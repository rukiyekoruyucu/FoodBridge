const logger = require("../utils/logger");
const { client: redis } = require("../config/redis"); // ✅ doğru

async function sendExpiryNotification(userId, item, daysLeft) {
  const key = `expnotify:${item.id}:${daysLeft}`;

  const already = await redis.get(key);
  if (already) return;

  logger.info(
    `Notify user ${userId} about expiring item ${item.id} (${item.name}) daysLeft=${daysLeft}`
  );

  await redis.set(key, "1", { EX: 60 * 60 * 24 * 30 }); // ✅ redis v4 doğru kullanım
}

module.exports = { sendExpiryNotification };
