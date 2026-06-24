// src/config/migrate.js
// Reads schema.sql and executes it to initialize the SQLite database.
// Called once at application startup.

const fs = require('fs');
const path = require('path');
const db = require('./db');
const logger = require('../utils/logger');

function runMigrations() {
  try {
    const schemaPath = path.join(__dirname, 'schema.sql');
    const sql = fs.readFileSync(schemaPath, 'utf-8');

    // Execute schema (CREATE TABLE IF NOT EXISTS - idempotent)
    db.exec(sql);

    logger.info('[DB] Migrations applied successfully');
  } catch (err) {
    logger.error('[DB] Migration failed:', err);
    throw err;
  }
}

module.exports = { runMigrations };
