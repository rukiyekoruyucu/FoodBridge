// src/repositories/itemRepository.js
const db = require("../config/db");

function createItem({
  fridgeId,
  donorUserId,
  name,
  description,
  category,
  quantity,
  unit,
  expiryDate,
  imageUrl,
  lat,
  lng,
  address,
}) {
  const info = db.prepare(
    `INSERT INTO items (
       fridge_id, donor_user_id, name, description, category,
       quantity, unit, expiry_date, status, image_url, lat, lng, address
     )
     VALUES (?, ?, ?, ?, ?, COALESCE(?, 1), ?, ?, 'AVAILABLE', ?, ?, ?, ?)`
  ).run(
    fridgeId,
    donorUserId,
    name,
    description ?? null,
    category ?? null,
    quantity ?? null,
    unit ?? null,
    expiryDate ?? null,
    imageUrl ?? null,
    lat ?? null,
    lng ?? null,
    address ?? null
  );
  return db.prepare(`SELECT * FROM items WHERE id = ?`).get(info.lastInsertRowid);
}

function listLatestFeed({ category = null, q = null, limit = 20 }) {
  return db.prepare(
    `SELECT
       i.*,
       f.latitude  AS fridge_latitude,
       f.longitude AS fridge_longitude,
       f.address   AS fridge_address,
       u.id        AS donor_id,
       u.username  AS donor_username,
       u.full_name AS donor_full_name,
       u.avatar_url AS donor_avatar_url
     FROM items i
     JOIN fridges f ON f.id = i.fridge_id
     JOIN users u ON u.id = i.donor_user_id
     WHERE i.status = 'AVAILABLE'
       AND f.is_public = 1
       AND (? IS NULL OR i.category = ?)
       AND (
         ? IS NULL
         OR i.name LIKE '%' || ? || '%'
         OR COALESCE(i.description,'') LIKE '%' || ? || '%'
       )
     ORDER BY i.created_at DESC
     LIMIT ?`
  ).all(category, category, q, q, q, Math.min(Math.max(parseInt(limit, 10) || 20, 1), 50));
}

function listItemsInFridge(fridgeId) {
  return db.prepare(
    `SELECT * FROM items
     WHERE fridge_id = ? AND status IN ('AVAILABLE','RESERVED')
     ORDER BY created_at DESC`
  ).all(fridgeId);
}

function getItemById(id) {
  return db.prepare(`SELECT * FROM items WHERE id = ?`).get(id) || null;
}

function reserveIfAvailable(itemId) {
  db.prepare(
    `UPDATE items
     SET status='RESERVED',
         updated_at=datetime('now')
     WHERE id=? AND status='AVAILABLE'`
  ).run(itemId);
  const row = db.prepare(`SELECT * FROM items WHERE id = ?`).get(itemId);
  return row && row.status === 'RESERVED' ? row : null;
}

function markItemStatus(id, status) {
  db.prepare(
    `UPDATE items
     SET status = ?,
         updated_at = datetime('now')
     WHERE id = ?`
  ).run(status, id);
  return db.prepare(`SELECT * FROM items WHERE id = ?`).get(id) || null;
}

// Tx version (no client needed — same db connection)
function markItemStatusTx(id, status) {
  db.prepare(
    `UPDATE items
     SET status = ?,
         updated_at = datetime('now')
     WHERE id = ?`
  ).run(status, id);
  return db.prepare(`SELECT * FROM items WHERE id = ?`).get(id) || null;
}

function findExpiringItems(daysBefore = 2) {
  return db.prepare(
    `SELECT * FROM items
     WHERE status = 'AVAILABLE'
       AND expiry_date IS NOT NULL
       AND expiry_date <= date('now', '+' || ? || ' days')`
  ).all(daysBefore);
}

