const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth');
const {
validatePromoCode,
calculatePromoDiscount,
applyPromoCodeToBooking
} = require('../controllers/promoCodeController');
router.post('/validate', authMiddleware, validatePromoCode);
router.post('/calculate', authMiddleware, calculatePromoDiscount);
module.exports = router;
