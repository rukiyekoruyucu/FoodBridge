const chatRepository = require("../repositories/chatRepository");
const ApiError = require("../utils/ApiError");
const userRepository = require("../repositories/userRepository");

async function openDm(req, res, next) {
  try {
    const me = req.user.id;
    // ✅ Tüm authenticated kullanıcılar DM açabilir (NEEDY, PERSONAL, CORPORATE)
    const other = Number(req.params.userId);
    if (!other || other <= 0) throw new ApiError(400, "userId required");
    if (other === me) throw new ApiError(400, "Cannot DM yourself");

    const room = await chatRepository.getOrCreateDmRoom(me, other);

    // ✅ minimum response (Flutter bunu zaten parse ediyor)
    return res.json({
      id: room.id,
      room_type: "DM",
      other_user_id: other,
    });
  } catch (err) {
    next(err);
  }
}

async function listRooms(req, res, next) {
  try {
    const meId = req.user.id;
    const rooms = await chatRepository.listUserRooms(meId, 50);

    res.json(
      rooms.map((r) => ({
        id: r.id,
        room_type: r.room_type,
        donation_id: r.donation_id,
        other_user_id: r.other_user_id,
        other_user_full_name: r.other_full_name,
        other_user_avatar_url: r.other_avatar_url,
        last_message: r.last_message,
        last_message_at: r.last_message_at,
      }))
    );
  } catch (err) {
    next(err);
  }
}

async function getMessages(req, res, next) {
  try {
    const meId = req.user.id;
    const roomId = Number(req.params.roomId);
    if (!roomId || roomId <= 0) throw new ApiError(400, "Invalid roomId");

    const ok = await chatRepository.isUserInRoom(roomId, meId);
    if (!ok) throw new ApiError(403, "Forbidden");

    const limit = Number(req.query.limit) || 50;
    const before = req.query.before ? new Date(req.query.before) : null;

    const rows = await chatRepository.listMessages(roomId, limit, before);
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function sendMessage(req, res, next) {
  try {
    const meId = req.user.id;
    const roomId = Number(req.params.roomId);
    if (!roomId || roomId <= 0) throw new ApiError(400, "Invalid roomId");

    const ok = await chatRepository.isUserInRoom(roomId, meId);
    if (!ok) throw new ApiError(403, "Forbidden");

    // Flutter bazen "message", bazen "text" gönderebiliyor: ikisini de kabul et
    const raw = (req.body.message ?? req.body.text ?? "").toString().trim();
    if (!raw) throw new ApiError(400, "message required");

    const msg = await chatRepository.insertMessage(roomId, meId, raw);
    res.json(msg);
  } catch (err) {
    next(err);
  }
}

module.exports = { openDm, listRooms, getMessages, sendMessage };
