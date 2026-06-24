const fridgeRepository = require("../repositories/fridgeRepository");
const { distanceKm } = require("../utils/geo");
const ApiError = require("../utils/ApiError");

async function createFridge({ ownerUserId, name, description, lat, lon, address, isPublic }) {
  if (!name || lat == null || lon == null) {
    throw new ApiError(400, "Missing required fields for fridge");
  }
  return fridgeRepository.createFridge({
    ownerUserId,
    name,
    description,
    lat,
    lon,
    address,
    isPublic: isPublic ?? true
  });
}

async function getNearbyFridges(lat, lon, radiusKm = 5) {
  const all = await fridgeRepository.getFridgesNear();
  const filtered = all.filter((f) => {
    if (f.latitude == null || f.longitude == null) return false;
    const d = distanceKm(lat, lon, f.latitude, f.longitude);
    return d <= radiusKm;
  });
  return filtered;
}

async function getFridgeById(id) {
  const fridge = await fridgeRepository.getFridgeById(id);
  if (!fridge) throw new ApiError(404, "Fridge not found");
  return fridge;
}

module.exports = {
  createFridge,
  getNearbyFridges,
  getFridgeById
};
