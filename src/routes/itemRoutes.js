const express = require("express");
const router = express.Router();
const auth = require("../middlewares/authMiddleware");
const role = require("../middlewares/roleMiddleware");
const itemController = require("../controllers/itemController");
const Joi = require("joi");
const validate = require("../middlewares/validationMiddleware");
const updateItemSchema = Joi.object({
  name: Joi.string().min(2).optional(),
  description: Joi.string().allow("", null).optional(),
  category: Joi.string().allow("", null).optional(),
  quantity: Joi.number().integer().min(1).allow(null).optional(),
  unit: Joi.string().allow("", null).optional(),
  expiryDate: Joi.date().iso().optional(),
  address: Joi.string().allow("", null).optional(),
});

const createItemSchema = Joi.object({
  // fridgeId yok ✅
  name: Joi.string().min(2).required(),
  description: Joi.string().allow("", null),
  category: Joi.string().allow("", null),
  quantity: Joi.number().integer().min(1).optional(),
  unit: Joi.string().allow("", null).optional(),
  // publicte zorunlu ✅
  expiryDate: Joi.date().iso().required(),
  lat: Joi.number().required(),
  lng: Joi.number().required(),
  address: Joi.string().allow("", null).optional(),
  imageUrl: Joi.string().uri().allow("", null).optional(),
});



// feed + map + detail
router.get("/feed", auth, itemController.getFeed);
router.get("/map", auth, itemController.getMap);
router.get("/my", auth, itemController.getMyPrivateItems);

router.get("/my-public", auth, role(["PERSONAL","CORPORATE"]), itemController.getMyPublicItems);
router.get("/by-user/:userId", auth, itemController.getPublicItemsByUser);

// ✅ bunu buraya al
router.get("/fridges/:fridgeId", auth, itemController.listItemsByFridge);

// ✅ en sona bırak
router.get("/:id", auth, itemController.getItemDetail);

router.put(
  "/:id",
  auth,
  role(["PERSONAL","CORPORATE"]),
  validate(updateItemSchema),
  itemController.updateMyItem
);

router.delete(
  "/:id",
  auth,
  role(["PERSONAL","CORPORATE"]),
  itemController.removeMyItem
);

// create item
router.post(
  "/",
  auth,
  role(["PERSONAL", "CORPORATE"]),
  validate(createItemSchema),
  itemController.createItem
);

module.exports = router;
