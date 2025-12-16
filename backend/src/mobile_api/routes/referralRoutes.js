const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth');
const {
  getReferralInfo,
  applyReferralCode
} = require('../controllers/referralController');

router.get('/info', authMiddleware, getReferralInfo);
router.post('/apply', authMiddleware, applyReferralCode);

module.exports = router;

