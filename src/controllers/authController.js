// foodbridge-backend/src/controllers/authController.js (HATALARI KESİN GİDERİLMİŞ VERSİYON)

const admin = require('../config/firebase'); // Firebase Admin SDK
const User = require('../models/User'); // Veritabanı modelimiz

/**
 * Yeni kullanıcı kaydını işler. (exports.register fonksiyonu)
 * 🚨 GÜNCELLEME: Supabase kaydı başarısız olursa Firebase kullanıcısı silinir (Atomik işlem).
 */
const register = async (req, res) => { // 🚨 exports yerine const ile tanımla
    const { email, password, username, role } = req.body;

    // Temel input kontrolleri
    if (!email || !password || !username || !role) {
        return res.status(400).send({ message: 'E-posta, şifre, kullanıcı adı ve rol gereklidir.' });
    }

    // Kullanıcı modelindeki güncel ROLES değerleriyle kontrol edilir.
    if (!Object.values(User.ROLES).includes(role)) {
        return res.status(400).send({
            message: 'Geçersiz rol seçimi.',
            accepted_roles: Object.values(User.ROLES)
        });
    }

    let firebaseUser; // Firebase kullanıcısını try bloğu dışında tanımla
    let isFirebaseUserCreated = false; // Temizlik için bayrak

    try {
        // 1. Firebase Auth'ta kullanıcı oluşturma
        firebaseUser = await admin.auth().createUser({
            email,
            password,
            displayName: username
        });
        isFirebaseUserCreated = true; // Firebase'de oluştu

        // 2. Kullanıcının rol ve diğer bilgilerini PostgreSQL'e kaydetme
        await User.createUser(firebaseUser.uid, email, username, role);

        // 3. (Opsiyonel): Firebase Custom Claim ile rolü token'a gömme
        await admin.auth().setCustomUserClaims(firebaseUser.uid, { role: role });

        // Başarılı yanıt
        return res.status(201).send({
            message: 'Kayıt başarılı. Kullanıcı oluşturuldu.',
            userId: firebaseUser.uid,
            role: role
        });

    } catch (error) {
        // Supabase hatası varsa (Adım 2 başarısız oldu), Firebase'deki kullanıcıyı sil (ROLLBACK)
        if (isFirebaseUserCreated && firebaseUser && firebaseUser.uid) {
            console.log(`[TEMİZLİK] Supabase/Veritabanı kaydı başarısız oldu. Firebase kullanıcısı (${firebaseUser.uid}) siliniyor...`);
            await admin.auth().deleteUser(firebaseUser.uid)
                .catch(deleteError => {
                    console.error("Firebase kullanıcı silme hatası (ROLLBACK FAILED):", deleteError.message);
                });
        }

        let statusCode = 409;
        let errorMessage = 'Kayıt başarısız.';

        if (error.message && error.message.includes('already in use')) {
            statusCode = 409;
            errorMessage = 'E-posta adresi zaten kullanımda.';
        } else if (error.message && error.message.includes('Veritabanına kullanıcı ekleme hatası')) {
            statusCode = 500;
            errorMessage = error.message;
        } else if (error.message) {
            statusCode = 500;
            errorMessage = error.message;
        }

        console.error("Kayıt sırasında hata:", error.message);
        return res.status(statusCode).send({
            message: 'Kayıt başarısız.',
            error: errorMessage
        });
    }
};


/**
 * Kullanıcı Girişini Yönetir.
 */
const login = async (req, res) => { // 🚨 exports yerine const ile tanımla
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).send({ message: 'E-posta ve şifre gereklidir.' });
    }

    try {
        // Bu kısım simülasyon olduğu için sadece başarılı yanıt döndürülür
        return res.status(200).send({
            message: 'Oturum açma isteği alındı. Başarılı yanıt gönderildi.',
            status: 'success'
        });

    } catch (error) {
        console.error("Giriş hatası:", error.message);
        return res.status(401).send({
            message: 'Giriş başarısız. Kimlik bilgileri hatalı.'
        });
    }
};


/**
 * Kimlik doğrulama sonrası kullanıcının rolünü çeker...
 */
const getAuthenticatedUserRole = async (req, res) => { // 🚨 exports yerine const ile tanımla
    const uid = req.user.uid;

    try {
        const role = await User.getRoleByUid(uid);

        if (!role) {
            return res.status(404).send({ message: 'Kullanıcı veritabanında bulunamadı.' });
        }

        return res.status(200).send({ uid, role });
    } catch (error) {
        return res.status(500).send({ message: 'Rol bilgisi alınamadı.', error: error.message });
    }
};
/**
 * Geliştirme/Test Amaçlı Özel Token Oluşturur.
 * NOT: YALNIZCA KORUNMALI (authMiddleware.isAuthenticated) ENDPOINT'ler için kullanılır.
 */
exports.generateTestToken = async (req, res) => {
    // Buraya, daha önce kaydettiğiniz donor kullanıcısının Firebase UID'sini manuel olarak yazmalısınız.
    // Örnek: "Hry72KKLKfNgqXHkmddt5O6trOr2" gibi.
    const TEST_DONOR_UID = req.body.uid;

    if (!TEST_DONOR_UID) {
        return res.status(400).send({ message: 'UID gereklidir.' });
    }

    try {
        // Firebase Admin SDK ile Custom Token oluşturma
        const customToken = await admin.auth().createCustomToken(TEST_DONOR_UID);

        // Bu custom token'ı döndürme
        return res.status(200).send({
            message: 'Custom Token başarıyla oluşturuldu.',
            token: customToken,
            info: 'Bu Custom Token\'ı kullanarak client-side SDK\'da oturum açılabilir.'
        });

    } catch (error) {
        return res.status(500).send({ message: 'Token oluşturulamadı.', error: error.message });
    }
};


// 🚨 KRİTİK DÜZELTME: Tüm fonksiyonları modülün sonunda açıkça dışa aktar
module.exports = {
    register, // register fonksiyonu
    login, // login fonksiyonu
    getAuthenticatedUserRole, // getAuthenticatedUserRole fonksiyonu
    generateTestToken: exports.generateTestToken
};