function listFeed({ mode = "latest", lat = null, lng = null, radiusKm = 10, category = null, q = null, limit = 20 }) {
  const params = [];
  const where = [];

  where.push(`i.status = 'AVAILABLE'`);
  where.push(`f.is_public = 1`);

  if (q) {
    params.push(q, q);
    where.push(`(
      i.name LIKE '%' || ? || '%'
      OR COALESCE(i.description,'') LIKE '%' || ? || '%'
    )`);
  }

  if (category) {
    params.push(category);
    where.push(`i.category = ?`);
  }

  let distanceSelect = `NULL AS distance_km`;

  if (mode === "nearby") {
    if (lat == null || lng == null) {
      throw new Error("lat/lng required for nearby");
    }

    const latN = Number(lat);
    const lngN = Number(lng);
    const radKm = Number(radiusKm);

    // We'll use JS-side params for haversine (SQLite has no acos/radians by default,
    // but better-sqlite3 inherits the built-in math functions which ARE available)
    params.push(latN, lngN, latN, lngN);
    distanceSelect = `
      (6371 * acos(
        cos(radians(?)) * cos(radians(f.latitude)) *
        cos(radians(f.longitude) - radians(?)) +
        sin(radians(?)) * sin(radians(f.latitude))
      )) AS distance_km
    `;

    params.push(latN, lngN, latN, lngN, radKm);
    where.push(`(
      6371 * acos(
        cos(radians(?)) * cos(radians(f.latitude)) *
        cos(radians(f.longitude) - radians(?)) +
        sin(radians(?)) * sin(radians(f.latitude))
      )
    ) <= ?`);
  }

  const safeLimit = Math.min(Math.max(parseInt(limit, 10) || 20, 1), 50);
  params.push(safeLimit);

  const sql = `
    SELECT
      i.*,
      f.latitude  AS fridge_latitude,
      f.longitude AS fridge_longitude,
      f.address   AS fridge_address,
      u.id        AS donor_id,
      u.username  AS donor_username,
      u.full_name AS donor_full_name,
      u.avatar_url AS donor_avatar_url,
      ${distanceSelect}
    FROM items i
    JOIN fridges f ON f.id = i.fridge_id
    JOIN users   u ON u.id = i.donor_user_id
    WHERE ${where.join(" AND ")}
    ORDER BY ${mode === "nearby" ? "distance_km ASC" : "i.created_at DESC"}
    LIMIT ?
  `;

  return db.prepare(sql).all(...params);
}

function listMapMarkers({ lat, lng, radiusKm = 10, category = null, q = null, limit = 200 }) {
  return db.prepare(
    `WITH base AS (
      SELECT
        i.id,
        i.name,
        i.category,
        i.lat,
        i.lng,
        i.address,
        (6371 * acos(
          cos(radians(?)) * cos(radians(i.lat)) *
          cos(radians(i.lng) - radians(?)) +
          sin(radians(?)) * sin(radians(i.lat))
        )) AS distance_km
      FROM items i
      JOIN fridges f ON f.id = i.fridge_id
      WHERE i.status = 'AVAILABLE'
        AND f.is_public = 1
        AND i.lat IS NOT NULL
        AND i.lng IS NOT NULL
        AND (? IS NULL OR i.category = ?)
        AND (
          ? IS NULL
          OR i.name LIKE '%' || ? || '%'
          OR COALESCE(i.description,'') LIKE '%' || ? || '%'
        )
    )
    SELECT *
    FROM base
    WHERE distance_km <= ?
    ORDER BY distance_km ASC
    LIMIT ?`
  ).all(lat, lng, lat, category, category, q, q, q, radiusKm, limit);
}

function listMyPrivateItems(userId, limit = 200) {
  return db.prepare(
    `SELECT
       i.*,
       f.name AS fridge_name,
       f.is_public
     FROM items i
     JOIN fridges f ON f.id = i.fridge_id
     WHERE f.owner_user_id = ?
       AND f.is_public = 0
       AND i.status IN ('AVAILABLE','RESERVED')
     ORDER BY i.expiry_date ASC, i.created_at DESC
     LIMIT ?`
  ).all(userId, limit);
}

function listMyPublicItems(userId, limit = 200) {
  return db.prepare(
    `SELECT
       i.*,
       f.is_public,
       f.name AS fridge_name
     FROM items i
     JOIN fridges f ON f.id = i.fridge_id
     WHERE i.donor_user_id = ?
       AND f.is_public = 1
       AND i.status IN ('AVAILABLE','RESERVED','REMOVED','EXPIRED')
     ORDER BY i.created_at DESC
     LIMIT ?`
  ).all(userId, limit);
}

function updateItemById({ id, donorUserId, name, description, category, quantity, unit, expiryDate, address }) {
  db.prepare(
    `UPDATE items
     SET
       name        = COALESCE(?, name),
       description = COALESCE(?, description),
       category    = COALESCE(?, category),
       quantity    = COALESCE(?, quantity),
       unit        = COALESCE(?, unit),
       expiry_date = COALESCE(?, expiry_date),
       address     = COALESCE(?, address),
       updated_at  = datetime('now')
     WHERE id = ?
       AND donor_user_id = ?`
  ).run(
    name ?? null, description ?? null, category ?? null,
    quantity ?? null, unit ?? null, expiryDate ?? null,
    address ?? null, id, donorUserId
  );
  return db.prepare(`SELECT * FROM items WHERE id = ? AND donor_user_id = ?`).get(id, donorUserId) || null;
}

