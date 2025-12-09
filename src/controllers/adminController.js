// foodbridge-backend/src/controllers/adminController.js

const Admin = require('../models/Admin');

/**
 * Kullanıcı rolünü günceller (Admin Paneli İşlevi).
 * Rol değişimi, Kurumsal onayı veya Banlama için kullanılır.
 */
exports.updateUserRole = async (req, res) => {
    const { userId } = req.params;
    const { newRole } = req.body;

    if (!newRole) {
        return res.status(400).send({ message: 'Yeni rol gereklidir.' });
    }

    try {
        const updatedUser = await Admin.updateUserRole(userId, newRole);
        res.status(200).send({
            message: `Kullanıcı ${userId} rolü başarıyla ${newRole} olarak güncellendi.`,
            user: updatedUser
        });
    } catch (error) {
        console.error("Admin: Rol güncelleme hatası:", error.message);
        res.status(500).send({ message: error.message });
    }
};

/**
 * Anlaşmazlıkları çözmek için bir bağışın durumunu manuel olarak günceller.
 */
exports.resolveDispute = async (req, res) => {
    const { donationId } = req.params;
    const { status } = req.body; // 'completed', 'cancelled' vb.

    if (!status) {
        return res.status(400).send({ message: 'Yeni bağış durumu gereklidir.' });
    }

    try {
        const updatedDonation = await Admin.setDonationStatus(donationId, status);
        res.status(200).send({
            message: `Bağış ${donationId} durumu başarıyla ${status} olarak ayarlandı.`,
            donation: updatedDonation
        });
    } catch (error) {
        console.error("Admin: Anlaşmazlık çözme hatası:", error.message);
        res.status(500).send({ message: error.message });
    }
};

// 💡 Diğer Admin rotaları (Örn: listAllUsers, getSystemLogs) buraya eklenebilir.