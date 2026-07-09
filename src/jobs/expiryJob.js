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

// ✅ Aynı item için birden fazla bildirim gönderme — in-memory set
// Railway restart'ta sıfırlanır (kabul edilebilir — günlük job)
const _notifiedToday = new Set();

function _getTodayKey(itemId, threshold) {
  const d = new Date();
  return `${itemId}-${threshold}-${d.getFullYear()}${d.getMonth()}${d.getDate()}`;
}

async function runExpiryCheck() {
  const thresholds = [7, 3, 1];

  try {
    for (const d of thresholds) {
      const items = itemRepository.findExpiringItems(d);

      for (const item of items) {
        const expiry = item.expiry_date || item.expiryDate;
        if (!expiry) continue;

        const daysLeft = _daysLeft(expiry);

        // Bildir: 7/3/1 gün kaldığında — aynı gün tekrarlama
        if (thresholds.includes(daysLeft)) {
          const userId = item.donor_user_id || item.user_id || item.owner_user_id;
          if (userId) {
            const key = _getTodayKey(item.id, daysLeft);
            if (!_notifiedToday.has(key)) {
              await notificationService.sendExpiryNotification(userId, item, daysLeft);
              _notifiedToday.add(key);
            }
          }
        }

        // Süresi geçtiyse expired yap
        if (daysLeft < 0) {
          itemService.markItemExpired(item.id);
        }
      }
    }

    logger.info(`Expiry job OK (thresholds=${thresholds.join(",")})`);
  } catch (err) {
    logger.error("Expiry job failed", err);
  }
}

// ✅ Bellek sızıntısı önlemi: Her gün gece yarısı _notifiedToday temizlenir
let _scheduledTask = null;

function scheduleExpiryJob() {
  // Gece yarısı: bildirim setini temizle
  cron.schedule("0 0 * * *", () => {
    const prevSize = _notifiedToday.size;
    _notifiedToday.clear();
    logger.info(`Expiry job: cleared ${prevSize} notification keys`);
  });

  // Her gece saat 02:00'de çalıştır
  _scheduledTask = cron.schedule("0 2 * * *", () => {
    runExpiryCheck().catch((e) => logger.error("Expiry cron error", e));
  });

  // Uygulama ilk açıldığında bir kere çalıştır (non-blocking)
  setImmediate(() => {
    runExpiryCheck().catch((e) => logger.error("Expiry startup error", e));
  });
}

// ✅ Graceful shutdown desteği — node-cron task'ı düzgün durdur
function stopExpiryJob() {
  if (_scheduledTask) {
    _scheduledTask.stop();
    _scheduledTask = null;
  }
}

module.exports = { scheduleExpiryJob, stopExpiryJob, runExpiryCheck };
