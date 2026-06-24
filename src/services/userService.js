const userRepository = require("../repositories/userRepository");
const donationRepository = require("../repositories/donationRepository");
const ApiError = require("../utils/ApiError");

async function getUserSummary(userId) {
  const user = await userRepository.getById(userId);
  const donations = await donationRepository.listUserDonations(userId);
  return {
    user,
    stats: {
      donationsCount: donations.filter((d) => d.type === "DONATION" && d.donor_id === userId).length,
      tradesCount: donations.filter((d) => d.type === "TRADE").length
    }
  };
}
async function getTopDonors({ limit = 10 }) {
  return userRepository.listTopDonors(limit);
}
async function updateMe(userId, { fullName, username, avatarUrl, bio }) {
  const patch = {
    fullName,
    username,
    avatarUrl,
    bio,
  };

  const updated = await userRepository.updateUserById(userId, patch);
  if (!updated) throw new ApiError(404, "User not found");
  return updated;
}
module.exports = {
  getUserSummary, getTopDonors , updateMe
};
