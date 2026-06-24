const express = require("express");
const multer = require("multer");
const { uploadImage } = require("../controllers/uploadController");
const auth = require("../middlewares/authMiddleware");

const router = express.Router();

// Memory storage: DB’ye değil Cloudinary’ye gidecek
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 } // 10MB
});

router.post("/image", auth, upload.single("image"), uploadImage);

module.exports = router;
