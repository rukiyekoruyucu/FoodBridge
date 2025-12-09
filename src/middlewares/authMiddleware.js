// foodbridge-backend/src/middlewares/authMiddleware.js
const admin = require('../config/firebase'); // Firebase Admin SDK
const User = require('../models/User');

// 1. Kullanıcının oturum açıp açmadığını kontrol eden middleware
exports.isAuthenticated = async (req, res, next) => {
    // ... (Token kontrolü kısmı aynı kalır) ...
    if (!req.headers.authorization || !req.headers.authorization.startsWith('Bearer ')) {
        return res.status(401).send({ message: 'Erişim reddedildi. Token gerekli.' });
    }

    const idToken = req.headers.authorization.split('Bearer ')[1];

    try {
        // 1. Firebase ile tokenı doğrula (UID'yi al)
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        req.user = decodedToken; // uid, email gibi Firebase bilgilerini ekle

        // 2. Veritabanından kullanıcının rolünü çek 💡 YENİ KRİTİK ADIM
        const userRole = await User.getRoleByUid(decodedToken.uid);

        if (!userRole) {
            // Token geçerli ama kullanıcı DB'de yoksa (tutarsızlık)
            return res.status(403).send({ message: 'Kullanıcı veritabanında bulunamadı.' });
        }

        req.user.role = userRole; // Rolü istek objesine ekle

        next();
    } catch (error) {
        console.error("Token Doğrulama Hatası:", error.message);
        return res.status(401).send({ message: 'Token geçersiz veya süresi dolmuş.' });
    }
};

// 2. Kullanıcının belirli bir role sahip olup olmadığını kontrol eden middleware
// Örn: checkRole(['company']) veya checkRole(['company', 'manager'])
exports.checkRole = (allowedRoles) => {
    return (req, res, next) => {
        // isAuthenticated middleware'i zaten req.user'ı ekledi
        if (!req.user || !req.user.role) {
            // Eğer role alanı token içinde yoksa, DB'den kontrol etmek gerekebilir.
            // Ama basitlik için, şimdilik sadece token'daki role güveniyoruz.
            return res.status(403).send({ message: 'Yetki bilgisi eksik.' });
        }

        const userRole = req.user.role;

        if (allowedRoles.includes(userRole)) {
            next(); // İzin verildi
        } else {
            // İzin verilmedi
            return res.status(403).send({ message: 'Bu işlem için yeterli yetkiniz yok.' });
        }
    };
};