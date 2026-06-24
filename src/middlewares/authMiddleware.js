// src/middlewares/authMiddleware.js
const userRepository = require("../repositories/userRepository");
const ApiError = require("../utils/ApiError");
const admin = require("../config/firebase");
const logger = require("../utils/logger");

module.exports = async function authMiddleware(req, res, next) {
  try {
    const auth = req.headers.authorization;
    if (!auth?.startsWith("Bearer ")) throw new ApiError(401, "Unauthorized");

    const idToken = auth.substring("Bearer ".length);

    const decoded = await admin.auth().verifyIdToken(idToken);
    const firebaseUid = decoded.uid;

    // getUserByFirebaseUid is now synchronous (better-sqlite3)
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
