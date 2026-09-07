# NestForge API

## Overview

NestForge API is a production-oriented NestJS task management backend. It
provides JWT authentication, per-user task ownership, PostgreSQL persistence,
TypeORM migrations, OpenAPI documentation, database-aware health checks, and a
container workflow designed to grow toward ECS Fargate and RDS PostgreSQL.

There is no frontend in this project. The primary interactive API client is
Swagger UI at `http://localhost:3000/api/docs`.

## Tech Stack

- Node.js 22 LTS
- NestJS 11 and TypeScript
- PostgreSQL 16
- TypeORM 0.3 with migrations
- Passport and JWT authentication
- Argon2 password hashing
- class-validator and class-transformer
- Swagger/OpenAPI
- NestJS Terminus health checks
- Jest and Supertest
- pnpm 10
- Docker and Docker Compose

## Architecture

```text
Client / Swagger UI
        |
        v
NestJS controllers
        |
        v
Application services
        |
        v
TypeORM repositories
        |
        v
PostgreSQL
```

Controllers handle HTTP concerns, DTOs validate input, services contain
business rules, and TypeORM repositories own persistence. Every task query is
scoped to both the task ID and authenticated user ID to prevent cross-account
access.

The Docker startup order is:

```text
postgres (healthy) -> migrations (completed successfully) -> api
```

## Project Structure

```text
nestforge-api/
|-- src/
|   |-- common/
|   |   |-- decorators/
|   |   |-- filters/
|   |   `-- interfaces/
|   |-- config/
|   |   |-- configuration.ts
|   |   |-- database-options.ts
|   |   `-- env.validation.ts
|   |-- database/
|   |   |-- migrations/
|   |   |-- data-source.ts
|   |   `-- database.module.ts
|   |-- modules/
|   |   |-- auth/
|   |   |   |-- dto/
|   |   |   |-- guards/
|   |   |   |-- strategies/
|   |   |   |-- auth.controller.ts
|   |   |   |-- auth.module.ts
|   |   |   `-- auth.service.ts
|   |   |-- health/
|   |   |   |-- dto/
|   |   |   |-- health.controller.ts
|   |   |   |-- health.module.ts
|   |   |   `-- health.service.ts
|   |   |-- tasks/
|   |   |   |-- dto/
|   |   |   |-- entities/
|   |   |   |-- enums/
|   |   |   |-- tasks.controller.ts
|   |   |   |-- tasks.module.ts
|   |   |   `-- tasks.service.ts
|   |   `-- users/
|   |       |-- dto/
|   |       |-- entities/
|   |       |-- users.controller.ts
|   |       |-- users.module.ts
|   |       `-- users.service.ts
|   |-- app.module.ts
|   `-- main.ts
|-- test/
|   |-- jest-e2e.json
|   |-- nestforge.e2e-spec.ts
|   `-- setup-env.ts
|-- .dockerignore
|-- .env.example
|-- .env.test.example
|-- Dockerfile
|-- docker-compose.yml
|-- package.json
`-- pnpm-lock.yaml
```

## Environment Variables

Copy `.env.example` to `.env` for normal local development.

| Variable | Required | Example | Purpose |
| --- | --- | --- | --- |
| `NODE_ENV` | No | `development` | Runtime environment; defaults to `development` |
| `PORT` | No | `3000` | HTTP port; defaults to `3000` |
| `DB_HOST` | Yes | `localhost` | PostgreSQL hostname |
| `DB_PORT` | No | `5432` | PostgreSQL port; defaults to `5432` |
| `DB_USERNAME` | Yes | `postgres` | PostgreSQL user |
| `DB_PASSWORD` | Yes | `postgres` | PostgreSQL password |
| `DB_NAME` | Yes | `nestforge` | PostgreSQL database |
| `DB_SSL` | No | `false` | Enables TLS for PostgreSQL |
| `DB_SSL_REJECT_UNAUTHORIZED` | No | `true` | Validates the database TLS certificate |
| `JWT_SECRET` | Yes | long random string | JWT signing secret, minimum 16 characters |
| `JWT_EXPIRES_IN` | No | `1h` | JWT lifetime; defaults to `1h` |

The application validates configuration at startup and exits immediately when
required values are missing or invalid. Do not commit real secrets. For AWS,
inject database credentials and the JWT secret from a managed secret store.

## Local Development

Prerequisites: Node.js 22+, Corepack/pnpm, Docker, and Docker Compose.

```powershell
Copy-Item .env.example .env
pnpm install --frozen-lockfile
docker compose up -d postgres
pnpm migration:run
pnpm start:dev
```

The API listens on `http://localhost:3000` by default.

## PostgreSQL

Docker Compose exposes PostgreSQL on `localhost:5432` with these local-only
credentials:

```text
database: nestforge
username: postgres
password: postgres
```

Start or stop only the database with:

```bash
docker compose up -d postgres
docker compose stop postgres
```

Data persists in the `postgres_data` named volume. These credentials are for
local development only and must not be used in production.

## TypeORM

The Nest application and TypeORM CLI share database option construction from
`src/config/database-options.ts`. Entities are registered explicitly.

`synchronize` is always `false`. Schema changes must be represented by
migrations.

## TypeORM Migrations

The CLI DataSource is `src/database/data-source.ts`. Development commands load
environment variables from `.env`; the compiled Docker command uses
`dist/database/data-source.js`.

The initial migration creates:

- the `users` table and unique email index;
- the `task_status_enum` PostgreSQL enum;
- the `tasks` table and cascading user foreign key;
- task indexes on `userId`, `status`, and `(userId, status)`;
- UUID and timestamp defaults.

Useful migration commands:

