import http from 'k6/http';
import { check } from 'k6';

export const options = {
  vus: 5,
  duration: '30s',
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<500'],
    checks: ['rate>0.99'],
  },
};

const target = __ENV.TARGET_URL || 'http://pmhub-gateway:6880/actuator/health';

export default function () {
  const response = http.get(target, { tags: { assessment: 'gateway-health' } });
  check(response, {
    'HTTP status is 200': (r) => r.status === 200,
    'response contains a health status': (r) => r.body.includes('status'),
  });
}

export function handleSummary(data) {
  return {
    '/evidence/k6-summary.json': JSON.stringify(data, null, 2),
    stdout: JSON.stringify({
      checks: data.metrics.checks,
      http_req_duration: data.metrics.http_req_duration,
      http_req_failed: data.metrics.http_req_failed,
      http_reqs: data.metrics.http_reqs,
    }, null, 2),
  };
}
