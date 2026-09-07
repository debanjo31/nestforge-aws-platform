import { Controller, Get } from '@nestjs/common';
import { HealthCheck } from '@nestjs/terminus';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { HealthResponseDto } from './dto/health-response.dto';
import { HealthService } from './health.service';

@ApiTags('Health')
@Controller('health')
export class HealthController {
  constructor(private readonly healthService: HealthService) {}

  @Get()
  @HealthCheck()
  @ApiOperation({ summary: 'Check application and PostgreSQL health' })
  @ApiResponse({ status: 200, type: HealthResponseDto })
  @ApiResponse({ status: 503, description: 'PostgreSQL is unavailable' })
  check(): Promise<HealthResponseDto> {
    return this.healthService.check();
  }
}
