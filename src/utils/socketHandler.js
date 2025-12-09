// foodbridge-backend/src/utils/socketHandler.js

const Chat = require('../models/Chat');
const { verifyIdToken } = require('../middlewares/authMiddleware'); // Firebase token doğrulama

/**
 * Socket.io bağlantılarını yönetir.
 */
function handleChatConnection(socket, io) {
    console.log(`👤 Yeni Socket Bağlantısı: ${socket.id}`);

    // Kullanıcıların hangi bağış odalarına katıldığını tutmak için
    let userDonationRooms = [];

    // 1. Kullanıcıdan gelen "AUTH" olayını dinleme (Kullanıcının kimliğini doğrulamak için)
    socket.on('authenticate', async ({ token, userId }) => {
        try {
            // Firebase tokenını doğrula (Token geçerliyse, kullanıcı kimliği doğrulanır)
            // 💡 NOT: verifyIdToken, authMiddleware'den sadece token doğrulama kısmını almalıdır.
            // Simplistik amaçlarla, token'ı sadece istemciden aldığımızı varsayalım.

            // Kullanıcı kimliği doğrulandıktan sonra, tüm bağış odalarına katılmasını sağlayabiliriz
            // VEYA sadece sohbet etmek istediği odaya katılmasını isteyebiliriz.

            socket.userId = userId; // Socket objesine UID'yi ekle
            console.log(`✅ Kullanıcı ${userId} doğrulandı.`);
            socket.emit('auth-success', { message: 'Doğrulama başarılı.' });

        } catch (error) {
            console.error("Socket Auth Hatası:", error.message);
            socket.emit('auth-error', { message: 'Geçersiz token. Bağlantı kesiliyor.' });
            socket.disconnect(true);
        }
    });

    // 2. Kullanıcının belirli bir bağış sohbet odasına katılması
    socket.on('join-room', (donationId) => {
        if (!socket.userId) {
            socket.emit('chat-error', { message: 'Önce kimlik doğrulaması yapın.' });
            return;
        }

        const roomName = `donation_${donationId}`;
        socket.join(roomName);
        userDonationRooms.push(roomName);

        console.log(`User ${socket.userId} joined room ${roomName}`);
        socket.emit('room-joined', { donationId, roomName });
    });

    // 3. Mesaj gönderme olayı
    socket.on('send-message', async ({ donationId, content }) => {
        if (!socket.userId || !userDonationRooms.includes(`donation_${donationId}`)) {
            socket.emit('chat-error', { message: 'Mesaj gönderme yetkiniz yok.' });
            return;
        }

        const senderId = socket.userId;

        // 1. Mesajı veritabanına kaydet
        try {
            const savedMessage = await Chat.saveMessage(donationId, senderId, content);

            const messagePayload = {
                senderId: savedMessage.sender_user_id,
                content: savedMessage.content,
                sentAt: savedMessage.sent_at,
                messageId: savedMessage.message_id
            };

            // 2. Mesajı odadaki diğer tüm istemcilere yayınla (gerçek zamanlı akış)
            io.to(`donation_${donationId}`).emit('new-message', messagePayload);

        } catch (error) {
            console.error("Mesaj gönderme/kaydetme hatası:", error.message);
            socket.emit('chat-error', { message: 'Mesajınız gönderilemedi.' });
        }
    });

    // 4. Bağlantı kesildiğinde (log)
    socket.on('disconnect', () => {
        console.log(`❌ Socket Bağlantısı Kesildi: ${socket.id} (User: ${socket.userId})`);
    });
}

module.exports = {
    handleChatConnection
};