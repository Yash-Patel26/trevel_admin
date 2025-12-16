const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth');
const {
createToAirportTransferBooking,
createFromAirportTransferBooking
} = require('../controllers/airportTransferController');

// Note: GET bookings endpoints removed - use /api/v1/my-bookings?status=all instead
router.post('/to-airport/transfer-bookings', authMiddleware, createToAirportTransferBooking);
router.post('/from-airport/transfer-bookings', authMiddleware, createFromAirportTransferBooking);

module.exports = router;
