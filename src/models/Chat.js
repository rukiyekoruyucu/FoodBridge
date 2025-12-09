// foodbridge-backend/src/models/Chat.js

const supabase = require('../config/db');

/**
 * Belirli bir baðýþ (donation) için geçmiþ mesajlarý çeker.
 */
async function getMessagesByDonationId(donationId) {
    const { data, error } = await supabase
        .from('chat_messages')
        .select('*')
        .eq('donation_id', donationId)
        .order('sent_at', { ascending: true }); // Mesajlarý gönderilme sýrasýna göre sýrala

    if (error) {
        console.error(`Baðýþ ID ${donationId} için mesaj çekme hatasý:`, error.message);
        throw new Error('Mesajlar listelenemedi.');
    }
    return data;
}

/**
 * Yeni bir mesajý veritabanýna kaydeder.
 * (Gerçek zamanlý akýþý Socket.io yönetirken, bu veritabaný kaydý için kullanýlýr.)
 */
async function saveMessage(donationId, senderUserId, content) {
    const { data, error } = await supabase
        .from('chat_messages')
        .insert({
            donation_id: donationId,
            sender_user_id: senderUserId,
            content,
            sent_at: new Date().toISOString() // Þu anki zamaný kaydet
        })
        .select();

    if (error) {
        console.error("Mesaj kaydetme hatasý:", error.message);
        throw new Error('Mesaj kaydedilemedi.');
    }
    return data[0];
}

module.exports = {
    getMessagesByDonationId,
    saveMessage
};