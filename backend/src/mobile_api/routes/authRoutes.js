const express = require('express');
const router = express.Router();
const { logout, getCurrentUser, sendOtp, verifyOtp, resendOtp, changePassword } = require('../controllers/authController');
const authMiddleware = require('../middleware/auth');

router.post('/send-otp', sendOtp);
router.post('/verify-otp', verifyOtp);
router.post('/resend-otp', resendOtp);
router.post('/logout', authMiddleware, logout);
router.get('/me', authMiddleware, getCurrentUser);
router.post('/change-password', authMiddleware, changePassword);

module.exports = router;
