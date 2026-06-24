// src/config/db.js
const Database = require('better-sqlite3');
const path = require('path');

const dbPath = process.env.DATABASE_PATH || path.join(__dirname, '..', '..', 'data', 'foodbridge.db');

// Ensure data directory exists
const fs = require('fs');
const dir = path.dirname(dbPath);
if (!fs.existsSync(dir)) {
  fs.mkdirSync(dir, { recursive: true });
}

const db = new Database(dbPath, { verbose: null });

db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');
db.pragma('case_sensitive_like = OFF');

module.exports = db;
