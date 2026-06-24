const ApiError = require("../utils/ApiError");
const privateFridgeRepository = require("../repositories/privateFridgeRepository");
const fridgeRepository = require("../repositories/fridgeRepository");
const itemRepository = require("../repositories/itemRepository");
const db = require("../config/db");

function roleUpper(role) {
  return String(role || "").trim().toUpperCase();
}

async function listMyPrivateFridges(userId) {
  return privateFridgeRepository.listMyPrivateFridges(userId);
}

async function createPrivateFridge({ userId, name, description, lat, lon, address }) {
  return privateFridgeRepository.createPrivateFridge({
    userId,
    name,
    description,
    lat,
    lon,
    address,
  });
}

async function listItems({ userId, fridgeId }) {
  const fridge = await privateFridgeRepository.getMyPrivateFridgeById({ userId, fridgeId });
  if (!fridge) throw new ApiError(404, "Private fridge not found");
  return privateFridgeRepository.listItemsInPrivateFridge({ userId, fridgeId });
}

async function addPrivateItem({
  userId,
  fridgeId,
  name,
  description,
  category,
  quantity,
  expiryDate,
  unit,
  imageUrl,
}) {
  const fridge = await privateFridgeRepository.getMyPrivateFridgeById({ userId, fridgeId });
  if (!fridge) throw new ApiError(404, "Private fridge not found");

  return privateFridgeRepository.createPrivateItem({
    fridgeId,
    ownerUserId: userId,
    name,
    description,
    category,
    quantity,
    expiryDate,
    unit,
    imageUrl,
  });
}

async function transferItemToPublicFridge({ userId, role, itemId, targetFridgeId }) {
  const r = roleUpper(role);
  if (r === "NEEDY") throw new ApiError(403, "Needy users cannot create donations");

  const item = await itemRepository.getItemById(itemId);
  if (!item) throw new ApiError(404, "Item not found");

  // item owner kontrol (private item’i kim eklediyse donor_user_id=userId yaptık)
  if (item.donor_user_id !== userId) {
    throw new ApiError(403, "You are not the owner of this item");
  }

  const targetFridge = await fridgeRepository.getFridgeById(targetFridgeId);
  if (!targetFridge) throw new ApiError(404, "Target fridge not found");

  if (targetFridge.owner_user_id !== userId) {
    throw new ApiError(403, "You are not the owner of the target fridge");
  }

  if (targetFridge.is_public !== true) {
    throw new ApiError(400, "Target fridge must be public");
  }
   return privateFridgeRepository.moveItemToFridge(itemId, targetFridgeId);
}

async function listMyPublicFridges(userId) {
  return fridgeRepository.listMyPublicFridges(userId);
}
async function updatePrivateFridge({ userId, fridgeId, name, description, lat, lon, address }) {
  const fridge = await privateFridgeRepository.getMyPrivateFridgeById({ userId, fridgeId });
  if (!fridge) throw new ApiError(404, "Private fridge not found");

  return privateFridgeRepository.updateMyPrivateFridge({
    userId,
    fridgeId,
    name,
    description,
    lat,
    lon,
    address,
  });
}

async function deletePrivateFridge({ userId, fridgeId }) {
  const fridge = await privateFridgeRepository.getMyPrivateFridgeById({ userId, fridgeId });
  if (!fridge) throw new ApiError(404, "Private fridge not found");

  // güvenli silme: önce items, sonra fridge (transaction)
  await db.query("BEGIN");
  try {
    await privateFridgeRepository.deleteItemsInMyPrivateFridge({ userId, fridgeId });
    await privateFridgeRepository.deleteMyPrivateFridge({ userId, fridgeId });
    await db.query("COMMIT");
  } catch (e) {
    await db.query("ROLLBACK");
    throw e;
  }
}

async function updatePrivateItem({ userId, fridgeId, itemId, patch }) {
  const fridge = await privateFridgeRepository.getMyPrivateFridgeById({ userId, fridgeId });
  if (!fridge) throw new ApiError(404, "Private fridge not found");

  const item = await privateFridgeRepository.getItemInMyPrivateFridge({ userId, fridgeId, itemId });
  if (!item) throw new ApiError(404, "Item not found");

  // expiryDate null gelirse temizleme için destek
  return privateFridgeRepository.updateItemInMyPrivateFridge({
    userId,
    fridgeId,
    itemId,
    patch,
  });
}

async function deletePrivateItem({ userId, fridgeId, itemId }) {
  const fridge = await privateFridgeRepository.getMyPrivateFridgeById({ userId, fridgeId });
  if (!fridge) throw new ApiError(404, "Private fridge not found");

  const item = await privateFridgeRepository.getItemInMyPrivateFridge({ userId, fridgeId, itemId });
  if (!item) throw new ApiError(404, "Item not found");

  await privateFridgeRepository.deleteItemInMyPrivateFridge({ userId, fridgeId, itemId });
}

async function listExpiringItemsInPrivateFridge({ userId, fridgeId, daysBefore = 2 }) {
  const fridge = await privateFridgeRepository.getMyPrivateFridgeById({ userId, fridgeId });
  if (!fridge) throw new ApiError(404, "Private fridge not found");

  return privateFridgeRepository.listExpiringItemsInMyPrivateFridge({ userId, fridgeId, daysBefore });
}


module.exports = {
  listMyPrivateFridges,
  createPrivateFridge,
  listItems,
  addPrivateItem,
  transferItemToPublicFridge,
  listMyPublicFridges,
  updatePrivateFridge,
  deletePrivateFridge,
  updatePrivateItem,
  deletePrivateItem,
  listExpiringItemsInPrivateFridge,
};
