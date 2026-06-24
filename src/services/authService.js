// src/services/authService.js
const userRepository = require("../repositories/userRepository");
const ApiError = require("../utils/ApiError");

const ALLOWED_ROLES = ["NEEDY", "PERSONAL", "CORPORATE"];

function registerUser({ firebaseUid, role, fullName, email, username }) {
  if (!ALLOWED_ROLES.includes(role)) {
    throw new ApiError(400, "Invalid role");
  }

  if (userRepository.getUserByUsername(username)) {
    throw new ApiError(400, "Username already taken");
  }

  const existingByUid = userRepository.getUserByFirebaseUid(firebaseUid);
  if (existingByUid) {
    throw new ApiError(400, "User already registered");
  }

  if (email) {
    const existingByEmail = userRepository.getUserByEmail(email);
    if (existingByEmail) {
      throw new ApiError(400, "Email already registered");
    }
  }

  const user = userRepository.createUser({
    firebaseUid,
    role,
    fullName,
    username,
    email
  });

  return user;
}

function getMe(userId) {
  const user = userRepository.getUserById(userId);
  if (!user) throw new ApiError(404, "User not found");
  return user;
}

function getMeByFirebaseUid(firebaseUid) {
  const user = userRepository.getUserByFirebaseUid(firebaseUid);
  if (!user) throw new ApiError(404, "User not found");
  return user;
}

module.exports = {
  registerUser,
  getMeByFirebaseUid,
  getMe
};
