const logger = require("../utils/logger");

const sentNotifications = new Set();

async function sendExpiryNotification(userId, item, daysLeft) {
  const key = `expnotify:${item.id}:${daysLeft}`;

  if (sentNotifications.has(key)) return;

  logger.info(
    `Notify user ${userId} about expiring item ${item.id} (${item.name}) daysLeft=${daysLeft}`
  );

  sentNotifications.add(key);
}

module.exports = { sendExpiryNotification };
