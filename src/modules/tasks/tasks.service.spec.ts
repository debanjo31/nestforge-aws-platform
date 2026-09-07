import { NotFoundException } from '@nestjs/common';
import { Repository } from 'typeorm';
import { Task } from './entities/task.entity';
import { TaskStatus } from './enums/task-status.enum';
import { TasksService } from './tasks.service';

describe('TasksService', () => {
  let repository: jest.Mocked<Repository<Task>>;
  let service: TasksService;

  const userId = '04d3c56c-10f5-4bca-8e8a-cf1309e2a278';
  const taskId = 'a35ffae8-c6ae-4b6b-b2d4-9272a765a45b';
  const now = new Date('2026-09-07T12:00:00.000Z');

  function makeTask(overrides: Partial<Task> = {}): Task {
    return {
      id: taskId,
      title: 'Ship API',
      description: null,
      status: TaskStatus.TODO,
      userId,
      user: undefined as never,
      createdAt: now,
      updatedAt: now,
      ...overrides,
    };
  }

  beforeEach(() => {
    repository = {
      create: jest.fn(),
      save: jest.fn(),
      find: jest.fn(),
      findOne: jest.fn(),
      merge: jest.fn(),
      remove: jest.fn(),
    } as unknown as jest.Mocked<Repository<Task>>;
    service = new TasksService(repository);
  });

  it('assigns ownership and a default TODO status when creating', async () => {
    const task = makeTask();
    repository.create.mockReturnValue(task);
    repository.save.mockResolvedValue(task);

    const result = await service.create(userId, { title: 'Ship API' });

    expect(repository.create).toHaveBeenCalledWith({
      title: 'Ship API',
      description: null,
      status: TaskStatus.TODO,
      userId,
    });
    expect(result.userId).toBe(userId);
  });

  it('always scopes lists by owner and applies an optional status filter', async () => {
    repository.find.mockResolvedValue([
      makeTask({ status: TaskStatus.IN_PROGRESS }),
    ]);

    await service.findAll(userId, { status: TaskStatus.IN_PROGRESS });

    expect(repository.find).toHaveBeenCalledWith({
      where: { userId, status: TaskStatus.IN_PROGRESS },
      order: { createdAt: 'DESC' },
    });
  });

  it('scopes single-task reads by both task id and owner id', async () => {
    repository.findOne.mockResolvedValue(makeTask());

    await service.findOne(userId, taskId);

    expect(repository.findOne).toHaveBeenCalledWith({
      where: { id: taskId, userId },
    });
  });

  it('returns not found when a task is not owned by the user', async () => {
    repository.findOne.mockResolvedValue(null);

    await expect(service.findOne(userId, taskId)).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('loads an owned task before updating it', async () => {
    const task = makeTask();
    const updatedTask = makeTask({ status: TaskStatus.DONE });
    repository.findOne.mockResolvedValue(task);
    repository.merge.mockReturnValue(updatedTask);
    repository.save.mockResolvedValue(updatedTask);

    const result = await service.update(userId, taskId, {
      status: TaskStatus.DONE,
    });

    expect(repository.findOne).toHaveBeenCalledWith({
      where: { id: taskId, userId },
    });
    expect(repository.merge).toHaveBeenCalledWith(task, {
      status: TaskStatus.DONE,
    });
    expect(result.status).toBe(TaskStatus.DONE);
  });

  it('loads an owned task before deleting it', async () => {
    const task = makeTask();
    repository.findOne.mockResolvedValue(task);
    repository.remove.mockResolvedValue(task);

    await service.remove(userId, taskId);

    expect(repository.findOne).toHaveBeenCalledWith({
      where: { id: taskId, userId },
    });
    expect(repository.remove).toHaveBeenCalledWith(task);
  });
});
