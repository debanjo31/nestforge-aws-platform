import http from 'k6/http';
import { check, sleep } from 'k6';

const baseUrl = (__ENV.BASE_URL || 'http://host.docker.internal:3000').replace(
  /\/$/,
  '',
);

export const options = {
  scenarios: {
    api_load: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '15s', target: 10 },
        { duration: '30s', target: 10 },
        { duration: '15s', target: 0 },
      ],
      gracefulRampDown: '5s',
    },
  },
  thresholds: {
    checks: ['rate>0.99'],
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<500', 'p(99)<1000'],
  },
};

export function setup() {
  const email = `k6-${Date.now()}@example.com`;
  const password = 'k6-secure-password';
  const payload = JSON.stringify({ email, password });
  const headers = { 'Content-Type': 'application/json' };

  const registration = http.post(`${baseUrl}/auth/register`, payload, {
    headers,
    tags: { endpoint: 'register' },
  });
  check(registration, {
    'load user registration succeeds': (response) => response.status === 201,
  });

  const login = http.post(`${baseUrl}/auth/login`, payload, {
    headers,
    tags: { endpoint: 'login' },
  });
  const loginSucceeded = check(login, {
    'load user login succeeds': (response) => response.status === 200,
    'login returns a token': (response) =>
      Boolean(response.json('accessToken')),
  });

  if (!loginSucceeded) {
    throw new Error(`Unable to create k6 session: HTTP ${login.status}`);
  }

  return { token: login.json('accessToken') };
}

export default function (data) {
  const params = {
    headers: { Authorization: `Bearer ${data.token}` },
  };

  const responses = http.batch([
    [
      'GET',
      `${baseUrl}/users/me`,
      null,
      { ...params, tags: { endpoint: 'profile' } },
    ],
    [
      'GET',
      `${baseUrl}/tasks`,
      null,
      { ...params, tags: { endpoint: 'tasks' } },
    ],
    ['GET', `${baseUrl}/health`, null, { tags: { endpoint: 'health' } }],
  ]);

  check(responses[0], {
    'profile returns 200': (response) => response.status === 200,
  });
  check(responses[1], {
    'tasks return 200': (response) => response.status === 200,
  });
  check(responses[2], {
    'health returns 200': (response) => response.status === 200,
  });

  sleep(1);
}
