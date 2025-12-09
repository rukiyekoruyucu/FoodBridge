// foodbridge-backend/src/routes/adminRoutes.js

const express = require('express');
const router = express.Router();

const adminController = require('../controllers/adminController');
const { isAuthenticated, checkRole } = require('../middlewares/authMiddleware');
const { ROLES } = require('../models/User');

const ADMIN_ROLE = [ROLES.ADMIN]; // Sadece 'admin' rolü için

// Tüm Admin rotalarý için önce kimlik doðrulama ve Admin rolü kontrolü yapýlýr.
router.use(isAuthenticated, checkRole(ADMIN_ROLE));

// --------------------------------------------------------
// --- Admin Ýþlevleri Rotalarý ---
// --------------------------------------------------------

/**
 * Rota: PUT /api/admin/users/:userId/role
 * Ýþlev: Belirli bir kullanýcýnýn rolünü günceller (Kurumsal onay, Banlama).
 * Eriþim: Sadece Admin
 */
router.put('/users/:userId/role', adminController.updateUserRole);

/**
 * Rota: PUT /api/admin/disputes/:donationId/resolve
 * Ýþlev: Baðýþ anlaþmazlýðýný çözmek için durumu manuel ayarlar.
 * Eriþim: Sadece Admin
 */
router.put('/disputes/:donationId/resolve', adminController.resolveDispute);

module.exports = router;