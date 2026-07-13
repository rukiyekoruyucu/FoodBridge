// jest.config.js
'use strict';

module.exports = {
  testEnvironment: 'node',
  testMatch: [
    '**/tests/**/*.test.js',
  ],
  collectCoverageFrom: [
    'src/**/*.js',
    '!src/server.js',          // entry point — not unit testable
    '!src/config/firebase.js', // requires real credentials
    '!src/config/cloudinary.js',
  ],
  coverageReporters: ['text', 'lcov', 'clover'],
  coverageDirectory: 'coverage',
  // Clear mocks between tests
  clearMocks: true,
  // Fail if coverage drops below thresholds
  coverageThreshold: {
    global: {
      branches:   40,
      functions:  50,
      lines:      50,
      statements: 50,
    },
  },
};
