const express = require("express");
const router = express.Router();
const authMiddleware = require("../middlewares/authMiddleware");
const userController = require("../controllers/userController");

router.get("/me/summary", authMiddleware, userController.getSummary);
router.get("/leaderboard", userController.getTopDonors); // ✅ Public — auth gerekmez
router.patch("/me", authMiddleware, userController.updateMe);
router.get("/:id/public", userController.getPublicUser);

module.exports = router;
