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

// ── Rate limiting ────────────────────────────────────────────────────────────
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 200,                  // max requests per window per IP
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many requests, please try again later." },
});
app.use("/api/", limiter);

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
