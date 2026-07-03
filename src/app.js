// src/app.js
const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");
const { notFoundHandler, errorHandler } = require("./middlewares/errorMiddleware");
const logger = require("./utils/logger");
const { scheduleExpiryJob } = require("./jobs/expiryJob");
const { runMigrations } = require("./config/migrate");
const db = require("./config/db");

// routes
const authRoutes = require("./routes/authRoutes");
const userRoutes = require("./routes/userRoutes");
const fridgeRoutes = require("./routes/fridgeRoutes");
const itemRoutes = require("./routes/itemRoutes");
const donationRoutes = require("./routes/donationRoutes");
const itemFeedRoutes = require("./routes/itemFeedRoutes");
const privateFridgeRoutes = require("./routes/privateFridgeRoutes");

// extra
const followRoutes = require("./routes/followRoutes");
const chatRoutes = require("./routes/chatRoutes");
const uploadRoutes = require("./routes/uploadRoutes");

// ── Run migrations synchronously at startup ─────────────────────────────────
runMigrations();

const app = express();

// ── Security & parsing middleware ────────────────────────────────────────────
app.use(helmet());
app.use(cors({
  origin: process.env.CORS_ORIGIN || "*",
}));
app.use(express.json({ limit: "10mb" }));

// ── Rate Limiting — Route Bazlı (1000+ kullanıcı için optimize) ─────────────

// Auth: Brute force koruması — 15 dakikada max 20 deneme
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many login attempts, please try again later." },
});

// Upload: Cloudinary yükleme — dakikada max 15
const uploadLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 15,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many uploads, please wait a moment." },
});

// Chat REST: Mesaj endpoint — dakikada max 60 (1 mesaj/sn)
const chatLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 60,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many messages, please slow down." },
});

// Genel API: 15 dakikada 300 istek (eski 200'den artırıldı — meşru kullanım)
const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 300,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many requests, please try again later." },
});

// ── Limiters — spesifik route'lar önce gelir ─────────────────────────────────
app.use("/api/auth", authLimiter);
app.use("/api/uploads", uploadLimiter);
app.use("/api/chat", chatLimiter);
app.use("/api/", generalLimiter);  // geri kalan her şey

// ── Health endpoints ─────────────────────────────────────────────────────────
app.get("/health", (req, res) => res.json({ status: "ok" }));

app.get("/health/db", (req, res) => {
  try {
    const row = db.prepare("SELECT datetime('now') AS now").get();
    res.json({ status: "ok", dbTime: row.now });
  } catch (err) {
    res.status(500).json({ status: "db-error", message: err.message });
  }
});

// ── API Routes ───────────────────────────────────────────────────────────────
app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/fridges", fridgeRoutes);
app.use("/api/items", itemRoutes);
app.use("/api/donations", donationRoutes);
app.use("/api/items", itemFeedRoutes);
app.use("/api/private-fridges", privateFridgeRoutes);

app.use("/api/follows", followRoutes);
app.use("/api/chat", chatRoutes);
app.use("/api/uploads", uploadRoutes);

// ── Error handlers ───────────────────────────────────────────────────────────
app.use(notFoundHandler);
app.use(errorHandler);

// ── Background jobs ──────────────────────────────────────────────────────────
scheduleExpiryJob();

module.exports = app;
