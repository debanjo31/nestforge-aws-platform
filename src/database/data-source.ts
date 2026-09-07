import 'dotenv/config';
import { DataSource } from 'typeorm';
import { createDatabaseOptions } from '../config/database-options';
import { envValidationSchema } from '../config/env.validation';

const validationResult = envValidationSchema.validate(process.env, {
  abortEarly: false,
  allowUnknown: true,
});

if (validationResult.error) {
  throw new Error(
    `Environment validation failed: ${validationResult.error.message}`,
  );
}

export default new DataSource(createDatabaseOptions(validationResult.value));
