const express = require("express");
const router = express.Router();
const fridgeController = require("../controllers/fridgeController");
const authMiddleware = require("../middlewares/authMiddleware");
const roleMiddleware = require("../middlewares/roleMiddleware");
const Joi = require("joi");
const validate = require("../middlewares/validationMiddleware");

const createFridgeSchema = Joi.object({
  name: Joi.string().min(2).required(),
  description: Joi.string().allow("", null),
  latitude: Joi.number().required(),
  longitude: Joi.number().required(),
  address: Joi.string().allow("", null),
  isPublic: Joi.boolean().optional()
});

router.post(
  "/",
  authMiddleware,
  roleMiddleware(["PERSONAL", "CORPORATE"]),
  validate(createFridgeSchema),
  fridgeController.createFridge
);

router.get("/:id", authMiddleware, fridgeController.getFridge);

module.exports = router;
