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
  // clearMocks: true,
};
