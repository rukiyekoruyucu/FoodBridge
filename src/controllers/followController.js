const followRepository = require("../repositories/followRepository");
const ApiError = require("../utils/ApiError");

async function request(req, res, next) {
  try {
    const followerId = req.user.id;
    const followeeId = parseInt(req.params.userId, 10);
    if (followeeId === followerId) throw new ApiError(400, "Cannot follow yourself");

    const row = await followRepository.requestFollow(followerId, followeeId);
    res.status(201).json(row);
  } catch (e) {
    next(e);
  }
}

async function accept(req, res, next) {
  try {
    const followeeId = req.user.id;
    const followerId = parseInt(req.params.userId, 10);

    const row = await followRepository.acceptFollow(followeeId, followerId);
    if (!row) throw new ApiError(404, "Follow request not found");

    res.json(row);
  } catch (e) {
    next(e);
  }
}

async function incoming(req, res, next) {
  try {
    const rows = await followRepository.listIncomingRequests(req.user.id);
    res.json(rows);
  } catch (e) {
    next(e);
  }
}

module.exports = { request, accept, incoming };
