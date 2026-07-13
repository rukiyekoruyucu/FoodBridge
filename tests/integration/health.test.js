// tests/integration/health.test.js
//
// Integration tests for health check endpoints.
// Uses supertest to make real HTTP requests against the Express app
// without starting a real server (no port binding).

// Isolate from real Firebase + DB in CI
process.env.NODE_ENV        = 'test';
process.env.DATABASE_PATH   = ':memory:';   // in-memory SQLite for tests
process.env.FIREBASE_PROJECT_ID   = 'test-project';
process.env.FIREBASE_CLIENT_EMAIL = 'test@test.iam.gserviceaccount.com';
process.env.FIREBASE_PRIVATE_KEY  = '-----BEGIN PRIVATE KEY-----\nMIIE\n-----END PRIVATE KEY-----\n';

// Mock Firebase Admin so tests don't need real credentials
jest.mock('firebase-admin', () => ({
  apps: [],
  initializeApp: jest.fn(),
  credential: { cert: jest.fn() },
  auth: () => ({ verifyIdToken: jest.fn() }),
}));

const request = require('supertest');
const app     = require('../../src/app');

describe('GET /health', () => {
  test('returns 200 with status ok', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({ status: 'ok' });
  });
});

describe('GET /health/db', () => {
  test('returns 200 with db status', async () => {
    const res = await request(app).get('/health/db');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
    expect(res.body).toHaveProperty('dbTime');
  });
});

describe('404 handling', () => {
  test('unknown route returns 404', async () => {
    const res = await request(app).get('/api/nonexistent-route-xyz');
    expect(res.status).toBe(404);
  });
});

describe('API base protection', () => {
  test('auth-required endpoint returns 401 without token', async () => {
    const res = await request(app).get('/api/auth/me');
    expect(res.status).toBe(401);
  });
});