function removeItemById({ id, donorUserId }) {
  db.prepare(
    `UPDATE items
     SET status='REMOVED', updated_at=datetime('now')
     WHERE id=? AND donor_user_id=?`
  ).run(id, donorUserId);
  return db.prepare(`SELECT * FROM items WHERE id = ?`).get(id) || null;
}

function getItemDetail(id) {
  return db.prepare(
    `SELECT
       i.*,
       f.latitude AS fridge_latitude,
       f.longitude AS fridge_longitude,
       f.address AS fridge_address,
       u.full_name AS donor_full_name,
       u.avatar_url AS donor_avatar_url,
       u.bio AS donor_bio
     FROM items i
     JOIN fridges f ON f.id = i.fridge_id
     JOIN users u ON u.id = i.donor_user_id
     WHERE i.id = ?
     LIMIT 1`
  ).get(id) || null;
}

function findMyPublicItemsWithSummary(userId, limit = 200) {
  // SQLite doesn't support FILTER (WHERE ...) in aggregates.
  // Use conditional aggregation with CASE instead.
  return db.prepare(
    `SELECT
       i.*,
       COUNT(CASE WHEN d.status = 'PENDING' THEN 1 END) AS pending_request_count,
       MAX(CASE WHEN d.status = 'ACCEPTED' THEN d.id END) AS accepted_donation_id,
       MAX(CASE WHEN d.status = 'ACCEPTED' THEN u.full_name END) AS accepted_recipient_full_name,
       MAX(CASE WHEN d.status = 'ACCEPTED' THEN u.avatar_url END) AS accepted_recipient_avatar_url,
       MAX(d.donor_confirmed_at) AS donor_confirmed_at,
       MAX(d.recipient_confirmed_at) AS recipient_confirmed_at
     FROM items i
     LEFT JOIN donations d ON d.item_id = i.id
     LEFT JOIN users u ON u.id = d.recipient_id
     WHERE i.donor_user_id = ?
     GROUP BY i.id
     ORDER BY i.created_at DESC
     LIMIT ?`
  ).all(userId, limit);
}

function getPublicProfileBundle({ userId, limit = 30 }) {
  const user = db.prepare(
    `SELECT id, username, full_name, avatar_url, bio
     FROM users
     WHERE id = ?
     LIMIT 1`
  ).get(userId) || null;

  const items = db.prepare(
    `SELECT
       i.*,
       f.latitude  AS fridge_latitude,
       f.longitude AS fridge_longitude,
       f.address   AS fridge_address
     FROM items i
     JOIN fridges f ON f.id = i.fridge_id
     WHERE i.status = 'AVAILABLE'
       AND f.is_public = 1
       AND i.donor_user_id = ?
     ORDER BY i.created_at DESC
     LIMIT ?`
  ).all(userId, limit);

  return { user, items };
}

function listPublicItemsByUser({ userId, limit = 30 }) {
  return db.prepare(
    `SELECT
       i.*,
       f.latitude  AS fridge_latitude,
       f.longitude AS fridge_longitude,
       f.address   AS fridge_address,
       u.id        AS donor_id,
       u.username  AS donor_username,
       u.full_name AS donor_full_name,
       u.avatar_url AS donor_avatar_url,
       u.bio AS donor_bio
     FROM items i
     JOIN fridges f ON f.id = i.fridge_id
     JOIN users u ON u.id = i.donor_user_id
     WHERE i.status = 'AVAILABLE'
       AND f.is_public = 1
       AND i.donor_user_id = ?
     ORDER BY i.created_at DESC
     LIMIT ?`
  ).all(userId, limit);
}

module.exports = {
  createItem,
  listItemsInFridge,
  listLatestFeed,
  listMyPublicItems,
  listMyPrivateItems,
  findExpiringItems,
  getItemById,
  getItemDetail,

  reserveIfAvailable,
  markItemStatus,
  markItemStatusTx,

  listFeed,
  listMapMarkers,

  updateItemById,
  removeItemById,
  listPublicItemsByUser,
  getPublicProfileBundle,
  findMyPublicItemsWithSummary
};
