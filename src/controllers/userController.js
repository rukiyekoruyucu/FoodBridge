const userService = require("../services/userService");
const userRepository = require("../repositories/userRepository");

async function getSummary(req, res, next) {
  try {
    const summary = await userService.getUserSummary(req.user.id);
    res.json(summary);
  } catch (err) {
    next(err);
  }
}
async function getTopDonors(req, res, next) {
  try {
    const limit = Math.min(Math.max(parseInt(req.query.limit || "10", 10), 1), 50);
    const rows = await userService.getTopDonors({ limit });
    res.json(rows);
  } catch (e) {
    next(e);
  }
}
async function updateMe(req, res, next) {
  try {
    const updated = await userService.updateMe(req.user.id, req.body);
    res.json(updated);
  } catch (e) {
    next(e);
  }
}
async function getPublicUser(req, res, next) {
  try {
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) {
      return res.status(400).json({ message: "Invalid user id" });
    }

    const u = await userRepository.getUserById(id); // ✅ DÜZELT
    if (!u) return res.status(404).json({ message: "User not found" });

    const displayName =
      (u.full_name && String(u.full_name).trim()) ||
      (u.username && String(u.username).trim()) ||
      `Kullanıcı #${u.id}`;

    // ✅ Frontend uyumu: { user: {...} }
    return res.json({
      user: {
        id: u.id,
        username: u.username || null,
        full_name: u.full_name || null,
        avatar_url: u.avatar_url || null,
        bio: u.bio || null,
        displayName, // opsiyonel
        avatarUrl: u.avatar_url || null, // opsiyonel
      },
    });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getSummary, getTopDonors , updateMe, getPublicUser
};
