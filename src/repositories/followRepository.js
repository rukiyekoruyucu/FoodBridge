// src/repositories/followRepository.js
const db = require("../config/db");

function requestFollow(followerId, followeeId) {
  // INSERT OR REPLACE emulates ON CONFLICT DO UPDATE
  const existing = db.prepare(
    `SELECT id FROM follows WHERE follower_id = ? AND followee_id = ?`
  ).get(followerId, followeeId);

  if (existing) {
    db.prepare(
      `UPDATE follows SET status = 'PENDING' WHERE follower_id = ? AND followee_id = ?`
    ).run(followerId, followeeId);
    return db.prepare(`SELECT * FROM follows WHERE follower_id = ? AND followee_id = ?`).get(followerId, followeeId);
  }

  const info = db.prepare(
    `INSERT INTO follows (follower_id, followee_id, status)
     VALUES (?, ?, 'PENDING')`
  ).run(followerId, followeeId);
  return db.prepare(`SELECT * FROM follows WHERE id = ?`).get(info.lastInsertRowid);
}

function acceptFollow(followeeId, followerId) {
  db.prepare(
    `UPDATE follows
     SET status = 'ACCEPTED'
     WHERE follower_id = ? AND followee_id = ?`
  ).run(followerId, followeeId);
  return db.prepare(
    `SELECT * FROM follows WHERE follower_id = ? AND followee_id = ?`
  ).get(followerId, followeeId) || null;
}

function listIncomingRequests(userId) {
  return db.prepare(
    `SELECT f.*, u.full_name, u.avatar_url
     FROM follows f
     JOIN users u ON u.id = f.follower_id
     WHERE f.followee_id = ? AND f.status = 'PENDING'
     ORDER BY f.created_at DESC`
  ).all(userId);
}

function isMutualAccepted(userA, userB) {
  const row = db.prepare(
    `SELECT
       (SELECT COUNT(*) FROM follows WHERE follower_id=? AND followee_id=? AND status='ACCEPTED') as a_to_b,
       (SELECT COUNT(*) FROM follows WHERE follower_id=? AND followee_id=? AND status='ACCEPTED') as b_to_a`
  ).get(userA, userB, userB, userA);
  return row.a_to_b > 0 && row.b_to_a > 0;
}

module.exports = {
  requestFollow,
  acceptFollow,
  listIncomingRequests,
  isMutualAccepted
};
