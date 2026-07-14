const express = require("express");
const router = express.Router();
const auth = require("../middlewares/authMiddleware");
const role = require("../middlewares/roleMiddleware");
const Joi = require("joi");
const validate = require("../middlewares/validationMiddleware");
const c = require("../controllers/privateFridgeController");

const createPrivateFridgeSchema = Joi.object({
  name: Joi.string().min(2).required(),
  description: Joi.string().allow("", null),
  latitude: Joi.number().required(),
  longitude: Joi.number().required(),
  address: Joi.string().allow("", null),
});

const createPrivateItemSchema = Joi.object({
  name: Joi.string().min(2).required(),
  description: Joi.string().allow("", null),
  category: Joi.string().allow("", null),
  quantity: Joi.number().integer().min(1).required(),
  expiryDate: Joi.string().isoDate().optional(),
  unit: Joi.string().allow("", null).optional(),
  imageUrl: Joi.string().uri().allow("", null).optional(),
});

const updatePrivateFridgeSchema = Joi.object({
  name: Joi.string().min(2).optional(),
  description: Joi.string().allow("", null).optional(),
  latitude: Joi.number().optional(),
  longitude: Joi.number().optional(),
  address: Joi.string().allow("", null).optional(),
}).min(1);

const updatePrivateItemSchema = Joi.object({
  name: Joi.string().min(2).optional(),
  description: Joi.string().allow("", null).optional(),
  category: Joi.string().allow("", null).optional(),
  quantity: Joi.number().integer().min(1).optional(),
  expiryDate: Joi.string().isoDate().allow(null).optional(),
  unit: Joi.string().allow("", null).optional(),
  imageUrl: Joi.string().uri().allow("", null).optional(),
}).min(1);

// ─────────────────────────────────────────────────────────────────────────────
// ✅ ÖNEMLI: Literal (statik) route'lar dynamic (:param) route'lardan ÖNCE gelir
// ─────────────────────────────────────────────────────────────────────────────

// Static top-level routes (ÖNCE)
router.get("/", auth, c.listMyPrivateFridges);
router.post("/", auth, validate(createPrivateFridgeSchema), c.createPrivateFridge);

// ✅ "my-public-fridges" literal route — /:fridgeId'den önce olmalı
router.get(
  "/my-public-fridges",
  auth,
  role(["PERSONAL", "CORPORATE"]),
  c.listMyPublicFridges
);

// ✅ "items/:itemId/transfer" literal prefix — /:fridgeId'den önce olmalı
router.put(
  "/items/:itemId/transfer",
  auth,
  role(["PERSONAL", "CORPORATE"]),
  c.transferItemToPublicFridge
);

// ─────────────────────────────────────────────────────────────────────────────
// Dynamic /:fridgeId routes (SONRA)
// ─────────────────────────────────────────────────────────────────────────────

router.put(
  "/:fridgeId",
  auth,
  validate(updatePrivateFridgeSchema),
  c.updatePrivateFridge
);

router.delete("/:fridgeId", auth, c.deletePrivateFridge);

router.get("/:fridgeId/items", auth, c.listItems);

router.post(
  "/:fridgeId/items",
  auth,
  role(["NEEDY", "PERSONAL", "CORPORATE"]),
  validate(createPrivateItemSchema),
  c.addPrivateItem
);

router.get("/:fridgeId/items-expiring", auth, c.listExpiringItemsInPrivateFridge);

router.put(
  "/:fridgeId/items/:itemId",
  auth,
  role(["NEEDY", "PERSONAL", "CORPORATE"]),
  validate(updatePrivateItemSchema),
  c.updatePrivateItem
);

router.delete(
  "/:fridgeId/items/:itemId",
  auth,
  role(["NEEDY", "PERSONAL", "CORPORATE"]),
  c.deletePrivateItem
);

module.exports = router;
