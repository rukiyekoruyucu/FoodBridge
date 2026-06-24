// src/services/donationService.js
const donationRepository = require("../repositories/donationRepository");
const itemRepository = require("../repositories/itemRepository");
const chatRepository = require("../repositories/chatRepository");
const ApiError = require("../utils/ApiError");
const kindnessService = require("./kindnessService");
const db = require("../config/db");

/**
 * NEEDY (veya trade isteyen) -> item için talep oluşturur (PENDING).
 * Item AVAILABLE kalır (çoklu talep için).
 */
function requestDonation({ itemId, requesterId, type = "DONATION" }) {
  const item = itemRepository.getItemById(itemId);
  if (!item) throw new ApiError(404, "Item not found");

  if (item.status !== "AVAILABLE") {
    throw new ApiError(400, "Item is not available");
  }

  if (item.donor_user_id === requesterId) {
    throw new ApiError(400, "Owner cannot request own item");
  }

  const existing = donationRepository.findActiveByItemAndRecipient(itemId, requesterId);
  if (existing) throw new ApiError(409, "You already requested this item");

  const donation = donationRepository.createDonation({
    itemId,
    donorId: item.donor_user_id,
    recipientId: requesterId,
    type
  });

  return donation;
}

/**
 * DONOR -> item için gelen PENDING istekleri listeler
 */
function listItemRequests(itemId, userId) {
  const item = itemRepository.getItemById(itemId);
  if (!item) throw new ApiError(404, "Item not found");
  if (item.donor_user_id !== userId) throw new ApiError(403, "Not item owner");

  return donationRepository.listPendingRequestsByItem(itemId);
}

/**
 * DONOR -> bir request'i ACCEPT eder.
 * - seçileni ACCEPT
 * - diğer PENDING'leri CANCELLED
 * - item -> RESERVED
 * - donation chat room -> auto create
 *
 * SQLite db.transaction() — fully synchronous, ACID.
 */
function acceptRequest(donationId, userId) {
  const acceptTx = db.transaction((donationId, userId) => {
    const donation = db.prepare(`SELECT * FROM donations WHERE id = ?`).get(donationId);
    if (!donation) throw new ApiError(404, "Donation request not found");

    if (donation.donor_id !== userId) {
      throw new ApiError(403, "You are not the donor of this donation");
    }
    if (donation.status !== "PENDING") {
      throw new ApiError(400, "Donation request cannot be accepted");
    }

    const item = db.prepare(`SELECT * FROM items WHERE id = ?`).get(donation.item_id);
    if (!item) throw new ApiError(404, "Item not found");
    if (item.status !== "AVAILABLE") {
      throw new ApiError(400, "Item is not available anymore");
    }

    // 1) seçileni ACCEPT + accepted_at setle
    db.prepare(
      `UPDATE donations
       SET status = 'ACCEPTED',
           accepted_at = datetime('now'),
           updated_at = datetime('now')
       WHERE id = ?`
    ).run(donationId);
    const accepted = db.prepare(`SELECT * FROM donations WHERE id = ?`).get(donationId);

    // 2) diğer pending'leri iptal et
    db.prepare(
      `UPDATE donations
       SET status='CANCELLED',
           cancelled_at=datetime('now'),
           updated_at=datetime('now')
       WHERE item_id=? AND status='PENDING' AND id <> ?`
    ).run(donation.item_id, donationId);

    // 3) item -> RESERVED
    db.prepare(
      `UPDATE items
       SET status='RESERVED',
           updated_at=datetime('now')
       WHERE id=?`
    ).run(donation.item_id);

    // 4) chat room (yoksa) oluştur — INSERT OR IGNORE
    db.prepare(
      `INSERT OR IGNORE INTO chat_rooms (room_type, donation_id)
       VALUES ('DONATION', ?)`
    ).run(donationId);

    return accepted;
  });

  return acceptTx(donationId, userId);
}

/**
 * Çift taraflı teslim onayı.
 * donor -> donor_confirmed_at
 * recipient -> recipient_confirmed_at
 * ikisi de doluysa -> COMPLETED + puan + item REMOVED
 */
function confirmPickup(donationId, userId) {
  const confirmTx = db.transaction((donationId, userId) => {
    const donation = db.prepare(`SELECT * FROM donations WHERE id = ?`).get(donationId);
    if (!donation) throw new ApiError(404, "Donation not found");

    if (donation.status === "COMPLETED") {
      throw new ApiError(409, "Donation already completed");
    }

    if (donation.status !== "ACCEPTED") {
      throw new ApiError(400, "Only ACCEPTED donations can be confirmed");
    }

    const isDonor = donation.donor_id === userId;
    const isRecipient = donation.recipient_id === userId;

    if (!isDonor && !isRecipient) {
      throw new ApiError(403, "You are not part of this donation");
    }

    if (isDonor) {
      db.prepare(
        `UPDATE donations
         SET donor_confirmed_at = COALESCE(donor_confirmed_at, datetime('now')),
             updated_at = datetime('now')
         WHERE id = ?`
      ).run(donationId);
    } else {
      db.prepare(
        `UPDATE donations
         SET recipient_confirmed_at = COALESCE(recipient_confirmed_at, datetime('now')),
             updated_at = datetime('now')
         WHERE id = ?`
      ).run(donationId);
    }

    const fresh = db.prepare(`SELECT * FROM donations WHERE id = ?`).get(donationId);

    if (fresh.donor_confirmed_at && fresh.recipient_confirmed_at) {
      const points = 10;

      db.prepare(
        `UPDATE donations
         SET status = 'COMPLETED',
             completed_at = datetime('now'),
             kindness_points_awarded = ?,
             updated_at = datetime('now')
         WHERE id = ? AND status = 'ACCEPTED'`
      ).run(points, donationId);

      const completed = db.prepare(`SELECT * FROM donations WHERE id = ?`).get(donationId);

      if (completed) {
        // kindnessService.awardKindnessPoints is synchronous after migration
        kindnessService.awardKindnessPoints(fresh.donor_id, points);
        itemRepository.markItemStatusTx(fresh.item_id, "REMOVED");
      }

      return completed;
    }

    return fresh;
  });

  return confirmTx(donationId, userId);
}

function rejectRequest(donationId, userId, reason = null) {
  const rejected = donationRepository.rejectRequest(donationId, userId, reason);
  if (!rejected) throw new ApiError(400, "Request cannot be rejected");
  return rejected;
}

function listUserDonations(userId) {
  return donationRepository.listUserDonationsDetailed(userId);
}

module.exports = {
  requestDonation,
  listItemRequests,
  acceptRequest,
  confirmPickup,
  rejectRequest,
  listUserDonations
};
