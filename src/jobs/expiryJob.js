// src/jobs/expiryJob.js
const cron = require("node-cron");
const itemRepository = require("../repositories/itemRepository");
const notificationService = require("../services/notificationService");
const itemService = require("../services/itemService");
const logger = require("../utils/logger");

function _daysLeft(expiryDate) {
  const now = new Date();
  const start = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const exp = new Date(expiryDate);
  const expDay = new Date(exp.getFullYear(), exp.getMonth(), exp.getDate());
  const diff = expDay.getTime() - start.getTime();
  return Math.ceil(diff / (1000 * 60 * 60 * 24));
}

async function runExpiryCheck() {
  const thresholds = [7, 3, 1];

  try {
    for (const d of thresholds) {
      // findExpiringItems is now synchronous
      const items = itemRepository.findExpiringItems(d);

      for (const item of items) {
        const expiry = item.expiry_date || item.expiryDate;
        if (!expiry) continue;

        const daysLeft = _daysLeft(expiry);

        // Bildir: 7/3/1 gün kaldığında
        if (thresholds.includes(daysLeft)) {
          const userId = item.donor_user_id || item.user_id || item.owner_user_id;
          if (userId) {
            await notificationService.sendExpiryNotification(userId, item, daysLeft);
          }
        }

        // Süresi geçtiyse expired yap
        if (daysLeft < 0) {
          await itemService.markItemExpired(item.id);
        }
      }
    }

    logger.info(`Expiry job OK (thresholds=${thresholds.join(",")})`);
  } catch (err) {
    logger.error("Expiry job failed", err);
  }
}

function scheduleExpiryJob() {
  // Her gece saat 02:00'de çalıştır
  cron.schedule("0 2 * * *", () => {
    runExpiryCheck().catch(() => {});
  });

  // Uygulama ilk açıldığında bir kere çalıştır
  runExpiryCheck().catch(() => {});
}

module.exports = { scheduleExpiryJob, runExpiryCheck };
