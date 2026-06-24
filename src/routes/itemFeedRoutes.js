const express = require("express");
const router = express.Router();
const auth = require("../middlewares/authMiddleware");
const itemController = require("../controllers/itemController");

router.get("/feed", auth, itemController.getFeed);

module.exports = router;
