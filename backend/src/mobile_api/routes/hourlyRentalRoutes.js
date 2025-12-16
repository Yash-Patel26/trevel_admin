const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth');
const {
createHourlyRentalBooking,
updateHourlyRentalWithExtensions
} = require('../controllers/hourlyRentalController');

// Note: GET bookings endpoints removed - use /api/v1/my-bookings?status=all instead
router.post('/bookings', authMiddleware, createHourlyRentalBooking);
router.patch('/bookings/:id/extensions', authMiddleware, updateHourlyRentalWithExtensions);

module.exports = router;
