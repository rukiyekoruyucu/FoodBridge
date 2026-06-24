const fridgeService = require("../services/fridgeService");

async function createFridge(req, res, next) {
  try {
    const { name, description, latitude, longitude, address, isPublic } = req.body;
    const fridge = await fridgeService.createFridge({
      ownerUserId: req.user.id,
      name,
      description,
      lat: latitude,
      lon: longitude,
      address,
      isPublic
    });
    res.status(201).json(fridge);
  } catch (err) {
    next(err);
  }
}

async function getFridge(req, res, next) {
  try {
    const id = parseInt(req.params.id, 10);
    const fridge = await fridgeService.getFridgeById(id);
    res.json(fridge);
  } catch (err) {
    next(err);
  }
}

module.exports = {
  createFridge,
  getFridge
};
