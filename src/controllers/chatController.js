// foodbridge-backend/src/controllers/chatController.js

const Chat = require('../models/Chat');
const Donation = require('../models/Donation'); // Yetki kontrolü için

/**
 * Belirli bir baðýþ (donation) için geçmiþ mesajlarý listeler.
 * Korumalý Rota: Sadece o baðýþýn Donör veya Alýcýsý eriþebilir.
 */
exports.getChatHistory = async (req, res) => {
    const { donationId } = req.params;
    const currentUserId = req.user.uid; // Middleware'den gelen UID

    try {
        // 1. Kullanýcýnýn bu baðýþta taraf olup olmadýðýný kontrol et
        const { data: donation, error: donationError } = await supabase
            .from('donations')
            .select('donor_user_id, recipient_user_id')
            .eq('donation_id', donationId)
            .single();

        if (donationError || !donation) {
            return res.status(404).send({ message: 'Baðýþ iþlemi bulunamadý.' });
        }

        // 2. Kullanýcýnýn donör veya alýcý olup olmadýðýný kontrol et
        if (donation.donor_user_id !== currentUserId && donation.recipient_user_id !== currentUserId) {
            return res.status(403).send({ message: 'Bu sohbet geçmiþini görmeye yetkiniz yok.' });
        }

        // 3. Mesajlarý veritabanýndan çek
        const messages = await Chat.getMessagesByDonationId(donationId);

        res.status(200).send({ messages });

    } catch (error) {
        console.error("Sohbet geçmiþi çekme hatasý:", error.message);
        res.status(500).send({ message: 'Sohbet geçmiþi listelenirken bir hata oluþtu.' });
    }
};

// ?? Gerçek zamanlý mesaj gönderme mantýðý Socket.io entegrasyonunda yer alacaktýr.