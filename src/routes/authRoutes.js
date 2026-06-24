const express = require("express");
const router = express.Router();
const authController = require("../controllers/authController");
const authMiddleware = require("../middlewares/authMiddleware");
const Joi = require("joi");
const validate = require("../middlewares/validationMiddleware");

const registerSchema = Joi.object({
  firebaseUid: Joi.string().required(),        // profesyonel: zorunlu
  fullName: Joi.string().min(2).required(),
  email: Joi.string().email().required(),
  username: Joi.string().alphanum().min(3).max(20).required(),
  role: Joi.string().valid("NEEDY", "PERSONAL", "CORPORATE").required(),

  // şimdilik opsiyonel kalsın; corporate seçilince dolacak
  companyName: Joi.string().allow("", null).optional(),
  location: Joi.string().allow("", null).optional(),
});

router.post("/register", validate(registerSchema), authController.register);
router.get("/me", authMiddleware, authController.me);

module.exports = router;
