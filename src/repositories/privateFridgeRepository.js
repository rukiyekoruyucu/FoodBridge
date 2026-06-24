// src/repositories/privateFridgeRepository.js
const db = require("../config/db");

// ---- Private fridges (fridges table, is_public=0) ----

function listMyPrivateFridges(userId) {
  return db.prepare(
    `SELECT *
     FROM fridges
     WHERE owner_user_id = ? AND is_public = 0
     ORDER BY created_at DESC`
  ).all(userId);
}

function createPrivateFridge({ userId, name, description, lat, lon, address }) {
  const info = db.prepare(
    `INSERT INTO fridges (owner_user_id, name, description, latitude, longitude, address, is_public)
     VALUES (?, ?, ?, ?, ?, ?, 0)`
  ).run(userId, name, description ?? null, lat ?? 0, lon ?? 0, address ?? null);
  return db.prepare(`SELECT * FROM fridges WHERE id = ?`).get(info.lastInsertRowid);
}

function getMyPrivateFridgeById({ userId, fridgeId }) {
  return db.prepare(
    `SELECT *
     FROM fridges
     WHERE id = ?
       AND owner_user_id = ?
       AND is_public = 0
     LIMIT 1`
  ).get(fridgeId, userId) || null;
}

function listItemsInPrivateFridge({ userId, fridgeId }) {
  return db.prepare(
    `SELECT i.*
     FROM items i
     JOIN fridges f ON f.id = i.fridge_id
     WHERE i.fridge_id = ?
       AND f.owner_user_id = ?
       AND f.is_public = 0
       AND i.status IN ('AVAILABLE','RESERVED')
     ORDER BY i.expiry_date ASC, i.created_at DESC`
  ).all(fridgeId, userId);
}

function createPrivateItem({
  fridgeId,
  ownerUserId,
  name,
  description,
  category,
  quantity,
  expiryDate,
  unit,
  imageUrl,
}) {
  const info = db.prepare(
    `INSERT INTO items (
       fridge_id, donor_user_id, name, description, category,
       quantity, unit, expiry_date, image_url, status
     )
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'AVAILABLE')`
  ).run(
    fridgeId,
    ownerUserId,
    name,
    description ?? null,
    category ?? null,
    quantity ?? null,
    unit ?? null,
    expiryDate ?? null,
    imageUrl ?? null
  );
  return db.prepare(`SELECT * FROM items WHERE id = ?`).get(info.lastInsertRowid);
}

function moveItemToFridge(itemId, targetFridgeId) {
  db.prepare(
    `UPDATE items
     SET fridge_id = ?,
         updated_at = datetime('now')
     WHERE id = ?`
  ).run(targetFridgeId, itemId);
  return db.prepare(`SELECT * FROM items WHERE id = ?`).get(itemId) || null;
}

function updateMyPrivateFridge({ userId, fridgeId, name, description, lat, lon, address }) {
  db.prepare(
    `UPDATE fridges
     SET
       name        = COALESCE(?, name),
       description = COALESCE(?, description),
       latitude    = COALESCE(?, latitude),
       longitude   = COALESCE(?, longitude),
       address     = COALESCE(?, address),
       updated_at  = datetime('now')
     WHERE id = ? AND owner_user_id = ? AND is_public = 0`
  ).run(name ?? null, description ?? null, lat ?? null, lon ?? null, address ?? null, fridgeId, userId);
  return db.prepare(`SELECT * FROM fridges WHERE id = ? AND owner_user_id = ? AND is_public = 0`).get(fridgeId, userId) || null;
}

/**
 * DELETE...USING not supported in SQLite.
 * Replaced with subquery in WHERE clause.
 */
function deleteItemInMyPrivateFridge({ userId, fridgeId, itemId }) {
  const info = db.prepare(
    `DELETE FROM items
     WHERE id = ?
       AND fridge_id = ?
       AND fridge_id IN (
         SELECT id FROM fridges WHERE id = ? AND owner_user_id = ? AND is_public = 0
       )`
  ).run(itemId, fridgeId, fridgeId, userId);
  return info.changes > 0;
}

function deleteMyPrivateFridge({ userId, fridgeId }) {
  const info = db.prepare(
    `DELETE FROM fridges
     WHERE id = ? AND owner_user_id = ? AND is_public = 0`
  ).run(fridgeId, userId);
  return info.changes > 0;
}

function getItemInMyPrivateFridge({ userId, fridgeId, itemId }) {
  return db.prepare(
    `SELECT i.*
     FROM items i
     JOIN fridges f ON f.id = i.fridge_id
     WHERE i.id = ?
       AND i.fridge_id = ?
       AND f.owner_user_id = ?
       AND f.is_public = 0
     LIMIT 1`
  ).get(itemId, fridgeId, userId) || null;
}

function updateItemInMyPrivateFridge({ userId, fridgeId, itemId, patch }) {
  const {
    name,
    description,
    category,
    quantity,
    expiryDate,
    unit,
    imageUrl,
  } = patch || {};

  // Verify ownership first
  const existing = getItemInMyPrivateFridge({ userId, fridgeId, itemId });
  if (!existing) return null;

  // Handle expiryDate: undefined = keep, null = keep, "null" string = clear
  let newExpiryDate;
  if (expiryDate === "null") {
    newExpiryDate = null;
  } else if (expiryDate !== undefined && expiryDate !== null) {
    newExpiryDate = expiryDate;
  } else {
    newExpiryDate = existing.expiry_date;
  }

  db.prepare(
    `UPDATE items
     SET
       name        = COALESCE(?, name),
       description = COALESCE(?, description),
       category    = COALESCE(?, category),
       quantity    = COALESCE(?, quantity),
       unit        = COALESCE(?, unit),
       expiry_date = ?,
       image_url   = COALESCE(?, image_url),
       updated_at  = datetime('now')
     WHERE id = ?`
  ).run(
    name ?? null,
    description ?? null,
    category ?? null,
    quantity ?? null,
    unit ?? null,
    newExpiryDate,
    imageUrl ?? null,
    itemId
  );

  return db.prepare(`SELECT * FROM items WHERE id = ?`).get(itemId) || null;
}

function deleteItemsInMyPrivateFridge({ userId, fridgeId, itemId }) {
  db.prepare(
    `DELETE FROM items
     WHERE id = ?
       AND fridge_id = ?
       AND fridge_id IN (
         SELECT id FROM fridges WHERE id = ? AND owner_user_id = ? AND is_public = 0
       )`
  ).run(itemId, fridgeId, fridgeId, userId);
}

function listExpiringItemsInMyPrivateFridge({ userId, fridgeId, daysBefore = 2 }) {
  return db.prepare(
    `SELECT i.*
     FROM items i
     JOIN fridges f ON f.id = i.fridge_id
     WHERE i.fridge_id = ?
       AND f.owner_user_id = ?
       AND f.is_public = 0
       AND i.status IN ('AVAILABLE','RESERVED')
       AND i.expiry_date IS NOT NULL
       AND i.expiry_date <= date('now', '+' || ? || ' days')
     ORDER BY i.expiry_date ASC`
  ).all(fridgeId, userId, daysBefore);
}

module.exports = {
  listMyPrivateFridges,
  createPrivateFridge,
  getMyPrivateFridgeById,
  listItemsInPrivateFridge,
  createPrivateItem,
  moveItemToFridge,
  updateMyPrivateFridge,
  deleteItemsInMyPrivateFridge,
  deleteMyPrivateFridge,
  getItemInMyPrivateFridge,
  updateItemInMyPrivateFridge,
  deleteItemInMyPrivateFridge,
  listExpiringItemsInMyPrivateFridge,
};