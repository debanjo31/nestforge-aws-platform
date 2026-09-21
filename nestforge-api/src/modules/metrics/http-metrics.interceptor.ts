import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import type { Request, Response } from 'express';
import type { Observable } from 'rxjs';
import { finalize } from 'rxjs/operators';
import { MetricsService } from './metrics.service';

function routeLabel(request: Request): string {
  const route = request.route as { path?: unknown } | undefined;
  const routePath = typeof route?.path === 'string' ? route.path : undefined;

  return routePath ? `${request.baseUrl}${routePath}` : 'unmatched';
}

@Injectable()
export class HttpMetricsInterceptor implements NestInterceptor {
  constructor(private readonly metricsService: MetricsService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const request = context.switchToHttp().getRequest<Request>();
    const response = context.switchToHttp().getResponse<Response>();
    const startedAt = process.hrtime.bigint();

    this.metricsService.requestStarted();

    return next.handle().pipe(
      finalize(() => {
        const durationSeconds =
          Number(process.hrtime.bigint() - startedAt) / 1_000_000_000;
        this.metricsService.requestFinished(
          request.method,
          routeLabel(request),
          response.statusCode,
          durationSeconds,
        );
      }),
    );
  }
}
