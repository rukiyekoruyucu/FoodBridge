// src/repositories/userRepository.js
const db = require("../config/db");

// Yeni kullanıcı oluşturma
function createUser({ firebaseUid, role, fullName, email, username }) {
  const stmt = db.prepare(
    `INSERT INTO users (firebase_uid, role, full_name, email, username)
     VALUES (?, ?, ?, ?, ?)`
  );
  const info = stmt.run(firebaseUid, role, fullName, email, username);
  return db.prepare(
    `SELECT id, firebase_uid, role, full_name, email, username,
            kindness_points, avatar_url, bio, created_at, updated_at
     FROM users WHERE id = ?`
  ).get(info.lastInsertRowid);
}

function getUserByUsername(username) {
  return db.prepare(`SELECT id FROM users WHERE username = ?`).get(username) || null;
}

function getUserByEmail(email) {
  return db.prepare(
    `SELECT id, firebase_uid, role, full_name, username, email, kindness_points, created_at, updated_at
     FROM users
     WHERE email = ?`
  ).get(email) || null;
}

function incrementKindnessPoints(userId, points) {
  db.prepare(
    `UPDATE users
     SET kindness_points = COALESCE(kindness_points, 0) + ?,
         updated_at = datetime('now')
     WHERE id = ?`
  ).run(points, userId);
  return db.prepare(`SELECT id, kindness_points FROM users WHERE id = ?`).get(userId) || null;
}

function getUserByFirebaseUid(firebaseUid) {
  return db.prepare(
    `SELECT id, firebase_uid, role, full_name, email, username,
            kindness_points, avatar_url, bio, created_at, updated_at
     FROM users
     WHERE firebase_uid = ?`
  ).get(firebaseUid) || null;
}

function getUserById(id) {
  return db.prepare(
    `SELECT id, firebase_uid, role, full_name, email, username,
            kindness_points, avatar_url, bio, created_at, updated_at
     FROM users
     WHERE id = ?`
  ).get(id) || null;
}

function listTopDonors(limit = 10) {
  return db.prepare(
    `SELECT id, username, full_name, avatar_url, kindness_points
     FROM users
     ORDER BY kindness_points DESC
     LIMIT ?`
  ).all(limit);
}

function updateUserById(userId, { fullName, username, avatarUrl, bio }) {
  db.prepare(
    `UPDATE users
     SET
       full_name  = COALESCE(?, full_name),
       username   = COALESCE(?, username),
       avatar_url = COALESCE(?, avatar_url),
       bio        = COALESCE(?, bio),
       updated_at = datetime('now')
     WHERE id = ?`
  ).run(fullName ?? null, username ?? null, avatarUrl ?? null, bio ?? null, userId);

  return db.prepare(
    `SELECT id, firebase_uid, role, full_name, email, username,
            kindness_points, avatar_url, bio, created_at, updated_at
     FROM users WHERE id = ?`
  ).get(userId) || null;
}

module.exports = {
  createUser,
  getUserByFirebaseUid,
  getUserByUsername,
  incrementKindnessPoints,
  listTopDonors,
  updateUserById,
  getUserByEmail,
  getUserById
};
