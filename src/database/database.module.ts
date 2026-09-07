import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { createDatabaseOptionsFromConfig } from '../config/database-options';

@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        ...createDatabaseOptionsFromConfig(configService),
        retryAttempts: 5,
        retryDelay: 3000,
      }),
    }),
  ],
})
export class DatabaseModule {}
