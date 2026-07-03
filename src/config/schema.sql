-- src/config/schema.sql
-- SQLite schema for FoodBridge (converted from PostgreSQL)

CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  firebase_uid TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL CHECK(role IN ('PERSONAL','CORPORATE','NEEDY')),
  full_name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  username TEXT UNIQUE NOT NULL,
  kindness_points INTEGER NOT NULL DEFAULT 0,
  avatar_url TEXT,
  bio TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS fridges (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  owner_user_id INTEGER NOT NULL REFERENCES users(id),
  name TEXT NOT NULL,
  description TEXT,
  latitude REAL NOT NULL DEFAULT 0,
  longitude REAL NOT NULL DEFAULT 0,
  address TEXT,
  is_public INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  fridge_id INTEGER NOT NULL REFERENCES fridges(id),
  donor_user_id INTEGER NOT NULL REFERENCES users(id),
  name TEXT NOT NULL,
  description TEXT,
  category TEXT,
  quantity INTEGER,
  unit TEXT,
  expiry_date TEXT,
  status TEXT NOT NULL DEFAULT 'AVAILABLE' CHECK(status IN ('AVAILABLE','RESERVED','REMOVED','EXPIRED')),
  image_url TEXT,
  lat REAL,
  lng REAL,
  address TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS donations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  item_id INTEGER NOT NULL REFERENCES items(id),
  donor_id INTEGER NOT NULL REFERENCES users(id),
  recipient_id INTEGER NOT NULL REFERENCES users(id),
  type TEXT NOT NULL DEFAULT 'DONATION',
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK(status IN ('PENDING','ACCEPTED','COMPLETED','CANCELLED')),
  accepted_at TEXT,
  completed_at TEXT,
  cancelled_at TEXT,
  cancel_reason TEXT,
  donor_confirmed_at TEXT,
  recipient_confirmed_at TEXT,
  kindness_points_awarded INTEGER,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS chat_rooms (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  room_type TEXT NOT NULL CHECK(room_type IN ('DM','DONATION')),
  donation_id INTEGER REFERENCES donations(id),
  dm_user_a INTEGER REFERENCES users(id),
  dm_user_b INTEGER REFERENCES users(id),
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_chat_rooms_dm
  ON chat_rooms(dm_user_a, dm_user_b)
  WHERE room_type = 'DM';

CREATE UNIQUE INDEX IF NOT EXISTS idx_chat_rooms_donation
  ON chat_rooms(donation_id)
  WHERE room_type = 'DONATION';

CREATE TABLE IF NOT EXISTS chat_messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  room_id INTEGER NOT NULL REFERENCES chat_rooms(id),
  sender_id INTEGER NOT NULL REFERENCES users(id),
  message TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS follows (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  follower_id INTEGER NOT NULL REFERENCES users(id),
  followee_id INTEGER NOT NULL REFERENCES users(id),
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK(status IN ('PENDING','ACCEPTED')),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(follower_id, followee_id)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- PERFORMANCE INDEXES — 1000+ kullanici icin zorunlu
-- Hepsi IF NOT EXISTS — mevcut DB uzerinde guvenle calisir, yeniden olusturmaz
-- ─────────────────────────────────────────────────────────────────────────────

-- items: en sik sorgulanan tablo
CREATE INDEX IF NOT EXISTS idx_items_status          ON items(status);
CREATE INDEX IF NOT EXISTS idx_items_fridge_id       ON items(fridge_id);
CREATE INDEX IF NOT EXISTS idx_items_donor_user_id   ON items(donor_user_id);
CREATE INDEX IF NOT EXISTS idx_items_status_created  ON items(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_items_category        ON items(category);
CREATE INDEX IF NOT EXISTS idx_items_lat_lng         ON items(lat, lng);

-- fridges: harita ve public sorgulari icin
CREATE INDEX IF NOT EXISTS idx_fridges_public        ON fridges(is_public);
CREATE INDEX IF NOT EXISTS idx_fridges_owner         ON fridges(owner_user_id);
CREATE INDEX IF NOT EXISTS idx_fridges_lat_lng       ON fridges(latitude, longitude);

-- donations: bagis sorgulari icin
CREATE INDEX IF NOT EXISTS idx_donations_item_id     ON donations(item_id);
CREATE INDEX IF NOT EXISTS idx_donations_donor_id    ON donations(donor_id);
CREATE INDEX IF NOT EXISTS idx_donations_recipient   ON donations(recipient_id);
CREATE INDEX IF NOT EXISTS idx_donations_status      ON donations(status);

-- chat_messages: inbox icin kritik — bu olmadan her chat aclisinda full scan
CREATE INDEX IF NOT EXISTS idx_chat_messages_room    ON chat_messages(room_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender  ON chat_messages(sender_id);

-- users: leaderboard siralama icin
CREATE INDEX IF NOT EXISTS idx_users_kindness        ON users(kindness_points DESC);
