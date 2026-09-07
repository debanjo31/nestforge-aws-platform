import { ApiProperty } from '@nestjs/swagger';

export class HealthResponseDto {
  @ApiProperty({ example: 'ok' })
  status: 'ok';

  @ApiProperty({ example: 'connected' })
  database: 'connected';

  @ApiProperty({ type: String, format: 'date-time' })
  timestamp: string;
}
