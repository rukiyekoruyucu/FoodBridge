// foodbridge-backend/src/routes/chatRoutes.js

const express = require('express');
const router = express.Router();

const chatController = require('../controllers/chatController');
const { isAuthenticated } = require('../middlewares/authMiddleware');

/**
 * Rota: GET /api/chat/:donationId/history
 * Ýþlev: Belirli bir baðýþ için geçmiþ mesajlarý listeler.
 * Eriþim: Sadece baðýþta taraf olan kullanýcýlar.
 */
router.get('/:donationId/history',
    isAuthenticated,
    chatController.getChatHistory
);

module.exports = router;