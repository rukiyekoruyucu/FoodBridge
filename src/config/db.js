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

// ─────────────────────────────────────────────────────────────────────────────
// PERFORMANCE PRAGMAS — 1000+ kullanici icin optimize edildi
// ─────────────────────────────────────────────────────────────────────────────

// WAL mode: sonsuz esit zamanli READ, serialize WRITE
db.pragma('journal_mode = WAL');

// Write kilidi beklemek yerine 5 saniye timeout — "SQLITE_BUSY" hatasinı onler
db.pragma('busy_timeout = 5000');

// WAL modunda NORMAL guvenli ve FULL'dan 2-3x daha hizli
db.pragma('synchronous = NORMAL');

// 64MB page cache (default 2MB) — tekrarlayan sorgular RAM'den gelir
db.pragma('cache_size = -64000');

// Gecici tablolar (sort, groupby) icin disk yerine RAM kullan
db.pragma('temp_store = MEMORY');

// Sayfa boyutu — SSD'lerde 4096 optimal
db.pragma('page_size = 4096');

// Foreign key constraintleri aktif
db.pragma('foreign_keys = ON');

// LIKE sorgulari buyuk/kucuk harf duyarsiz
db.pragma('case_sensitive_like = OFF');

// WAL checkpoint: 1000 sayfadan sonra otomatik checkpoint
db.pragma('wal_autocheckpoint = 1000');

module.exports = db;
