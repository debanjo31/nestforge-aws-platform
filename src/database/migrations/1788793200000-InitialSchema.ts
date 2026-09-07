import type { MigrationInterface, QueryRunner } from 'typeorm';

export class InitialSchema1788793200000 implements MigrationInterface {
  name = 'InitialSchema1788793200000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('CREATE EXTENSION IF NOT EXISTS "pgcrypto"');
    await queryRunner.query(
      "CREATE TYPE \"task_status_enum\" AS ENUM ('TODO', 'IN_PROGRESS', 'DONE')",
    );
    await queryRunner.query(`
      CREATE TABLE "users" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "email" varchar(320) NOT NULL,
        "passwordHash" varchar(255) NOT NULL,
        "createdAt" timestamptz NOT NULL DEFAULT now(),
        "updatedAt" timestamptz NOT NULL DEFAULT now(),
        CONSTRAINT "users_pkey" PRIMARY KEY ("id")
      )
    `);
    await queryRunner.query(
      'CREATE UNIQUE INDEX "users_email_unique_idx" ON "users" ("email")',
    );
    await queryRunner.query(`
      CREATE TABLE "tasks" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "title" varchar(200) NOT NULL,
        "description" text,
        "status" "task_status_enum" NOT NULL DEFAULT 'TODO',
        "userId" uuid NOT NULL,
        "createdAt" timestamptz NOT NULL DEFAULT now(),
        "updatedAt" timestamptz NOT NULL DEFAULT now(),
        CONSTRAINT "tasks_pkey" PRIMARY KEY ("id"),
        CONSTRAINT "tasks_user_id_fkey" FOREIGN KEY ("userId")
          REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(
      'CREATE INDEX "tasks_user_id_idx" ON "tasks" ("userId")',
    );
    await queryRunner.query(
      'CREATE INDEX "tasks_status_idx" ON "tasks" ("status")',
    );
    await queryRunner.query(
      'CREATE INDEX "tasks_user_id_status_idx" ON "tasks" ("userId", "status")',
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('DROP TABLE IF EXISTS "tasks"');
    await queryRunner.query('DROP TABLE IF EXISTS "users"');
    await queryRunner.query('DROP TYPE IF EXISTS "task_status_enum"');
  }
}
