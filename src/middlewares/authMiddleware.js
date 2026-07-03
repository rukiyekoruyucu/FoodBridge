// src/middlewares/authMiddleware.js
const userRepository = require("../repositories/userRepository");
const ApiError = require("../utils/ApiError");
const admin = require("../config/firebase");
const logger = require("../utils/logger");

// ─────────────────────────────────────────────────────────────────────────────
// In-memory token cache — Firebase doğrulama sonuçlarını önbelleğe al
// Her istek Google'a gitmiyor; 5 dakika TTL (token süresi 1 saat — güvenli)
// ─────────────────────────────────────────────────────────────────────────────
const tokenCache = new Map(); // token → { uid, expiresAt }
const TOKEN_CACHE_TTL_MS = 5 * 60 * 1000; // 5 dakika
const MAX_CACHE_SIZE = 5000; // Max kullanıcı sayısı

function getCachedUid(token) {
  const entry = tokenCache.get(token);
  if (!entry) return null;
  if (Date.now() > entry.expiresAt) {
    tokenCache.delete(token);
    return null;
  }
  return entry.uid;
}

function setCachedUid(token, uid) {
  // Cache doluysa en eski girişi temizle
  if (tokenCache.size >= MAX_CACHE_SIZE) {
    const firstKey = tokenCache.keys().next().value;
    tokenCache.delete(firstKey);
  }
  tokenCache.set(token, { uid, expiresAt: Date.now() + TOKEN_CACHE_TTL_MS });
}

module.exports = async function authMiddleware(req, res, next) {
  try {
    const auth = req.headers.authorization;
    if (!auth?.startsWith("Bearer ")) throw new ApiError(401, "Unauthorized");

    const idToken = auth.substring("Bearer ".length);

    // ✅ Cache hit → Firebase network call yok (~0.1ms)
    let firebaseUid = getCachedUid(idToken);

    if (!firebaseUid) {
      // Cache miss → Firebase doğrulama (~1-5ms, public key cached by SDK)
      const decoded = await admin.auth().verifyIdToken(idToken);
      firebaseUid = decoded.uid;
      setCachedUid(idToken, firebaseUid);
    }

    // getUserByFirebaseUid is synchronous (better-sqlite3) — indexed by UNIQUE
    const user = userRepository.getUserByFirebaseUid(firebaseUid);
    if (!user) throw new ApiError(401, "User not registered");

    req.user = {
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

    next();
  } catch (err) {
    logger.error("Token verification failed: " + (err.message || err));
    next(err instanceof ApiError ? err : new ApiError(401, "Unauthorized"));
  }
};
