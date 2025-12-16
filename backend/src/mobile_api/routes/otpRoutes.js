const express = require('express');
const router = express.Router();
const {
  sendOtp,
  verifyOtp,
  resendOtp,
  checkOtpStatus
} = require('../controllers/otpController');

/**
 * @route   POST /otp/send
 * @desc    Send OTP via DoveSoft WhatsApp
 * @access  Public
 * @body    { phone: string, name?: string }
 */
router.post('/send', sendOtp);

/**
 * @route   POST /otp/verify
 * @desc    Verify OTP
 * @access  Public
 * @body    { phone: string, otp: string }
 */
router.post('/verify', verifyOtp);

/**
 * @route   POST /otp/resend
 * @desc    Resend OTP via DoveSoft WhatsApp
 * @access  Public
 * @body    { phone: string, name?: string }
 */
router.post('/resend', resendOtp);

/**
 * @route   GET /otp/status
 * @desc    Check OTP status (without verifying)
 * @access  Public
 * @query   { phone: string }
 */
router.get('/status', checkOtpStatus);

module.exports = router;

