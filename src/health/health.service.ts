import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { HealthCheckService, TypeOrmHealthIndicator } from '@nestjs/terminus';
import { HealthResponseDto } from './dto/health-response.dto';

@Injectable()
export class HealthService {
  constructor(
    private readonly healthCheckService: HealthCheckService,
    private readonly databaseIndicator: TypeOrmHealthIndicator,
  ) {}

  async check(): Promise<HealthResponseDto> {
    const timestamp = new Date().toISOString();

    try {
      await this.healthCheckService.check([
        () => this.databaseIndicator.pingCheck('database', { timeout: 3000 }),
      ]);
      return { status: 'ok', database: 'connected', timestamp };
    } catch {
      throw new ServiceUnavailableException({
        status: 'error',
        database: 'disconnected',
        timestamp,
        message: 'Database health check failed',
      });
    }
  }
}
