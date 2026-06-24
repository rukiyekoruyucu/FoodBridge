// src/repositories/donationRepository.js
const db = require("../config/db");

function createDonation({ itemId, donorId, recipientId, type }) {
  const info = db.prepare(
    `INSERT INTO donations (item_id, donor_id, recipient_id, type, status)
     VALUES (?, ?, ?, ?, 'PENDING')`
  ).run(itemId, donorId, recipientId, type);
  return db.prepare(`SELECT * FROM donations WHERE id = ?`).get(info.lastInsertRowid);
}

function getDonationById(id) {
  return db.prepare(`SELECT * FROM donations WHERE id = ?`).get(id) || null;
}

// Tx versions (no client param needed — SQLite uses same connection inside db.transaction)
function getDonationForUpdate(donationId) {
  // SQLite WAL handles concurrency; FOR UPDATE not needed
  return db.prepare(`SELECT * FROM donations WHERE id = ?`).get(donationId) || null;
}

function acceptDonationTx(donationId) {
  db.prepare(
    `UPDATE donations
     SET status = 'ACCEPTED',
         accepted_at = datetime('now'),
         updated_at = datetime('now')
     WHERE id = ? AND status = 'PENDING'`
  ).run(donationId);
  return db.prepare(`SELECT * FROM donations WHERE id = ?`).get(donationId) || null;
}

function cancelOtherPendingTx(itemId, acceptedDonationId) {
  db.prepare(
    `UPDATE donations
     SET status = 'CANCELLED',
         cancelled_at = datetime('now'),
         updated_at = datetime('now')
     WHERE item_id = ?
       AND status = 'PENDING'
       AND id <> ?`
  ).run(itemId, acceptedDonationId);
}

function setDonorConfirmedTx(donationId) {
  db.prepare(
    `UPDATE donations
     SET donor_confirmed_at = COALESCE(donor_confirmed_at, datetime('now')),
         updated_at = datetime('now')
     WHERE id = ?`
  ).run(donationId);
}

function setRecipientConfirmedTx(donationId) {
  db.prepare(
    `UPDATE donations
     SET recipient_confirmed_at = COALESCE(recipient_confirmed_at, datetime('now')),
         updated_at = datetime('now')
     WHERE id = ?`
  ).run(donationId);
}

function completeDonationTx(donationId, points) {
  db.prepare(
    `UPDATE donations
     SET status = 'COMPLETED',
         completed_at = datetime('now'),
         kindness_points_awarded = ?,
         updated_at = datetime('now')
     WHERE id = ? AND status = 'ACCEPTED'`
  ).run(points, donationId);
  return db.prepare(`SELECT * FROM donations WHERE id = ?`).get(donationId) || null;
}

function findPendingByItemAndRecipient(itemId, recipientId) {
  return db.prepare(
    `SELECT * FROM donations
     WHERE item_id=? AND recipient_id=? AND status='PENDING'
     LIMIT 1`
  ).get(itemId, recipientId) || null;
}

function listPendingRequestsByItem(itemId) {
  return db.prepare(
    `SELECT d.*, u.full_name, u.avatar_url
     FROM donations d
     JOIN users u ON u.id = d.recipient_id
     WHERE d.item_id=? AND d.status='PENDING'
     ORDER BY d.created_at DESC`
  ).all(itemId);
}

function cancelOtherPendingRequests(itemId, acceptedDonationId) {
  db.prepare(
    `UPDATE donations
     SET status='CANCELLED',
         cancelled_at=datetime('now'),
         updated_at=datetime('now')
     WHERE item_id=?
       AND status='PENDING'
       AND id <> ?`
  ).run(itemId, acceptedDonationId);
}

function setDonorConfirmed(donationId) {
  db.prepare(
    `UPDATE donations
     SET donor_confirmed_at = COALESCE(donor_confirmed_at, datetime('now')),
         updated_at=datetime('now')
     WHERE id=?`
  ).run(donationId);
}

function setRecipientConfirmed(donationId) {
  db.prepare(
    `UPDATE donations
     SET recipient_confirmed_at = COALESCE(recipient_confirmed_at, datetime('now')),
         updated_at=datetime('now')
     WHERE id=?`
  ).run(donationId);
}

function completeDonationWithPoints(donationId, points) {
  db.prepare(
    `UPDATE donations
     SET status='COMPLETED',
         completed_at=COALESCE(completed_at, datetime('now')),
         kindness_points_awarded=?,
         updated_at=datetime('now')
     WHERE id=?`
  ).run(points, donationId);
  return db.prepare(`SELECT * FROM donations WHERE id = ?`).get(donationId) || null;
}

function findActiveByItemAndRecipient(itemId, recipientId) {
  return db.prepare(
    `SELECT * FROM donations
     WHERE item_id=? AND recipient_id=?
       AND status IN ('PENDING','ACCEPTED')
     LIMIT 1`
  ).get(itemId, recipientId) || null;
}

function rejectRequest(donationId, donorId, reason = null) {
  db.prepare(
    `UPDATE donations
     SET status='CANCELLED',
         cancelled_at=datetime('now'),
         cancel_reason=COALESCE(?, cancel_reason),
         updated_at=datetime('now')
     WHERE id=?
       AND donor_id=?
       AND status='PENDING'`
  ).run(reason, donationId, donorId);
  const row = db.prepare(`SELECT * FROM donations WHERE id = ?`).get(donationId);
  return (row && row.status === 'CANCELLED') ? row : null;
}

function listUserDonations(userId) {
  return db.prepare(
    `SELECT * FROM donations
     WHERE donor_id = ? OR recipient_id = ?
     ORDER BY created_at DESC`
  ).all(userId, userId);
}

function listUserDonationsDetailed(userId) {
  return db.prepare(
    `SELECT
       d.*,
       i.name AS item_name,
       i.description AS item_description,
       i.image_url AS item_image_url,
       i.status AS item_status,
       i.lat AS item_lat,
       i.lng AS item_lng,
       i.address AS item_address
     FROM donations d
     LEFT JOIN items i ON i.id = d.item_id
     WHERE d.donor_id = ? OR d.recipient_id = ?
     ORDER BY d.created_at DESC`
  ).all(userId, userId);
}

module.exports = {
  createDonation,
  getDonationById,
  getDonationForUpdate,
  findActiveByItemAndRecipient,
  findPendingByItemAndRecipient,
  acceptDonationTx,
  cancelOtherPendingTx,
  setDonorConfirmedTx,
  setRecipientConfirmedTx,
  completeDonationTx,
  listPendingRequestsByItem,
  cancelOtherPendingRequests,
  setDonorConfirmed,
  setRecipientConfirmed,
  completeDonationWithPoints,
  rejectRequest,
  listUserDonationsDetailed,
  listUserDonations
};
