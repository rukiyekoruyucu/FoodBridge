// foodbridge-backend/server.js (SOCKET.IO İLE GÜNCELLENMİŞ TAM İÇERİK)

const express = require('express');
const http = require('http'); // HTTP server modülünü ekle
const { Server } = require('socket.io'); // Socket.io Server modülünü ekle

require('dotenv').config();
const app = express();
const server = http.createServer(app); // Express uygulamasını HTTP sunucusuna bağla
const PORT = process.env.PORT || 3000;

// Socket.io Sunucusunu başlatma (CORS ayarları ile)
const io = new Server(server, {
    cors: {
        origin: "*", // Geliştirme aşamasında her yerden izin ver
        methods: ["GET", "POST"]
    }
});

// --- GÜVENLİK VE YAPILANDIRMA YÜKLEMELERİ ---
const helmet = require('helmet');
app.use(helmet());
app.use(express.json());

// Yapılandırma dosyalarını çağırıyoruz
const db = require('./src/config/db');
console.log(`[FIREBASE KONTROL] Project ID: ${process.env.FIREBASE_PROJECT_ID}`);
const admin = require('./src/config/firebase');

// Rota Tanımları (Buraya chatRoutes.js'i de ekliyoruz)
const authRoutes = require('./src/routes/authRoutes');
const fridgeRoutes = require('./src/routes/fridgeRoutes');
const donationRoutes = require('./src/routes/donationRoutes');
const privateFridgeRoutes = require('./src/routes/privateFridgeRoutes');
const chatRoutes = require('./src/routes/chatRoutes'); 
const adminRoutes = require('./src/routes/adminRoutes');

// Rota Kullanımı
app.use('/api/auth', authRoutes);
app.use('/api/fridges', fridgeRoutes);
app.use('/api/donations', donationRoutes);
app.use('/api/private-fridge', privateFridgeRoutes);
app.use('/api/chat', chatRoutes); 
app.use('/api/admin', adminRoutes);

// --- SOCKET.IO/CHAT İŞLEMLERİ ---
const { handleChatConnection } = require('./src/utils/socketHandler'); // Chat mantığı buraya taşınacak
io.on('connection', (socket) => handleChatConnection(socket, io));

// Temel durum kontrolü 
app.get('/', (req, res) => {
    res.status(200).send({
        message: '✅ FoodBridge API Sunucusu Çalışıyor!',
        status: 'Operational',
    });
});

// --- Sunucuyu Başlatma (app.listen yerine server.listen kullanıyoruz) ---
server.listen(PORT, () => {
    console.log(`✅ FoodBridge Backend http://localhost:${PORT} adresinde çalışıyor.`);
    console.log(`🌐 WebSocket/Socket.io hazır.`);
});

// ... (Gelişmiş Hata İşleme Middleware'i aynı kalır) ...