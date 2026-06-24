const express = require("express");
const router = express.Router();
const auth = require("../middlewares/authMiddleware");
const chatController = require("../controllers/chatController");

router.get("/rooms", auth, chatController.listRooms);
router.post("/dm/:userId", auth, chatController.openDm);

router.get("/rooms/:roomId/messages", auth, chatController.getMessages);
router.post("/rooms/:roomId/messages", auth, chatController.sendMessage);

module.exports = router;
