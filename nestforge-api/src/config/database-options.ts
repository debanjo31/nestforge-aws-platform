import { ConfigService } from '@nestjs/config';
import { join } from 'node:path';
import type { PostgresConnectionOptions } from 'typeorm/driver/postgres/PostgresConnectionOptions';
import { Task } from '../modules/tasks/entities/task.entity';
import { User } from '../modules/users/entities/user.entity';

export interface DatabaseEnvironment {
  DB_HOST?: string;
  DB_PORT?: string | number;
  DB_USERNAME?: string;
  DB_PASSWORD?: string;
  DB_NAME?: string;
  DB_SSL?: string | boolean;
  DB_SSL_REJECT_UNAUTHORIZED?: string | boolean;
}

export function createDatabaseOptions(
  environment: DatabaseEnvironment,
): PostgresConnectionOptions {
  const sslEnabled =
    environment.DB_SSL === true || environment.DB_SSL === 'true';

  return {
    type: 'postgres',
    host: environment.DB_HOST,
    port: Number.parseInt(String(environment.DB_PORT ?? 5432), 10),
    username: environment.DB_USERNAME,
    password: environment.DB_PASSWORD,
    database: environment.DB_NAME,
    ssl: sslEnabled
      ? {
          rejectUnauthorized:
            environment.DB_SSL_REJECT_UNAUTHORIZED !== false &&
            environment.DB_SSL_REJECT_UNAUTHORIZED !== 'false',
        }
      : false,
    entities: [User, Task],
    migrations: [join(__dirname, '../database/migrations/*{.ts,.js}')],
    installExtensions: false,
    synchronize: false,
  };
}

export function createDatabaseOptionsFromConfig(
  configService: ConfigService,
): PostgresConnectionOptions {
  return createDatabaseOptions({
    DB_HOST: configService.getOrThrow<string>('database.host'),
    DB_PORT: String(configService.getOrThrow<number>('database.port')),
    DB_USERNAME: configService.getOrThrow<string>('database.username'),
    DB_PASSWORD: configService.getOrThrow<string>('database.password'),
    DB_NAME: configService.getOrThrow<string>('database.name'),
    DB_SSL: String(configService.getOrThrow<boolean>('database.ssl')),
    DB_SSL_REJECT_UNAUTHORIZED: String(
      configService.getOrThrow<boolean>('database.sslRejectUnauthorized'),
    ),
  });
}
