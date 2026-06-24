// src/repositories/fridgeRepository.js
const db = require("../config/db");

function createFridge({ ownerUserId, name, description, lat, lon, address, isPublic }) {
  const info = db.prepare(
    `INSERT INTO fridges (owner_user_id, name, description, latitude, longitude, address, is_public)
     VALUES (?, ?, ?, ?, ?, ?, ?)`
  ).run(ownerUserId, name, description ?? null, lat ?? 0, lon ?? 0, address ?? null, isPublic ? 1 : 0);

  return db.prepare(`SELECT * FROM fridges WHERE id = ?`).get(info.lastInsertRowid);
}

function getFridgeById(id) {
  return db.prepare(`SELECT * FROM fridges WHERE id = ?`).get(id) || null;
}

function getFridgesNear() {
  return db.prepare(`SELECT * FROM fridges WHERE is_public = 1`).all();
}

function listMyPublicFridges(userId) {
  return db.prepare(
    `SELECT *
     FROM fridges
     WHERE owner_user_id = ?
       AND is_public = 1
     ORDER BY created_at DESC`
  ).all(userId);
}

module.exports = {
  createFridge,
  getFridgeById,
  getFridgesNear,
  listMyPublicFridges,
};
