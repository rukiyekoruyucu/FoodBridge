// foodbridge-backend/src/routes/fridgeRoutes.js

const express = require('express');
const router = express.Router();

const fridgeController = require('../controllers/fridgeController');
const { isAuthenticated, checkRole } = require('../middlewares/authMiddleware');
const { ROLES } = require('../models/User'); // Rol sabitlerini al

// --------------------------------------------------------
// --- Buzdolabý Listeleme ve Arama Rotalarý (Genel Eriþim) ---
// --------------------------------------------------------

/**
 * Rota: GET /api/fridges?lat=xx&lon=yy
 * Ýþlev: Konuma göre en yakýn buzdolaplarýný listeler.
 * Eriþim: Tüm kayýtlý kullanýcýlar (Recipient, Personal, Company)
 */
router.get('/', 
    isAuthenticated, // Oturum açmýþ herkes
    fridgeController.getFridges
);

/**
 * Rota: GET /api/fridges/:fridgeId/items
 * Ýþlev: Belirli bir buzdolabýndaki tüm mevcut ürünleri listeler.
 * Eriþim: Tüm kayýtlý kullanýcýlar
 */
router.get('/:fridgeId/items', 
    isAuthenticated, 
    fridgeController.getFridgeItems
);

// --------------------------------------------------------
// --- Ürün CRUD Rotalarý (Donor Eriþimi) ---
// --------------------------------------------------------

// Donor rolleri: personal ve company
const DONOR_ROLES = [ROLES.PERSONAL, ROLES.COMPANY];

/**
 * Rota: POST /api/fridges/:fridgeId/items
 * Ýþlev: Buzdolabýna yeni ürün ekler.
 * Eriþim: Sadece Donor rolleri
 */
router.post('/:fridgeId/items',
    isAuthenticated,
    checkRole(DONOR_ROLES),
    fridgeController.addItem
);

/**
 * Rota: PUT /api/fridges/items/:itemId
 * Ýþlev: Mevcut bir ürünü günceller (Sadece kendi ürününü).
 * Eriþim: Sadece Donor rolleri
 */
router.put('/items/:itemId',
    isAuthenticated,
    checkRole(DONOR_ROLES),
    fridgeController.updateItem
);

/**
 * Rota: DELETE /api/fridges/items/:itemId
 * Ýþlev: Mevcut bir ürünü siler (Sadece kendi ürününü).
 * Eriþim: Sadece Donor rolleri
 */
router.delete('/items/:itemId',
    isAuthenticated,
    checkRole(DONOR_ROLES),
    fridgeController.deleteItem
);


module.exports = router;