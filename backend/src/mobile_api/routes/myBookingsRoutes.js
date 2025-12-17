const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth');
const { getMyBookings, getMyBookingById, getUpcomingRides } = require('../controllers/myBookingsController');

// Unified bookings API - supports status filter: upcoming, completed, cancelled, or all
// Query params: ?status=upcoming|completed|cancelled|all (default: all)
router.get('/', authMiddleware, getMyBookings);
router.get('/upcoming', authMiddleware, getUpcomingRides);
router.get('/:id', authMiddleware, getMyBookingById);

module.exports = router;
