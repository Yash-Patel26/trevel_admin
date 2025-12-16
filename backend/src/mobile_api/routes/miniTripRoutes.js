const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth');
const {
createMiniTripBooking,
updateMiniTripArrivalTimes,
getRoutesForBooking,
updateRouteAtTripStart
} = require('../controllers/miniTripController');

// Note: GET bookings endpoints removed - use /api/v1/my-bookings?status=all instead
router.post('/bookings', authMiddleware, createMiniTripBooking);
router.patch('/bookings/:id/arrival-times', authMiddleware, updateMiniTripArrivalTimes);
router.get('/routes', authMiddleware, getRoutesForBooking);
router.patch('/bookings/:id/route', authMiddleware, updateRouteAtTripStart);

module.exports = router;
