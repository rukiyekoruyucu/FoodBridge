// src/services/kindnessService.js
const userRepository = require("../repositories/userRepository");

// awardKindnessPoints is synchronous (better-sqlite3)
function awardKindnessPoints(userId, points) {
  if (!points || points <= 0) return;
  userRepository.incrementKindnessPoints(userId, points);
}

module.exports = { awardKindnessPoints };
