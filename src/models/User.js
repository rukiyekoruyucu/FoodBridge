// foodbridge-backend/src/models/User.js (KESİN VE DOĞRU SÖZ DİZİMİ)

const supabase = require('../config/db');

// Database ENUM'ları ile uyumlu roller
const ROLES = {
    // Veritabanı: 'normal'
    PERSONAL: 'normal',
    // Veritabanı: 'company'
    COMPANY: 'company',
    // Veritabanı: 'person_in_need'
    NEEDY: 'person_in_need',
    // 'admin' (Admin rolü de kodda tanımlıysa kalsın)
    ADMIN: 'admin'
};

async function createUser(uid, email, username, role) {
    if (!Object.values(ROLES).includes(role)) {
        throw new Error('Geçersiz kullanıcı rolü.');
    }

    const { data, error } = await supabase
        .from('users')
        .insert({
            user_id: uid,
            email: email,
            username: username,
            role: role,
            kindness_points: 0
        })
        .select();

    if (error) {
        // Hata yönetimi kodu (Artık detaylı hata döndürüyor)
        console.error("Veritabanına kullanıcı ekleme hatası:", error);
        throw new Error(`Veritabanına kullanıcı ekleme hatası: ${error.message}. ${error.details ? 'Detay: ' + error.details : ''}`);
    }

    return data[0];
}

async function getRoleByUid(uid) {
    const { data, error } = await supabase
        .from('users')
        .select('role')
        .eq('user_id', uid)
        .single();

    if (error) {
        console.error("Rol çekme hatası:", error.message);
        return null;
    }

    return data ? data.role : null;
}

async function updateKindnessPoints(uid, pointsToAdd) {
    const { error } = await supabase.rpc('increment_kindness_points', {
        user_id_param: uid,
        points_to_add_param: pointsToAdd
    });

    if (error) {
        console.error("Puan güncelleme hatası:", error.message);
        throw new Error('Puanlar güncellenemedi.');
    }

    return true;
}

module.exports = {
    createUser,
    getRoleByUid,
    updateKindnessPoints,
    ROLES
};