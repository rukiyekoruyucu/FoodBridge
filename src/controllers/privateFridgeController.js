const ApiError = require("../utils/ApiError");
const privateFridgeService = require("../services/privateFridgeService");

function toInt(v) {
  const n = parseInt(v, 10);
  return Number.isFinite(n) ? n : null;
}

async function listMyPrivateFridges(req, res, next) {
  try {
    const fridges = await privateFridgeService.listMyPrivateFridges(req.user.id);
    return res.json({ fridges });
  } catch (e) {
    next(e);
  }
}

async function createPrivateFridge(req, res, next) {
  try {
    const { name, description, latitude, longitude, address } = req.body;
    const fridge = await privateFridgeService.createPrivateFridge({
      userId: req.user.id,
      name,
      description,
      lat: latitude,
      lon: longitude,
      address
    });
    return res.status(201).json(fridge);
  } catch (e) {
    next(e);
  }
}

async function listItems(req, res, next) {
  try {
    const fridgeId = toInt(req.params.fridgeId);
    if (!fridgeId) throw new ApiError(400, "Invalid fridgeId");
    const items = await privateFridgeService.listItems({
      userId: req.user.id,
      fridgeId
    });
    return res.json({ items });
  } catch (e) {
    next(e);
  }
}

async function addPrivateItem(req, res, next) {
  try {
    const fridgeId = toInt(req.params.fridgeId);
    if (!fridgeId) throw new ApiError(400, "Invalid fridgeId");
    const { name, description, category, quantity, expiryDate, unit, imageUrl } = req.body;

    const item = await privateFridgeService.addPrivateItem({
      userId: req.user.id,
      fridgeId,
      name,
      description,
      category,
      quantity,
      expiryDate,
      unit,
      imageUrl
    });

    return res.status(201).json({ item });
  } catch (e) {
    next(e);
  }
}

async function transferItemToPublicFridge(req, res, next) {
  try {
    const itemId = toInt(req.params.itemId);
    if (!itemId) throw new ApiError(400, "Invalid itemId");

    const targetFridgeId = toInt(req.body?.targetFridgeId);
    if (!targetFridgeId) throw new ApiError(400, "targetFridgeId is required");

    const item = await privateFridgeService.transferItemToPublicFridge({
      userId: req.user.id,
      role: req.user.role,
      itemId,
      targetFridgeId,
    });

    return res.json({ item });
  } catch (e) {
    next(e);
  }
}

async function listMyPublicFridges(req, res, next) {
  try {
    const fridges = await privateFridgeService.listMyPublicFridges(req.user.id);
    return res.json({ fridges });
  } catch (e) {
    next(e);
  }
}
async function updatePrivateFridge(req, res, next) {
  try {
    const fridgeId = toInt(req.params.fridgeId);
    if (!fridgeId) throw new ApiError(400, "Invalid fridgeId");

    const { name, description, latitude, longitude, address } = req.body;

    const fridge = await privateFridgeService.updatePrivateFridge({
      userId: req.user.id,
      fridgeId,
      name,
      description,
      lat: latitude,
      lon: longitude,
      address,
    });

    return res.json({ fridge });
  } catch (e) {
    next(e);
  }
}

async function deletePrivateFridge(req, res, next) {
  try {
    const fridgeId = toInt(req.params.fridgeId);
    if (!fridgeId) throw new ApiError(400, "Invalid fridgeId");

    await privateFridgeService.deletePrivateFridge({
      userId: req.user.id,
      fridgeId,
    });

    return res.status(204).send();
  } catch (e) {
    next(e);
  }
}

async function updatePrivateItem(req, res, next) {
  try {
    const fridgeId = toInt(req.params.fridgeId);
    const itemId = toInt(req.params.itemId);
    if (!fridgeId) throw new ApiError(400, "Invalid fridgeId");
    if (!itemId) throw new ApiError(400, "Invalid itemId");

    const item = await privateFridgeService.updatePrivateItem({
      userId: req.user.id,
      fridgeId,
      itemId,
      patch: req.body,
    });

    return res.json({ item });
  } catch (e) {
    next(e);
  }
}

async function deletePrivateItem(req, res, next) {
  try {
    const fridgeId = toInt(req.params.fridgeId);
    const itemId = toInt(req.params.itemId);
    if (!fridgeId) throw new ApiError(400, "Invalid fridgeId");
    if (!itemId) throw new ApiError(400, "Invalid itemId");

    await privateFridgeService.deletePrivateItem({
      userId: req.user.id,
      fridgeId,
      itemId,
    });

    return res.status(204).send();
  } catch (e) {
    next(e);
  }
}

async function listExpiringItemsInPrivateFridge(req, res, next) {
  try {
    const fridgeId = toInt(req.params.fridgeId);
    if (!fridgeId) throw new ApiError(400, "Invalid fridgeId");

    const days = toInt(req.query.daysBefore) ?? 2;

    const items = await privateFridgeService.listExpiringItemsInPrivateFridge({
      userId: req.user.id,
      fridgeId,
      daysBefore: days,
    });

    return res.json({ items });
  } catch (e) {
    next(e);
  }
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
