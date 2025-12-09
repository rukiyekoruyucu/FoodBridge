// foodbridge-backend/src/routes/donationRoutes.js

const express = require('express');
const router = express.Router();

const donationController = require('../controllers/donationController');
const { isAuthenticated, checkRole } = require('../middlewares/authMiddleware');
const { ROLES } = require('../models/User');

// Rol tanımları
const DONOR_ROLES = [ROLES.PERSONAL, ROLES.COMPANY];
const RECIPIENT_ROLES = [ROLES.NEEDY, ROLES.PERSONAL]; // Personal, hem bağışçı hem alıcı olabilir

// --------------------------------------------------------
// --- Alıcı (Recipient) Rotaları (Talep Etme ve Tamamlama) ---
// --------------------------------------------------------

/**
 * Rota: POST /api/donations/request
 * İşlev: Ürün talep eder (PENDING durumu ile başlar).
 * Erişim: Sadece RECIPIENT_ROLES
 */
router.post('/request',
    isAuthenticated,
    checkRole(RECIPIENT_ROLES),
    donationController.requestItem
);

/**
 * Rota: POST /api/donations/:donationId/confirm-pickup
 * İşlev: Alıcı ürünü aldığını onaylar (COMPLETED durumuna geçer ve puan eklenir).
 * Erişim: Sadece RECIPIENT_ROLES
 */
router.post('/:donationId/confirm-pickup',
    isAuthenticated,
    checkRole(RECIPIENT_ROLES),
    donationController.confirmPickup
);


// --------------------------------------------------------
// --- Bağışçı (Donor) Rotaları (Yanıt Verme) ---
// --------------------------------------------------------

/**
 * Rota: PUT /api/donations/:donationId/respond
 * İşlev: Bağışçı bir talebi ACCEPTED veya REJECTED olarak günceller.
 * Erişim: Sadece DONOR_ROLES
 */
router.put('/:donationId/respond',
    isAuthenticated,
    checkRole(DONOR_ROLES),
    donationController.respondToRequest
);

// 💡 Ek Rota: Bağışçının kendi taleplerini görmesi (GET /api/donations/my-donations) buraya eklenebilir.

module.exports = router;