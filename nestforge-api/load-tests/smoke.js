import http from 'k6/http';
import { check } from 'k6';

const baseUrl = (__ENV.BASE_URL || 'http://host.docker.internal:3000').replace(
  /\/$/,
  '',
);

export const options = {
  vus: 1,
  iterations: 1,
  thresholds: {
    checks: ['rate==1'],
    http_req_failed: ['rate==0'],
    http_req_duration: ['p(95)<1000'],
  },
};

export default function () {
  const health = http.get(`${baseUrl}/health`, {
    tags: { endpoint: 'health' },
  });
  check(health, {
    'health returns 200': (response) => response.status === 200,
    'database is connected': (response) =>
      response.json('database') === 'connected',
  });

  const metrics = http.get(`${baseUrl}/metrics`, {
    tags: { endpoint: 'metrics' },
  });
  check(metrics, {
    'metrics returns 200': (response) => response.status === 200,
    'metrics expose request counter': (response) =>
      response.body.includes('nestforge_http_requests_total'),
  });
}
