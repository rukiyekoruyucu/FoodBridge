const ApiError = require("../utils/ApiError");
const itemService = require("../services/itemService");
const db = require("../config/db");

function toNumberOrNull(v) {
  if (v === undefined || v === null || v === "") return null;
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
}

function toIntOr(v, fallback) {
  const n = parseInt(v, 10);
  return Number.isFinite(n) ? n : fallback;
}

function cleanStringOrNull(v) {
  if (v === undefined || v === null) return null;
  if (typeof v !== "string") return null;
  const s = v.trim();
  return s.length ? s : null;
}

// GET /api/items/feed?mode=latest|nearby&lat=&lng=&radiusKm=&category=&limit=
async function getFeed(req, res, next) {
  try {
    const mode = (req.query.mode || "latest").toLowerCase();

    const limit = Math.min(Math.max(toIntOr(req.query.limit, 20), 1), 50);
    const offset = Math.max(toIntOr(req.query.offset, 0), 0); // ✅ Pagination
    const category = cleanStringOrNull(req.query.category);
    const q = cleanStringOrNull(req.query.q);

    if (mode === "latest") {
      const rows = await itemService.getLatestFeed({ category, q, limit, offset });
      return res.json(rows);
    }

    if (mode === "nearby") {
      const lat = toNumberOrNull(req.query.lat);
      const lng = toNumberOrNull(req.query.lng);

      if (lat === null || lng === null) {
        throw new ApiError(400, "lat and lng are required and must be numbers");
      }

      const radiusKm = Math.min(
        Math.max(toNumberOrNull(req.query.radiusKm) ?? 10, 1),
        200
      );

      const rows = await itemService.getFeed({
        lat, lng, radiusKm, category, q, limit, offset,
      });

      return res.json(rows);
    }

    throw new ApiError(400, "Invalid mode. Use latest or nearby.");
  } catch (e) {
    next(e);
  }
}

// GET /api/items/map?lat=&lng=&radiusKm=&category=&q=&limit=
async function getMap(req, res, next) {
  try {
    const lat = toNumberOrNull(req.query.lat);
    const lng = toNumberOrNull(req.query.lng);

    if (lat === null || lng === null) {
      throw new ApiError(400, "lat and lng are required and must be numbers");
    }

    const radiusKm = Math.min(
      Math.max(toNumberOrNull(req.query.radiusKm) ?? 10, 1),
      200
    );
    const limit = Math.min(Math.max(toIntOr(req.query.limit, 200), 1), 500);

    const category = cleanStringOrNull(req.query.category);
    const q = cleanStringOrNull(req.query.q);

    const rows = await itemService.getMapMarkers({
      lat,
      lng,
      radiusKm,
      category,
      q,
      limit,
    });
    res.json(rows);
  } catch (e) {
    next(e);
  }
}

// GET /api/items/:id
async function getItemDetail(req, res, next) {
  try {
    const id = parseInt(req.params.id, 10);
    if (!id || Number.isNaN(id)) throw new ApiError(400, "Invalid item id");

    const item = await itemService.getItemDetail(id);
    if (!item) throw new ApiError(404, "Item not found");

    res.json(item);
  } catch (e) {
    next(e);
  }
}
// GET /api/items/my
async function getMyPrivateItems(req, res, next) {
  try {
    const items = await itemService.getMyPrivateItems(req.user.id);
    res.json(items);
  } catch (e) {
    next(e);
  }
}

async function getMyPublicItems(req, res, next) {
  try {
    const items = await itemService.getMyPublicItems(req.user.id);
    res.json(items);
  } catch (e) {
    next(e);
  }
}

// GET /api/items/fridges/:fridgeId
async function listItemsByFridge(req, res, next) {
  try {
    const fridgeId = parseInt(req.params.fridgeId, 10);
    if (!fridgeId || Number.isNaN(fridgeId))
      throw new ApiError(400, "Invalid fridgeId");

    const items = await itemService.listFridgeItems(fridgeId);
    res.json(items);
  } catch (e) {
    next(e);
  }
}
async function updateMyItem(req, res, next) {
  try {
    const id = parseInt(req.params.id, 10);
    const patch = req.body;
    const updated = await itemService.updateMyItem({ id, userId: req.user.id, patch });
    res.json(updated);
  } catch (e) {
    next(e);
  }
}

async function removeMyItem(req, res, next) {
  try {
    const id = parseInt(req.params.id, 10);
    const removed = await itemService.removeMyItem(id, req.user.id);
    res.json(removed);
  } catch (e) {
    next(e);
  }
}
// POST /api/items
async function createItem(req, res, next) {
  try {
    const {
      name,
      description,
      category,
      quantity,
      unit,
      expiryDate,
      lat,
      lng,
      address,
      imageUrl,
    } = req.body;

    const publicFridgeRow = db.prepare("SELECT id FROM fridges WHERE is_public = 1 LIMIT 1").get();
    if (!publicFridgeRow) {
      throw new ApiError(500, "No public fridge found in the database");
    }
    const publicFridgeId = publicFridgeRow.id;

    const item = await itemService.createPublicDonation({
      publicFridgeId,
      donorUserId: req.user.id,
      name,
      description,
      category,
      quantity,
      unit,
      expiryDate,
      lat,
      lng,
      address,
      imageUrl,
    });

    res.status(201).json(item);
  } catch (e) {
    next(e);
  }
}

async function getPublicItemsByUser(req, res, next) {
  try {
    const userId = parseInt(req.params.userId, 10);
    if (!userId || Number.isNaN(userId)) throw new ApiError(400, "Invalid userId");

    const limit = Math.min(Math.max(parseInt(req.query.limit || "30", 10), 1), 50);

    const rows = await itemService.getPublicItemsByUser({ userId, limit });
res.json(rows);

  } catch (e) {
    next(e);
  }
}

module.exports = {
  createItem,
  listItemsByFridge,
  getItemDetail,
  getMyPrivateItems,
  getMyPublicItems,
  updateMyItem,
  removeMyItem,
  getFeed,
  getMap,
  getPublicItemsByUser,
};
