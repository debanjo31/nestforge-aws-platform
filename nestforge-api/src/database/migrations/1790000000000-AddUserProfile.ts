import type { MigrationInterface, QueryRunner } from 'typeorm';

export class AddUserProfile1790000000000 implements MigrationInterface {
  name = 'AddUserProfile1790000000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      'ALTER TABLE "users" ADD COLUMN "displayName" varchar(100)',
    );
    await queryRunner.query(
      'ALTER TABLE "users" ADD COLUMN "bio" varchar(500)',
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('ALTER TABLE "users" DROP COLUMN "bio"');
    await queryRunner.query('ALTER TABLE "users" DROP COLUMN "displayName"');
  }
}
