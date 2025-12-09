// foodbridge-backend/src/models/Admin.js

const supabase = require('../config/db');
const { ROLES } = require('./User'); // Rol sabitlerini kullanıyoruz

/**
 * Belirli bir kullanıcının rolünü günceller (Örn: Banlama, Kurumsal onaylama).
 * @param {string} userId - Rolü değiştirilecek kullanıcının UID'si.
 * @param {string} newRole - Yeni rol (Örn: 'personal', 'company', 'admin' veya 'banned').
 */
async function updateUserRole(userId, newRole) {
    if (!Object.values(ROLES).includes(newRole)) {
        throw new Error('Geçersiz yeni rol.');
    }

    const { data, error } = await supabase
        .from('users')
        .update({ role: newRole, updated_at: new Date().toISOString() })
        .eq('user_id', userId)
        .select();

    if (error) {
        console.error("Kullanıcı rolü güncelleme hatası:", error.message);
        throw new Error('Kullanıcı rolü güncellenemedi.');
    }
    if (data.length === 0) {
        throw new Error('Kullanıcı bulunamadı.');
    }
    return data[0];
}

/**
 * Bağış (Donation) durumunu manuel olarak günceller (Anlaşmazlık çözümü için).
 * @param {string} donationId - Güncellenecek bağış ID'si.
 * @param {string} status - Yeni durum (Örn: 'completed', 'cancelled').
 */
async function setDonationStatus(donationId, status) {
    // Donation modelindeki DONATION_STATUS sabitlerini kullanmalıyız.
    // Şimdilik sadece güncelliyoruz.

    const { data, error } = await supabase
        .from('donations')
        .update({ status: status, updated_at: new Date().toISOString() })
        .eq('donation_id', donationId)
        .select();

    if (error) {
        console.error("Bağış durumu güncelleme hatası:", error.message);
        throw new Error('Bağış durumu güncellenemedi.');
    }
    if (data.length === 0) {
        throw new Error('Bağış işlemi bulunamadı.');
    }
    return data[0];
}

// 💡 Diğer Admin işlevleri (Örn: Sistem loglarını çekme, Buzdolabı durumunu değiştirme) buraya eklenebilir.

module.exports = {
    updateUserRole,
    setDonationStatus
};