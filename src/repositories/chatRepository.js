// src/repositories/chatRepository.js
const db = require("../config/db");

function getOrCreateDmRoom(userId, otherUserId) {
  const a = Math.min(userId, otherUserId);
  const b = Math.max(userId, otherUserId);

  const existing = db.prepare(
    `SELECT *
     FROM chat_rooms
     WHERE room_type = 'DM' AND dm_user_a = ? AND dm_user_b = ?
     LIMIT 1`
  ).get(a, b);
  if (existing) return existing;

  const info = db.prepare(
    `INSERT INTO chat_rooms (room_type, dm_user_a, dm_user_b)
     VALUES ('DM', ?, ?)`
  ).run(a, b);
  return db.prepare(`SELECT * FROM chat_rooms WHERE id = ?`).get(info.lastInsertRowid);
}

function getOrCreateDonationRoom(donationId) {
  const existing = db.prepare(
    `SELECT *
     FROM chat_rooms
     WHERE room_type = 'DONATION'
       AND donation_id = ?
     LIMIT 1`
  ).get(donationId);
  if (existing) return existing;

  const info = db.prepare(
    `INSERT INTO chat_rooms (room_type, donation_id)
     VALUES ('DONATION', ?)`
  ).run(donationId);
  return db.prepare(`SELECT * FROM chat_rooms WHERE id = ?`).get(info.lastInsertRowid);
}

/**
 * Yetki kontrolü:
 * - DM -> dm_user_a/b
 * - DONATION -> donations.donor_id / recipient_id
 */
function isUserInRoom(roomId, userId) {
  const room = db.prepare(
    `SELECT room_type, dm_user_a, dm_user_b, donation_id
     FROM chat_rooms
     WHERE id = ?`
  ).get(roomId);
  if (!room) return false;

  if (room.room_type === "DM") {
    return room.dm_user_a === userId || room.dm_user_b === userId;
  }

  if (room.room_type === "DONATION") {
    if (!room.donation_id) return false;
    const don = db.prepare(
      `SELECT donor_id, recipient_id FROM donations WHERE id = ?`
    ).get(room.donation_id);
    if (!don) return false;
    return don.donor_id === userId || don.recipient_id === userId;
  }

  return false;
}

/** Tek mesaj insert: kolon adı "message" */
function insertMessage(roomId, senderId, message) {
  const info = db.prepare(
    `INSERT INTO chat_messages (room_id, sender_id, message)
     VALUES (?, ?, ?)`
  ).run(roomId, senderId, message);
  return db.prepare(
    `SELECT m.*, u.full_name, u.avatar_url
     FROM chat_messages m
     JOIN users u ON u.id = m.sender_id
     WHERE m.id = ?`
  ).get(info.lastInsertRowid);
}

// Alias kept for socket handler compatibility
function createMessage(roomId, senderId, message) {
  return insertMessage(roomId, senderId, message);
}

/** Mesaj listesi: JOIN ile full_name, avatar_url */
function listMessages(roomId, limit = 50, before = null) {
  if (before) {
    const rows = db.prepare(
      `SELECT m.*, u.full_name, u.avatar_url
       FROM chat_messages m
       JOIN users u ON u.id = m.sender_id
       WHERE m.room_id = ? AND m.created_at < ?
       ORDER BY m.created_at DESC
       LIMIT ?`
    ).all(roomId, before, limit);
    return rows.reverse();
  }

  const rows = db.prepare(
    `SELECT m.*, u.full_name, u.avatar_url
     FROM chat_messages m
     JOIN users u ON u.id = m.sender_id
     WHERE m.room_id = ?
     ORDER BY m.created_at DESC
     LIMIT ?`
  ).all(roomId, limit);
  return rows.reverse();
}

/**
 * Thread listesi: son mesajı her room için al.
 * DISTINCT ON → SQLite'ta yok, MAX(id) GROUP BY ile çözüldü.
 * NULL::int → NULL
 */
function listUserRooms(meId, limit = 50) {
  return db.prepare(
    `WITH rooms AS (
      -- DM
      SELECT
        cr.id,
        cr.room_type,
        cr.created_at,
        cr.donation_id,
        cr.dm_user_a,
        cr.dm_user_b,
        CASE
          WHEN cr.dm_user_a = ? THEN cr.dm_user_b
          ELSE cr.dm_user_a
        END AS other_user_id
      FROM chat_rooms cr
      WHERE cr.room_type = 'DM'
        AND (cr.dm_user_a = ? OR cr.dm_user_b = ?)

      UNION ALL

      -- DONATION
      SELECT
        cr.id,
        cr.room_type,
        cr.created_at,
        cr.donation_id,
        cr.dm_user_a,
        cr.dm_user_b,
        NULL AS other_user_id
      FROM chat_rooms cr
      JOIN donations d ON d.id = cr.donation_id
      WHERE cr.room_type = 'DONATION'
        AND (d.donor_id = ? OR d.recipient_id = ?)
    ),
    last_msg AS (
      SELECT
        m.room_id,
        m.message  AS last_message,
        m.created_at AS last_message_at,
        m.sender_id  AS last_sender_id
      FROM chat_messages m
      WHERE m.id IN (
        SELECT MAX(id) FROM chat_messages GROUP BY room_id
      )
    )
    SELECT
      r.*,
      lm.last_message,
      lm.last_message_at,
      lm.last_sender_id,
      COALESCE(u.full_name, u.username, 'Kullanıcı #' || u.id) AS other_full_name,
      u.avatar_url AS other_avatar_url
    FROM rooms r
    LEFT JOIN last_msg lm ON lm.room_id = r.id
    LEFT JOIN users u ON u.id = r.other_user_id
    ORDER BY COALESCE(lm.last_message_at, r.created_at) DESC
    LIMIT ?`
  ).all(meId, meId, meId, meId, meId, limit);
}

module.exports = {
  getOrCreateDmRoom,
  getOrCreateDonationRoom,
  isUserInRoom,
  insertMessage,
  createMessage,
  listMessages,
  listUserRooms,
};
