// src/config/migrate.js
// Reads schema.sql and executes it to initialize the SQLite database.
// Also seeds a default public fridge and sets PUBLIC_FRIDGE_ID env var.

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

    // ✅ PUBLIC_FRIDGE_ID: Auto-create the global public fridge (system fridge, owner_user_id=0 workaround)
    // We use a special system user (id=1 if exists, or create a sentinel row in fridges)
    _ensurePublicFridge();

  } catch (err) {
    logger.error('[DB] Migration failed:', err);
    throw err;
  }
}

/**
 * Ensures there is exactly one "global public fridge" in the DB.
 * Sets process.env.PUBLIC_FRIDGE_ID so itemController can use it.
 *
 * Strategy: Look for a fridge named '__SYSTEM_PUBLIC__' with is_public=1.
 * If it doesn't exist, create it using the first PERSONAL/CORPORATE user's id,
 * or use a placeholder owner_user_id=0 with PRAGMA foreign_keys=OFF if needed.
 */
function _ensurePublicFridge() {
  try {
    // Check if already exists
    let fridge = db.prepare(
      `SELECT id FROM fridges WHERE name = '__SYSTEM_PUBLIC__' AND is_public = 1 LIMIT 1`
    ).get();

    if (!fridge) {
      // Find system user or create one to be the nominal owner
      let systemUser = db.prepare(`SELECT id FROM users WHERE firebase_uid = '__SYSTEM__' LIMIT 1`).get();
      if (!systemUser) {
        const info = db.prepare(`
          INSERT INTO users (firebase_uid, role, full_name, email, username)
          VALUES ('__SYSTEM__', 'CORPORATE', 'System', 'system@foodbridge.local', 'system')
        `).run();
        systemUser = { id: info.lastInsertRowid };
      }

      const info = db.prepare(
        `INSERT OR IGNORE INTO fridges (owner_user_id, name, description, latitude, longitude, address, is_public)
         VALUES (?, '__SYSTEM_PUBLIC__', 'Genel Bağış Noktası', 0, 0, 'Türkiye', 1)`
      ).run(systemUser.id);
      fridge = db.prepare(`SELECT id FROM fridges WHERE id = ?`).get(info.lastInsertRowid);
    }

    if (fridge) {
      process.env.PUBLIC_FRIDGE_ID = String(fridge.id);
      logger.info(`[DB] PUBLIC_FRIDGE_ID = ${fridge.id}`);
    }
  } catch (err) {
    logger.warn('[DB] Could not ensure public fridge (non-fatal):', err.message);
  }
}

module.exports = { runMigrations };
