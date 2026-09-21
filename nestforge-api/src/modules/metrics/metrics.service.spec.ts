import { MetricsService } from './metrics.service';

describe('MetricsService', () => {
  it('renders request and Node.js metrics in Prometheus format', async () => {
    const service = new MetricsService();

    service.requestStarted();
    service.requestFinished('GET', '/health', 200, 0.025);

    const metrics = await service.render();

    expect(metrics).toContain('nestforge_http_requests_total');
    expect(metrics).toContain('method="GET"');
    expect(metrics).toContain('route="/health"');
    expect(metrics).toContain('status_code="200"');
    expect(metrics).toContain('nestforge_http_request_duration_seconds');
    expect(metrics).toContain(
      'nestforge_nodejs_process_cpu_user_seconds_total',
    );
  });
});
