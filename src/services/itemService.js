// src/services/itemService.js
const itemRepository = require("../repositories/itemRepository");
const fridgeRepository = require("../repositories/fridgeRepository");
const ApiError = require("../utils/ApiError");

function createItemForFridge({ fridgeId, donorUserId, name, description, category, quantity, expiryDate }) {
  const fridge = fridgeRepository.getFridgeById(fridgeId);
  if (!fridge) throw new ApiError(404, "Fridge not found");

  if (fridge.owner_user_id !== donorUserId) {
    throw new ApiError(403, "You are not the owner of this fridge");
  }

  return itemRepository.createItem({
    fridgeId,
    donorUserId,
    name,
    description,
    category,
    quantity,
    expiryDate
  });
}

function listFridgeItems(fridgeId) {
  return itemRepository.listItemsInFridge(fridgeId);
}

function markItemExpired(itemId) {
  return itemRepository.markItemStatus(itemId, "EXPIRED");
}

function getFeed(params) {
  return itemRepository.listFeed(params);
}

function getMyPrivateItems(userId) {
  return itemRepository.listMyPrivateItems(userId);
}

function getMapMarkers(params) {
  return itemRepository.listMapMarkers(params);
}

function getItemDetail(id) {
  return itemRepository.getItemDetail(id);
}

function getLatestFeed({ category = null, q = null, limit = 20, offset = 0 }) {
  return itemRepository.listLatestFeed({ category, q, limit, offset });
}

function getPublicItemsByUser({ userId, limit = 30 }) {
  return itemRepository.listPublicItemsByUser({ userId, limit });
}

function updateMyItem({ id, userId, patch }) {
  const updated = itemRepository.updateItemById({ id, donorUserId: userId, ...patch });
  if (!updated) throw new ApiError(404, "Item not found or not yours");
  return updated;
}

function getMyPublicItems(userId, limit) {
  return itemRepository.findMyPublicItemsWithSummary(userId, limit);
}

function removeMyItem(id, userId) {
  const removed = itemRepository.removeItemById({ id, donorUserId: userId });
  if (!removed) throw new ApiError(404, "Item not found or not yours");
  return removed;
}

function getPublicProfileBundle({ userId, limit = 30 }) {
  return itemRepository.getPublicProfileBundle({ userId, limit });
}

function createPublicDonation({
  publicFridgeId,
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
  return itemRepository.createItem({
    fridgeId: publicFridgeId,
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
  });
}

module.exports = {
  createItemForFridge,
  listFridgeItems,
  getMyPublicItems,
  getLatestFeed,
  getFeed,
  createPublicDonation,
  getMapMarkers,
  getMyPrivateItems,
  updateMyItem,
  removeMyItem,
  getItemDetail,
  getPublicItemsByUser,
  getPublicProfileBundle,
  markItemExpired
};
