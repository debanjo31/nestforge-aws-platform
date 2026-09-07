import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { App } from 'supertest/types';
import request from 'supertest';
import { DataSource } from 'typeorm';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { TaskStatus } from '../src/modules/tasks/enums/task-status.enum';

interface AuthResponseBody {
  accessToken: string;
  user: { id: string; email: string; passwordHash?: string };
}

interface TaskResponseBody {
  id: string;
  title: string;
  description: string | null;
  status: TaskStatus;
  userId: string;
}

describe('NestForge API (e2e)', () => {
  let app: INestApplication<App>;
  let dataSource: DataSource;
  let firstToken: string;
  let firstUserId: string;
  let todoTaskId: string;

  const firstCredentials = {
    email: 'first@example.com',
    password: 'first-secure-password',
  };
  const secondCredentials = {
    email: 'second@example.com',
    password: 'second-secure-password',
  };

  beforeAll(async () => {
    const moduleFixture = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    app.useGlobalFilters(new AllExceptionsFilter());

    dataSource = app.get(DataSource);
    await dataSource.runMigrations();
    await dataSource.query(
      'TRUNCATE TABLE "tasks", "users" RESTART IDENTITY CASCADE',
    );
    await app.init();
  });

  afterAll(async () => {
    if (dataSource?.isInitialized) {
      await dataSource.query(
        'TRUNCATE TABLE "tasks", "users" RESTART IDENTITY CASCADE',
      );
    }
    await app?.close();
  });

  it('registers a user without exposing passwordHash', async () => {
    const response = await request(app.getHttpServer())
      .post('/auth/register')
      .send(firstCredentials)
      .expect(201);
    const body = response.body as AuthResponseBody['user'];

    expect(body.email).toBe(firstCredentials.email);
    expect(body.passwordHash).toBeUndefined();
    firstUserId = body.id;
  });

  it('rejects duplicate registration', async () => {
    await request(app.getHttpServer())
      .post('/auth/register')
      .send(firstCredentials)
      .expect(409);
  });

  it('rejects invalid login credentials', async () => {
    await request(app.getHttpServer())
      .post('/auth/login')
      .send({ ...firstCredentials, password: 'incorrect-password' })
      .expect(401);
  });

  it('logs in and returns a JWT', async () => {
    const response = await request(app.getHttpServer())
      .post('/auth/login')
      .send(firstCredentials)
      .expect(200);
    const body = response.body as AuthResponseBody;

    expect(body.accessToken).toEqual(expect.any(String));
    expect(body.user.id).toBe(firstUserId);
    firstToken = body.accessToken;
  });

  it('rejects protected requests without a JWT', async () => {
    await request(app.getHttpServer()).get('/users/me').expect(401);
  });

  it('returns the authenticated user from /users/me', async () => {
    const response = await request(app.getHttpServer())
      .get('/users/me')
      .auth(firstToken, { type: 'bearer' })
      .expect(200);
    const body = response.body as AuthResponseBody['user'];

    expect(body).toMatchObject({
      id: firstUserId,
      email: firstCredentials.email,
    });
    expect(body.passwordHash).toBeUndefined();
  });

  it('creates a task for the authenticated user', async () => {
    const response = await request(app.getHttpServer())
      .post('/tasks')
      .auth(firstToken, { type: 'bearer' })
      .send({ title: 'Write migration documentation' })
      .expect(201);
    const body = response.body as TaskResponseBody;

    expect(body).toMatchObject({
      title: 'Write migration documentation',
      description: null,
      status: TaskStatus.TODO,
      userId: firstUserId,
    });
    todoTaskId = body.id;
  });

  it('gets all tasks belonging to the user', async () => {
    await request(app.getHttpServer())
      .post('/tasks')
      .auth(firstToken, { type: 'bearer' })
      .send({ title: 'Completed task', status: TaskStatus.DONE })
      .expect(201);

    const response = await request(app.getHttpServer())
      .get('/tasks')
      .auth(firstToken, { type: 'bearer' })
      .expect(200);
    const body = response.body as TaskResponseBody[];

    expect(body).toHaveLength(2);
    expect(body.every((task) => task.userId === firstUserId)).toBe(true);
  });

  it('filters tasks by status', async () => {
    const response = await request(app.getHttpServer())
      .get('/tasks')
      .query({ status: TaskStatus.DONE })
      .auth(firstToken, { type: 'bearer' })
      .expect(200);
    const body = response.body as TaskResponseBody[];

    expect(body).toHaveLength(1);
    expect(body[0].status).toBe(TaskStatus.DONE);
  });

  it('gets one owned task by id', async () => {
    const response = await request(app.getHttpServer())
      .get(`/tasks/${todoTaskId}`)
      .auth(firstToken, { type: 'bearer' })
      .expect(200);
    const body = response.body as TaskResponseBody;

    expect(body.id).toBe(todoTaskId);
  });

  it('updates one owned task', async () => {
    const response = await request(app.getHttpServer())
      .patch(`/tasks/${todoTaskId}`)
      .auth(firstToken, { type: 'bearer' })
      .send({ status: TaskStatus.IN_PROGRESS })
      .expect(200);
    const body = response.body as TaskResponseBody;

    expect(body.status).toBe(TaskStatus.IN_PROGRESS);
  });

  it('prevents access to another user’s task', async () => {
    await request(app.getHttpServer())
      .post('/auth/register')
      .send(secondCredentials)
      .expect(201);
    const loginResponse = await request(app.getHttpServer())
      .post('/auth/login')
      .send(secondCredentials)
      .expect(200);
    const secondToken = (loginResponse.body as AuthResponseBody).accessToken;
    const taskResponse = await request(app.getHttpServer())
      .post('/tasks')
      .auth(secondToken, { type: 'bearer' })
      .send({ title: 'Private second-user task' })
      .expect(201);
    const secondTask = taskResponse.body as TaskResponseBody;

    await request(app.getHttpServer())
      .get(`/tasks/${secondTask.id}`)
      .auth(firstToken, { type: 'bearer' })
      .expect(404);
    await request(app.getHttpServer())
      .patch(`/tasks/${secondTask.id}`)
      .auth(firstToken, { type: 'bearer' })
      .send({ status: TaskStatus.DONE })
      .expect(404);
    await request(app.getHttpServer())
      .delete(`/tasks/${secondTask.id}`)
      .auth(firstToken, { type: 'bearer' })
      .expect(404);
  });

  it('deletes an owned task', async () => {
    await request(app.getHttpServer())
      .delete(`/tasks/${todoTaskId}`)
      .auth(firstToken, { type: 'bearer' })
      .expect(204);
    await request(app.getHttpServer())
      .get(`/tasks/${todoTaskId}`)
      .auth(firstToken, { type: 'bearer' })
      .expect(404);
  });

  it('reports healthy when PostgreSQL is reachable', async () => {
    const response = await request(app.getHttpServer())
      .get('/health')
      .expect(200);

    expect(response.body).toMatchObject({
      status: 'ok',
      database: 'connected',
    });
    expect(response.body).toHaveProperty('timestamp');
  });
});
