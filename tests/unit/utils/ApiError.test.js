// tests/unit/utils/ApiError.test.js
const ApiError = require('../../../src/utils/ApiError');

describe('ApiError', () => {
  test('extends Error', () => {
    const err = new ApiError(404, 'Not found');
    expect(err).toBeInstanceOf(Error);
    expect(err).toBeInstanceOf(ApiError);
  });

  test('stores statusCode and message', () => {
    const err = new ApiError(400, 'Bad request');
    expect(err.statusCode).toBe(400);
    expect(err.message).toBe('Bad request');
  });

  test('details defaults to null', () => {
    const err = new ApiError(500, 'Server error');
    expect(err.details).toBeNull();
  });

  test('accepts details object', () => {
    const details = { field: 'email', issue: 'required' };
    const err = new ApiError(422, 'Validation failed', details);
    expect(err.details).toEqual(details);
  });

  test('common HTTP status codes', () => {
    expect(new ApiError(401, 'Unauthorized').statusCode).toBe(401);
    expect(new ApiError(403, 'Forbidden').statusCode).toBe(403);
    expect(new ApiError(409, 'Conflict').statusCode).toBe(409);
  });

  test('name is ApiError (not Error)', () => {
    const err = new ApiError(404, 'Not found');
    // Class name should be ApiError, not generic Error
    expect(err.constructor.name).toBe('ApiError');
  });
});
