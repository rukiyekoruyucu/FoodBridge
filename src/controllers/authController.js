const authService = require("../services/authService");
const ApiError = require("../utils/ApiError");

async function register(req, res, next) {
  try {
    const { firebaseUid, role, fullName, email, username, companyName, location } = req.body;

    const user = await authService.registerUser({
      firebaseUid,
      role,
      fullName,
      email,
      username,
      companyName,
      location,
    });

    res.status(201).json(user);
  } catch (err) {
    next(err);
  }
}

async function me(req, res, next) {
  try {
    const firebaseUid = req.user.firebaseUid || req.user.firebase_uid || req.user.uid;
    const user = await authService.getMeByFirebaseUid(firebaseUid);
    res.json(user);
  } catch (err) {
    next(err);
  }
}

module.exports = {
  register,
  me,
};