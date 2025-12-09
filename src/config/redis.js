// foodbridge-backend/src/config/redis.js

const { createClient } = require('redis');

// Ortam değişkeninden URL'yi çeker
const redisUrl = process.env.REDIS_URL;

// Redis istemcisini oluştur
const client = createClient({
    url: redisUrl,
    // Bağlantı zaman aşımı süresini artırarak yavaş ağlara karşı tolerans sağlayabiliriz:
    socket: {
        connectTimeout: 5000 // 5 saniye bekleme süresi
    }
});

// Bağlantı denemesi
client.connect()
    .then(() => {
        console.log("✅ Redis bağlantısı başarılı.");
    })
    .catch((err) => {
        // Hata durumunda loglama yap ve uygulamayı durdurma
        console.error("❌ Redis bağlantısı başarısız. Uygulama Redis kullanmadan devam edecek:", err.message);
    });

// 💡 Kritik: Hata olaylarını yakalama (Event Listener)
client.on('error', (err) => {
    console.error('Redis Client Error:', err.message);
});


// İstemciyi dışa aktararak diğer modüllerde kullanıma aç
module.exports = client;