```bash
pnpm migration:show
pnpm migration:run
pnpm migration:revert
pnpm migration:create -- src/database/migrations/AddFeature
pnpm migration:generate -- src/database/migrations/AddFeature
```

Review generated migrations before applying them. Production containers run
compiled migrations through the one-shot `migrations` Compose service before
the API starts.

## Swagger

Swagger UI:

```text
http://localhost:3000/api/docs
```

OpenAPI JSON:

```text
http://localhost:3000/api/docs-json
```

Suggested Swagger workflow:

1. Call `POST /auth/register`.
2. Call `POST /auth/login`.
3. Copy `accessToken` from the login response.
4. Click **Authorize** and enter the token.
5. Exercise `/users/me` and `/tasks`.

## Authentication

Passwords are hashed with Argon2 and never returned by API response DTOs. A
successful login returns:

```json
{
  "accessToken": "<jwt>",
  "user": {
    "id": "<uuid>",
    "email": "user@example.com",
    "createdAt": "2026-09-07T12:00:00.000Z",
    "updatedAt": "2026-09-07T12:00:00.000Z"
  }
}
```

Send the token as `Authorization: Bearer <jwt>`. `/users/me` and all `/tasks`
routes require authentication.

## API Endpoints

| Method | Path | Auth | Description |
| --- | --- | --- | --- |
| `POST` | `/auth/register` | No | Register a user |
| `POST` | `/auth/login` | No | Log in and receive a JWT |
| `GET` | `/users/me` | Bearer | Get the current user |
| `POST` | `/tasks` | Bearer | Create an owned task |
| `GET` | `/tasks` | Bearer | List owned tasks |
| `GET` | `/tasks?status=TODO` | Bearer | Filter owned tasks by status |
| `GET` | `/tasks/:id` | Bearer | Get an owned task |
| `PATCH` | `/tasks/:id` | Bearer | Update an owned task |
| `DELETE` | `/tasks/:id` | Bearer | Delete an owned task |
| `GET` | `/health` | No | Check API and database health |

Task lookups return `404` when a task does not exist or belongs to another
user. This avoids leaking resource existence across accounts.

## Testing

Unit tests cover `AuthService` and `TasksService` behavior, including Argon2,
invalid credentials, query ownership, updates, and deletion.

The e2e suite uses a separate PostgreSQL database named `nestforge_test`. With
the Compose PostgreSQL service running, create it once:

```bash
docker compose exec postgres createdb -U postgres nestforge_test
```

Then run:

```bash
pnpm test
pnpm test:e2e
pnpm test:cov
```

The e2e setup runs pending migrations and truncates only the `tasks` and
`users` tables in `nestforge_test` before and after the suite. Override its
defaults with real environment variables when the test database is elsewhere;
see `.env.test.example`.

## Docker

The multi-stage Dockerfile:

- uses Node.js 22 LTS on Debian slim;
- enables pnpm through Corepack;
- installs from `pnpm-lock.yaml` with `--frozen-lockfile`;
- compiles the NestJS application;
- prunes development dependencies;
- runs as the non-root `node` user;
- includes an HTTP health check against `/health`.

Build the API image directly with:

```bash
docker build -t nestforge-api:local .
```

## Docker Compose

Start the complete stack:

```bash
docker compose up --build -d
docker compose ps
docker compose logs -f api
```

Compose waits for `pg_isready`, runs migrations in a one-shot service, waits for
that service to exit successfully, and only then starts the API. No sleep-based
startup scripts are used.

Stop the stack while retaining PostgreSQL data:

```bash
docker compose down
```

To run migrations again without entering a container:

```bash
docker compose run --rm migrations
```

## CI/CD

The repository-level GitHub Actions workflows validate pull requests and deploy the API to the existing dev ECS service after changes reach `main`. Delivery uses Node.js 22, Corepack, the pinned pnpm version, the existing Dockerfile, and immutable Git commit SHA image tags.

The deployment runs `migration:run` from the newly built production image as one temporary Fargate task. The ECS service is updated only when that task exits successfully. Schema changes must therefore remain compatible with the currently running application during a rolling deployment: add compatible schema first, deploy code that supports both shapes, backfill when necessary, and remove old schema in a later release.

GitHub authenticates to AWS through OIDC. No AWS access key is stored in GitHub, and the application workflow never runs `terraform apply`. See the [platform README](../README.md) and [infrastructure README](../api-infra-terraform/README.md) for the complete flow.

## Health Checks

`GET /health` executes a real PostgreSQL ping through NestJS Terminus.

Healthy response:

```json
{
  "status": "ok",
  "database": "connected",
  "timestamp": "2026-09-07T12:00:00.000Z"
}
```

If PostgreSQL cannot be reached, the endpoint returns HTTP `503`. PostgreSQL
uses `pg_isready`; the API container health check calls `/health`.

## Useful Commands

| Command | Purpose |
| --- | --- |
| `pnpm install --frozen-lockfile` | Install the locked dependency graph |
| `pnpm start:dev` | Start in watch mode |
| `pnpm build` | Compile to `dist/` |
| `pnpm start:prod` | Run the compiled API |
| `pnpm format` | Format TypeScript files |
| `pnpm lint` | Check source and tests with ESLint |
| `pnpm lint:fix` | Apply safe ESLint fixes |
| `pnpm test` | Run unit tests |
| `pnpm test:e2e` | Run PostgreSQL e2e tests |
| `pnpm test:cov` | Run unit tests with coverage |
| `pnpm migration:show` | Show migration status |
| `pnpm migration:run` | Apply pending migrations |
| `pnpm migration:revert` | Revert the latest migration |
| `docker compose up --build -d` | Build and start the complete stack |
| `docker compose run --rm migrations` | Run migrations on demand |
| `docker compose down` | Stop the stack and retain data |
