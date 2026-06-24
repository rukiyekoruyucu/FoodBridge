const express = require("express");
const router = express.Router();
const auth = require("../middlewares/authMiddleware");
const followController = require("../controllers/followController");

router.post("/:userId", auth, followController.request);
router.post("/:userId/accept", auth, followController.accept);
router.get("/requests/incoming", auth, followController.incoming);

module.exports = router;
