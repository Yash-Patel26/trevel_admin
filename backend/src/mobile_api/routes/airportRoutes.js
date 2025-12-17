const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth');
const {
    createToAirportTransferBooking,
    createFromAirportTransferBooking
} = require('../controllers/airportTransferController');
const { getAirports, getAirportById, getTransferOptions } = require('../controllers/airportController');

// Note: GET bookings endpoints removed - use /api/v1/my-bookings?status=all instead

// Public/Protected Airport reference data
router.get('/', authMiddleware, getAirports);
router.get('/:id', authMiddleware, getAirportById);

router.post('/transfer-options', authMiddleware, getTransferOptions);

router.post('/to-airport/transfer-bookings', authMiddleware, createToAirportTransferBooking);
router.post('/from-airport/transfer-bookings', authMiddleware, createFromAirportTransferBooking);

module.exports = router;
