// foodbridge-backend/src/utils/validation.js

const { body, validationResult } = require('express-validator');
const { ROLES } = require('../models/User'); // Kullanýcý rollerini kullanýyoruz

// --- 1. Rota Ýþleyicisini (Handler) Oluþturma ---
// Doðrulama hatasý varsa, controller'a geçmeden 400 Bad Request döndürür.
exports.validate = (req, res, next) => {
    const errors = validationResult(req);
    if (errors.isEmpty()) {
        return next(); // Hata yoksa, bir sonraki middleware'e veya controller'a geç
    }

    // Hata varsa, detaylý hata mesajlarýný topla
    const extractedErrors = [];
    errors.array().map(err => extractedErrors.push({ [err.param]: err.msg }));

    return res.status(400).json({
        success: false,
        message: "Girdi verilerinizde hatalar var.",
        errors: extractedErrors,
    });
};

// --- 2. Kayýt (Register) Doðrulama Kurallarý ---
exports.registerValidation = [
    // Email kontrolü
    body('email', 'Geçerli bir e-posta adresi girin.').isEmail(),
    // Þifre kontrolü
    body('password', 'Þifre en az 6 karakter olmalýdýr.').isLength({ min: 6 }),
    // Kullanýcý adý kontrolü
    body('username', 'Kullanýcý adý boþ býrakýlamaz.').notEmpty(),
    // Rol kontrolü
    body('role', 'Geçersiz veya eksik kullanýcý rolü.')
        .isIn(Object.values(ROLES)), // Role'ün belirlenen rollerden biri olup olmadýðýný kontrol et
];

// --- 3. Ürün Ekleme (Add Item) Doðrulama Kurallarý ---
exports.addItemValidation = [
    body('name', 'Ürün adý gereklidir.').trim().isLength({ min: 2 }),
    body('quantity', 'Miktar geçerli bir pozitif sayý olmalýdýr.')
        .isInt({ gt: 0 }).withMessage('Miktar 0\'dan büyük olmalýdýr.'),
    body('expiryDate', 'Geçerli bir son kullanma tarihi (YYYY-MM-DD) girin.')
        .isISO8601().toDate(), // ISO 8601 tarih formatýný kontrol et
    body('category', 'Kategori boþ býrakýlamaz.').notEmpty(),
    // Ek: category'nin belirli bir ENUM listesinde olup olmadýðý da kontrol edilebilir.
];