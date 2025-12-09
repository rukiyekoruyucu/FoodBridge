// foodbridge-backend/src/routes/privateFridgeRoutes.js

const express = require('express');
const router = express.Router();

const privateController = require('../controllers/privateFridgeController');
const { isAuthenticated, checkRole } = require('../middlewares/authMiddleware');
const { ROLES } = require('../models/User');
// Girdi Doðrulama ve Item Transferi için gerekli olanlar
const { addItemValidation, validate } = require('../utils/validation');

const DONOR_ROLES = [ROLES.PERSONAL, ROLES.COMPANY];

// --------------------------------------------------------
// --- Kiþisel Envanter (Private Stash) Rotalarý ---
// --------------------------------------------------------

/**
 * Rota: GET /api/private-fridge/items
 * Ýþlev: Donörün tüm kiþisel envanterini listeler (Son kullanma tarihine göre sýralý).
 * Eriþim: Sadece Donor rolleri
 */
router.get('/items',
    isAuthenticated,
    checkRole(DONOR_ROLES),
    privateController.getMyItems
);

/**
 * Rota: POST /api/private-fridge/items
 * Ýþlev: Envantere yeni ürün ekler.
 * Güvenlik: Girdi Doðrulama (Input Validation) içerir.
 * Eriþim: Sadece Donor rolleri
 */
router.post('/items',
    isAuthenticated,
    checkRole(DONOR_ROLES),
    addItemValidation, // 1. Adým: Yeni ürünü doðrulama
    validate,          // 2. Adým: Hata varsa 400 döndür
    privateController.addItem
);

/**
 * Rota: PUT /api/private-fridge/items/:itemId
 * Ýþlev: Envanterdeki bir ürünü günceller (Miktar, Son Kullanma Tarihi vb.).
 * Eriþim: Sadece Donor rolleri
 */
router.put('/items/:itemId',
    isAuthenticated,
    checkRole(DONOR_ROLES),
    privateController.updateItem
);

/**
 * Rota: DELETE /api/private-fridge/items/:itemId
 * Ýþlev: Envanterdeki bir ürünü siler.
 * Eriþim: Sadece Donor rolleri
 */
router.delete('/items/:itemId',
    isAuthenticated,
    checkRole(DONOR_ROLES),
    privateController.deleteItem
);

// --------------------------------------------------------
// --- TRANSFER ROTALARI ---
// --------------------------------------------------------

/**
 * Rota: PUT /api/private-fridge/items/:itemId/transfer
 * Ýþlev: Kiþisel ürünü topluluk buzdolabýna taþýr (is_available = true olur).
 * Eriþim: Sadece Donor rolleri
 */
router.put('/items/:itemId/transfer',
    isAuthenticated,
    checkRole(DONOR_ROLES),
    privateController.transferItem
);


module.exports = router;