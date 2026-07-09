// src/sockets/socketHandler.js
const { Server } = require("socket.io");
const logger = require("../utils/logger");
const chatRepository = require("../repositories/chatRepository");
const userRepository = require("../repositories/userRepository");
const ApiError = require("../utils/ApiError");
const admin = require("../config/firebase");

// ─────────────────────────────────────────────────────────────────────────────
// Token cache — authMiddleware ile aynı mantık, socket authenticate için
// ─────────────────────────────────────────────────────────────────────────────
const socketTokenCache = new Map();
const TOKEN_TTL = 5 * 60 * 1000; // 5 dakika

function getCachedUid(token) {
  const entry = socketTokenCache.get(token);
  if (!entry) return null;
  if (Date.now() > entry.expiresAt) {
    socketTokenCache.delete(token);
    return null;
  }
  return entry.uid;
}

function setCachedUid(token, uid) {
  if (socketTokenCache.size >= 5000) {
    socketTokenCache.delete(socketTokenCache.keys().next().value);
  }
  socketTokenCache.set(token, { uid, expiresAt: Date.now() + TOKEN_TTL });
}

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
    // ✅ Performance: ping timeout ve interval optimize edildi
    pingTimeout: 30000,
    pingInterval: 25000,
    // ✅ Buffer boyutu sınırlandırıldı (büyük mesaj DoS koruması)
    maxHttpBufferSize: 1e5, // 100KB
  });

  io.on("connection", (socket) => {
    logger.info("Socket connected " + socket.id);
    socket.data.user = null;

    /**
     * 1️⃣ AUTHENTICATE
     * socket.emit("authenticate", { token })
     */
    socket.on("authenticate", async ({ token } = {}) => {
      try {
        if (!token) throw new ApiError(401, "Token required");

        // ✅ Cache hit → Firebase'e gitmez
        let firebaseUid = getCachedUid(token);
        if (!firebaseUid) {
          const decoded = await admin.auth().verifyIdToken(token);
          firebaseUid = decoded.uid;
          setCachedUid(token, firebaseUid);
        }

        const user = userRepository.getUserByFirebaseUid(firebaseUid);
        if (!user) throw new ApiError(401, "User not registered");

        socket.data.user = {
          id: user.id,
          firebaseUid: user.firebase_uid,
          role: user.role || "",
          fullName: user.full_name || "",
          email: user.email || "",
          username: user.username || "",
          avatarUrl: user.avatar_url || "",
          bio: user.bio || "",
        };

        socket.emit("authenticated", { ok: true });
        logger.info(`Socket authenticated: userId=${user.id}`);
      } catch (e) {
        logger.warn("Socket auth failed: " + (e.message || e));
        socket.emit("authenticated", { ok: false, message: e.message });
        socket.disconnect(true);
      }
    });

    /**
     * 2️⃣ JOIN ROOM
     * socket.emit("joinRoom", roomId)
     */
    socket.on("joinRoom", (roomIdRaw) => {
      try {
        if (!socket.data.user) throw new ApiError(401, "Not authenticated");

        const roomId = parseId(roomIdRaw, "roomId");
        const senderId = socket.data.user.id;

        const ok = chatRepository.isUserInRoom(roomId, senderId);
        if (!ok) throw new ApiError(403, "You are not allowed in this room");

        socket.join(String(roomId));

        // ✅ joinedRooms cache — send-message'da tekrar isUserInRoom sorgusu yapmamak için
        if (!socket.data.joinedRooms) socket.data.joinedRooms = new Set();
        socket.data.joinedRooms.add(roomId);

        socket.emit("joinedRoom", { roomId });
        logger.info(`User ${senderId} joined room ${roomId}`);
      } catch (e) {
        socket.emit("socketError", { message: e.message || "Join failed" });
      }
    });

    /**
     * 3️⃣ SEND MESSAGE
     * socket.emit("send-message", { roomId, message })
     */
    socket.on("send-message", ({ roomId: roomIdRaw, message } = {}) => {
      try {
        if (!socket.data.user) throw new ApiError(401, "Not authenticated");

        const roomId = parseId(roomIdRaw, "roomId");
        const senderId = socket.data.user.id;

        if (!message || typeof message !== "string" || message.trim().length === 0) {
          throw new ApiError(400, "Message is required");
        }
        if (message.length > 1000) throw new ApiError(400, "Message too long (max 1000 chars)");

        // ✅ joinedRooms cache varsa DB sorgusu yapmadan kontrol et
        const alreadyJoined = socket.data.joinedRooms?.has(roomId);
        if (!alreadyJoined) {
          const ok = chatRepository.isUserInRoom(roomId, senderId);
          if (!ok) throw new ApiError(403, "You are not allowed in this room");
        }

        const created = chatRepository.createMessage(roomId, senderId, message.trim());
        io.to(String(roomId)).emit("new-message", created);
      } catch (e) {
        socket.emit("socketError", { message: e.message || "Send failed" });
      }
    });

    socket.on("disconnect", () => {
      logger.info("Socket disconnected " + socket.id);
      // ✅ Cleanup — bellek sızıntısı önlenir
      socket.data.user = null;
      socket.data.joinedRooms = null;
    });
  });

  return io;
}

module.exports = initSocket;
