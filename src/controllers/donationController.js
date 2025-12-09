// foodbridge-backend/src/controllers/donationController.js

const Donation = require('../models/Donation');
const { ROLES } = require('../models/User');

// --- Alıcı (Recipient) İşlevleri ---

/**
 * Bir ihtiyaç sahibi tarafından ürün talep edilir.
 * Korumalı rota: Sadece 'needy' ve 'personal' (Recipient) rolleri erişebilir.
 */
exports.requestItem = async (req, res) => {
    const { itemId } = req.body;
    const recipientUserId = req.user.uid; // Middleware'den gelen UID
    const userRole = req.user.role;

    // Sadece alıcı rolüne sahip olanlar talep edebilir (Recipient ve Personal rolünü dahil ediyoruz)
    if (![ROLES.NEEDY, ROLES.PERSONAL].includes(userRole)) {
        return res.status(403).send({ message: 'Bu işlem için yetkiniz yok. Sadece alıcılar talep oluşturabilir.' });
    }

    if (!itemId) {
        return res.status(400).send({ message: 'Talep edilecek ürün ID\'si gereklidir.' });
    }

    try {
        const newDonation = await Donation.createDonationRequest(itemId, recipientUserId);
        res.status(201).send({
            message: 'Bağış talebi başarıyla oluşturuldu.',
            donation: newDonation
        });
    } catch (error) {
        console.error("Talep oluşturma hatası:", error.message);
        res.status(500).send({ message: error.message });
    }
};

/**
 * Alıcı işlemi tamamlandığını onaylar (Ürünü teslim aldı).
 * Korumalı rota: Sadece 'needy' ve 'personal' (Recipient) rolleri erişebilir.
 */
exports.confirmPickup = async (req, res) => {
    const { donationId } = req.params;
    const recipientUserId = req.user.uid;

    try {
        const completedDonation = await Donation.completeDonation(donationId, recipientUserId);

        res.status(200).send({
            message: 'Bağış başarıyla tamamlandı. Bağışçı puan kazandı.',
            donation: completedDonation
        });
    } catch (error) {
        console.error("Teslim alma onayı hatası:", error.message);
        res.status(403).send({ message: error.message });
    }
};

// --- Bağışçı (Donor) İşlevleri ---

/**
 * Bağışçı bir talebe yanıt verir (Kabul/Red).
 * Korumalı rota: Sadece 'personal' ve 'company' (Donor) rolleri erişebilir.
 */
exports.respondToRequest = async (req, res) => {
    const { donationId } = req.params;
    const { status } = req.body; // 'accepted' veya 'rejected' olmalı
    const donorUserId = req.user.uid;

    if (!status) {
        return res.status(400).send({ message: 'Talep durumu (accepted/rejected) gereklidir.' });
    }

    try {
        const updatedDonation = await Donation.respondToRequest(donationId, donorUserId, status);

        res.status(200).send({
            message: `Talep başarıyla ${status} olarak güncellendi.`,
            donation: updatedDonation
        });
    } catch (error) {
        console.error("Talep yanıtı hatası:", error.message);
        res.status(403).send({ message: error.message });
    }
};

// 💡 Ek olarak: Bağışçının kendi yaptığı bağışları listeleme endpoint'i buraya eklenebilir.