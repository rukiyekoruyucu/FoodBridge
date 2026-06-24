// src/sockets/socketHandler.js
const { Server } = require("socket.io");
const logger = require("../utils/logger");
const chatRepository = require("../repositories/chatRepository");
const userRepository = require("../repositories/userRepository");
const ApiError = require("../utils/ApiError");
const admin = require("../config/firebase");

function parseId(raw, name) {
  const n = parseInt(raw, 10);
  if (!Number.isInteger(n) || n <= 0) {
    throw new ApiError(400, `Invalid ${name}`);
  }
  return n;
}

function initSocket(server) {
  const io = new Server(server, {
    cors: { origin: process.env.CORS_ORIGIN || "*" },
  });

  io.on("connection", (socket) => {
    logger.info("Socket connected " + socket.id);

    // socket context
    socket.data.user = null;

    /**
     * 1️⃣ AUTHENTICATE
     * Frontend:
     * socket.emit("authenticate", { token })
     */
    socket.on("authenticate", async ({ token }) => {
      try {
        if (!token) throw new ApiError(401, "Token required");

        const decoded = await admin.auth().verifyIdToken(token);
        const firebaseUid = decoded.uid;

        // getUserByFirebaseUid is synchronous (better-sqlite3)
        const user = userRepository.getUserByFirebaseUid(firebaseUid);
        if (!user) throw new ApiError(401, "User not registered");

        socket.data.user = {
          id: user.id,
          firebaseUid: user.firebase_uid,
          role: user.role || "",
          fullName: user.full_name || "",
          email: user.email || "",
          username: user.username || "",
          phone: user.phone || "",
          avatarUrl: user.avatar_url || "",
          bio: user.bio || "",
        };

        socket.emit("authenticated", { ok: true });
        logger.info(`Socket authenticated: userId=${user.id}`);
      } catch (e) {
        logger.warn("Socket auth failed: " + (e.message || e));
        socket.emit("authenticated", { ok: false });
        socket.disconnect(true);
      }
    });

    /**
     * 2️⃣ JOIN ROOM
     * Frontend:
     * socket.emit("joinRoom", roomId)
     */
    socket.on("joinRoom", (roomIdRaw) => {
      try {
        if (!socket.data.user) throw new ApiError(401, "Not authenticated");

        const roomId = parseId(roomIdRaw, "roomId");
        const senderId = socket.data.user.id;

        // isUserInRoom is synchronous (better-sqlite3)
        const ok = chatRepository.isUserInRoom(roomId, senderId);
        if (!ok) throw new ApiError(403, "You are not allowed in this room");

        socket.join(String(roomId));
        socket.emit("joinedRoom", { roomId });

        logger.info(`User ${senderId} joined room ${roomId}`);
      } catch (e) {
        socket.emit("socketError", { message: e.message || "Join failed" });
      }
    });

    /**
     * 3️⃣ SEND MESSAGE (DB + broadcast)
     * Frontend:
     * socket.emit("send-message", { roomId, message })
     */
    socket.on("send-message", ({ roomId: roomIdRaw, message }) => {
      try {
        if (!socket.data.user) throw new ApiError(401, "Not authenticated");

        const roomId = parseId(roomIdRaw, "roomId");
        const senderId = socket.data.user.id;

        if (!message || typeof message !== "string" || message.trim().length === 0) {
          throw new ApiError(400, "Message is required");
        }
        if (message.length > 1000) throw new ApiError(400, "Message too long");

        // Both synchronous now
        const ok = chatRepository.isUserInRoom(roomId, senderId);
        if (!ok) throw new ApiError(403, "You are not allowed in this room");

        const created = chatRepository.createMessage(roomId, senderId, message.trim());

        // sender dahil HERKESE gider
        io.to(String(roomId)).emit("new-message", created);
      } catch (e) {
        socket.emit("socketError", { message: e.message || "Send failed" });
      }
    });

    socket.on("disconnect", () => {
      logger.info("Socket disconnected " + socket.id);
    });
  });

  return io;
}

module.exports = initSocket;
