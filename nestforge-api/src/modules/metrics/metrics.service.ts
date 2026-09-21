import { Injectable } from '@nestjs/common';
import {
  collectDefaultMetrics,
  Counter,
  Gauge,
  Histogram,
  Registry,
} from '@prometheus-io/client';

const HTTP_LABELS = ['method', 'route', 'status_code'] as const;

@Injectable()
export class MetricsService {
  private readonly registry = new Registry();

  private readonly requestCount = new Counter({
    name: 'nestforge_http_requests_total',
    help: 'Total number of HTTP requests handled by NestForge',
    labelNames: HTTP_LABELS,
    registers: [this.registry],
  });

  private readonly requestDuration = new Histogram({
    name: 'nestforge_http_request_duration_seconds',
    help: 'NestForge HTTP request duration in seconds',
    labelNames: HTTP_LABELS,
    buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5],
    registers: [this.registry],
  });

  private readonly activeRequests = new Gauge({
    name: 'nestforge_http_active_requests',
    help: 'Number of NestForge HTTP requests currently being handled',
    registers: [this.registry],
  });

  constructor() {
    this.registry.setDefaultLabels({ service: 'nestforge-api' });
    collectDefaultMetrics({
      register: this.registry,
      prefix: 'nestforge_nodejs_',
    });
  }

  requestStarted(): void {
    this.activeRequests.inc();
  }

  requestFinished(
    method: string,
    route: string,
    statusCode: number,
    durationSeconds: number,
  ): void {
    const labels = {
      method,
      route,
      status_code: String(statusCode),
    };

    this.activeRequests.dec();
    this.requestCount.inc(labels);
    this.requestDuration.observe(labels, durationSeconds);
  }

  get contentType(): string {
    return this.registry.contentType;
  }

  render(): Promise<string> {
    return this.registry.metrics();
  }
}
