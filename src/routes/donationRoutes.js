const express = require("express");
const router = express.Router();
const donationController = require("../controllers/donationController");
const authMiddleware = require("../middlewares/authMiddleware");
const roleMiddleware = require("../middlewares/roleMiddleware");
const Joi = require("joi");
const validate = require("../middlewares/validationMiddleware");
const rejectSchema = Joi.object({
  reason: Joi.string().allow("", null).optional()
});

/**
 * NEEDY -> item için bağış talebi oluşturur
 */
const requestDonationSchema = Joi.object({
  itemId: Joi.number().integer().required(),
  type: Joi.string().valid("DONATION", "TRADE").optional()
});
router.post(
  "/:id/reject",
  authMiddleware,
  roleMiddleware(["PERSONAL","CORPORATE"]),
  validate(rejectSchema),
  donationController.rejectRequest
);


router.post(
  "/request",
  authMiddleware,
  roleMiddleware(["NEEDY", "PERSONAL", "CORPORATE"]), // isteyen herkes talep edebilir (trade için de)
  validate(requestDonationSchema),
  donationController.requestDonation
);

/**
 * DONOR -> item'a gelen PENDING istekleri listeler
 * /api/donations/items/:itemId/requests
 */
router.get(
  "/items/:itemId/requests",
  authMiddleware,
  roleMiddleware(["PERSONAL", "CORPORATE"]),
  donationController.listItemRequests
);

/**
 * DONOR -> bir isteği kabul eder (donationId üzerinden)
 * /api/donations/:id/accept
 */
router.post(
  "/:id/accept",
  authMiddleware,
  roleMiddleware(["PERSONAL", "CORPORATE"]),
  donationController.acceptRequest
);

/**
 * DONOR veya RECIPIENT -> teslim alındı/teslim edildi onayı
 * /api/donations/:id/confirm-pickup
 */
router.post(
  "/:id/confirm-pickup",
  authMiddleware,
  donationController.confirmPickup
);

/**
 * Kullanıcının bağış geçmişi
 */
router.get(
  "/me",
  authMiddleware,
  donationController.listMyDonations
);

module.exports = router;
