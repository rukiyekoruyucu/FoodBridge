// foodbridge-backend/src/models/Donation.js

const supabase = require('../config/db');
const { updateKindnessPoints } = require('./User'); // İyilik Puanı güncellemesi için

// Veritabanındaki 'donation_status' enum değerleriyle uyumlu olmalıdır
const DONATION_STATUS = {
    PENDING: 'pending',     // Talep gönderildi, Bağışçı onay bekliyor
    ACCEPTED: 'accepted',   // Bağışçı onayladı, Alıcı almaya hazır
    REJECTED: 'rejected',   // Bağışçı reddetti
    COMPLETED: 'completed', // Alıcı ürünü aldığını onayladı (Başarılı işlem)
    CANCELLED: 'cancelled'  // Kullanıcı tarafından iptal edildi
};

/**
 * Bir ihtiyaç sahibi tarafından ürün talep edilir.
 * Yeni bir 'donations' kaydı oluşturur ve ürünün 'is_available' durumunu kapatır (Önlem).
 */
async function createDonationRequest(itemId, recipientUserId) {
    // Supabase ile İşlem (Transaction) mantığı kullanarak veri bütünlüğünü sağlama
    // (Gerçek bir projede, bu tür kritik adımlar için RLS politikaları veya Postgre'nin transaction'ları tercih edilir.)

    // 1. Ürünün mevcut ve uygun olup olmadığını kontrol et
    const { data: itemData, error: itemError } = await supabase
        .from('items')
        .select('is_available, donor_user_id')
        .eq('item_id', itemId)
        .eq('is_available', true)
        .single();

    if (itemError || !itemData) {
        throw new Error('Talep edilen ürün bulunamadı veya şu anda mevcut değil.');
    }

    const donorUserId = itemData.donor_user_id;

    // 2. Yeni bağış talebi kaydı oluştur
    const { data: donationData, error: donationError } = await supabase
        .from('donations')
        .insert({
            item_id: itemId,
            donor_user_id: donorUserId,
            recipient_user_id: recipientUserId,
            status: DONATION_STATUS.PENDING
        })
        .select();

    if (donationError) {
        console.error("Bağış talebi oluşturma hatası:", donationError.message);
        throw new Error('Bağış talebi oluşturulamadı.');
    }

    // 3. Ürünü artık mevcut değil olarak işaretle (Başka bir talep gelmesini engellemek için)
    // 💡 İdeal olarak bu adım da transaction içinde olmalıdır.
    await supabase
        .from('items')
        .update({ is_available: false })
        .eq('item_id', itemId);

    return donationData[0];
}

/**
 * Bağışçı (Donor) bir talebe yanıt verir (Kabul veya Red).
 */
async function respondToRequest(donationId, donorUserId, newStatus) {
    if (newStatus !== DONATION_STATUS.ACCEPTED && newStatus !== DONATION_STATUS.REJECTED) {
        throw new Error('Geçersiz yanıt durumu. Sadece ACCEPTED veya REJECTED olabilir.');
    }

    const { data, error } = await supabase
        .from('donations')
        .update({
            status: newStatus,
            claimed_at: newStatus === DONATION_STATUS.ACCEPTED ? new Date().toISOString() : null
        })
        .eq('donation_id', donationId)
        .eq('donor_user_id', donorUserId) // Sadece doğru bağışçı güncelleyebilir
        .eq('status', DONATION_STATUS.PENDING) // Sadece bekleyen talepler yanıtlanabilir
        .select();

    if (error) {
        console.error("Talep yanıtı hatası:", error.message);
        throw new Error('Talep yanıtlanamadı.');
    }
    if (data.length === 0) {
        throw new Error('Talep bulunamadı veya yanıtlamaya yetkiniz yok.');
    }

    // Eğer talep reddedilirse, ürünü tekrar mevcut olarak işaretle
    if (newStatus === DONATION_STATUS.REJECTED) {
        await supabase
            .from('items')
            .update({ is_available: true })
            .eq('item_id', data[0].item_id);
    }

    return data[0];
}

/**
 * Alıcı (Recipient) işlemi tamamlandığını onaylar.
 * İyilik Puanı (Kindness Point) burada işlenir.
 */
async function completeDonation(donationId, recipientUserId) {
    // 1. Bağış kaydını bul ve Alıcı'nın doğru kişi olduğunu kontrol et
    const { data: donationData, error: findError } = await supabase
        .from('donations')
        .select('donor_user_id, status, item_id')
        .eq('donation_id', donationId)
        .eq('recipient_user_id', recipientUserId)
        .eq('status', DONATION_STATUS.ACCEPTED) // Sadece kabul edilmiş işlemler tamamlanabilir
        .single();

    if (findError || !donationData) {
        throw new Error('İşlem bulunamadı, tamamlanmaya uygun değil veya yetkiniz yok.');
    }

    // 2. Bağış durumunu "COMPLETED" olarak güncelle
    const { data: updateData, error: updateError } = await supabase
        .from('donations')
        .update({
            status: DONATION_STATUS.COMPLETED,
            completed_at: new Date().toISOString()
        })
        .eq('donation_id', donationId)
        .select();

    if (updateError) {
        console.error("Bağış tamamlama hatası:", updateError.message);
        throw new Error('Bağış tamamlanamadı.');
    }

    // 3. İyilik Puanlarını (Kindness Points) Bağışçıya ekle
    // (Örn: Her başarılı bağış için 10 puan)
    const POINTS_TO_ADD = 10;
    await updateKindnessPoints(donationData.donor_user_id, POINTS_TO_ADD);

    // 4. İlgili ürünü 'is_available: false' olarak kalıcı olarak işaretle (ürün transfer edildi)
    // 💡 Eğer bir item birden fazla kez bağışlanacaksa, bu adımı es geçmeliyiz (Örn: Kurumsal bağışlarda büyük stoklar)
    // Şu anki şemaya göre tek seferlik varsayıyoruz.
    await supabase
        .from('items')
        .update({ is_available: false })
        .eq('item_id', donationData.item_id);

    return updateData[0];
}

module.exports = {
    DONATION_STATUS,
    createDonationRequest,
    respondToRequest,
    completeDonation,
};