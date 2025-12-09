// foodbridge-backend/src/routes/authRoutes.js

const express = require('express');
const router = express.Router();

// Controller, Middleware ve Validation'ları çağırıyoruz
const authController = require('../controllers/authController');
const authMiddleware = require('../middlewares/authMiddleware');
const { registerValidation, validate } = require('../utils/validation'); // Girdi doğrulama için

// --------------------------------------------------------
// --- Auth Rotaları ---
// --------------------------------------------------------

/**
 * Rota: POST /api/auth/register
 * İşlev: Yeni kullanıcı kaydı. 
 * Güvenlik: Girdi Doğrulama (Input Validation) içerir.
 */
router.post('/register',
    registerValidation, // 1. Adım: Girdi kurallarını uygula (email, password, role)
    validate,           // 2. Adım: Hataları yakala ve 400 Bad Request döndür
    authController.register
);

/**
 * Rota: POST /api/auth/login
 * İşlev: Kullanıcı girişi.
 */
router.post('/login', authController.login);

/**
 * Rota: GET /api/auth/user-role
 * İşlev: Kullanıcının geçerli token'ı ile rolünü ve temel bilgilerini çeker.
 * Güvenlik: Oturum açma gereklidir (isAuthenticated).
 */
router.get('/user-role',
    authMiddleware.isAuthenticated, // Token doğrulaması yapar ve req.user'a rolü ekler
    authController.getAuthenticatedUserRole
);

// --------------------------------------------------------
// --- Geliştirme/Test Rotaları ---
// --------------------------------------------------------

// Geçici bir test rotası (API'nin çalıştığını kontrol etmek için)
router.get('/test', (req, res) => {
    res.status(200).send({ message: 'Auth Rotası Çalışıyor!' });
});

module.exports = router;