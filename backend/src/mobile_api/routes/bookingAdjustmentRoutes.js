const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth');
const {
updateActualDistance,
calculateTripStartPrice,
checkTolerance
} = require('../controllers/bookingAdjustmentController');
const {
createBooking,
cancelBooking,
updateBooking,
getBooking,
getBookings,
getBookingDriver,
getBookingStatus,
getLiveLocation,
callDriver,
shareRide,
changeRoute,
getWaitingTime,
downloadReceipt,
rebookRide,
updateBookingStatus
} = require('../controllers/bookingManagementController');
const { applyPromoCodeToBooking } = require('../controllers/promoCodeController');
const { checkDriverProximity, checkAllBookings } = require('../controllers/driverArrivalController');
const pricingController = require('../controllers/pricingController');
// Health check for bookings endpoint
router.get('/health', (req, res) => {
res.status(200).json({
success: true,
message: 'Bookings endpoint is accessible',
timestamp: new Date().toISOString()
});
});

router.post('/create', authMiddleware, createBooking);
router.post('/calculate-fare', authMiddleware, pricingController.estimatePrice);
router.post('/rebook', authMiddleware, rebookRide);
router.get('/', authMiddleware, getBookings);
router.post('/:id/cancel', authMiddleware, cancelBooking);
router.post('/:id/apply-promo', authMiddleware, applyPromoCodeToBooking);
router.patch('/:id/promo-code', authMiddleware, applyPromoCodeToBooking);
router.get('/:id/driver', authMiddleware, getBookingDriver);
router.get('/:id/status', authMiddleware, getBookingStatus);
router.get('/:id/live-location', authMiddleware, getLiveLocation);
router.post('/:id/call-driver', authMiddleware, callDriver);
router.post('/:id/share', authMiddleware, shareRide);
router.put('/:id/route', authMiddleware, changeRoute);
router.get('/:id/waiting-time', authMiddleware, getWaitingTime);
router.get('/:id/receipt', authMiddleware, downloadReceipt);
router.get('/:id/driver-proximity', authMiddleware, checkDriverProximity);
router.post('/:id/feedback', authMiddleware, async (req, res) => {
const ratingController = require('../controllers/ratingController');
const { id } = req.params;
const { rating, comment } = req.body;
const userId = req.user?.id;
const db = require('../config/postgresClient');
let bookingType = null;
for (const source of [
{ table: 'mini_trip_bookings', type: 'mini_trip' },
{ table: 'hourly_rental_bookings', type: 'hourly_rental' },
{ table: 'to_airport_transfer_bookings', type: 'to_airport' },
{ table: 'from_airport_transfer_bookings', type: 'from_airport' }
]) {
const { rows } = await db.query(
`SELECT * FROM ${source.table} WHERE id = $1 AND user_id = $2`,
[id, userId]
);
if (rows.length > 0) {
bookingType = source.type;
break;
}
}
if (!bookingType) {
return res.status(404).json({
success: false,
error: 'Booking not found'
});
}
req.body = {
booking_id: id,
booking_type: bookingType,
rating: rating,
review: comment
};
return ratingController.createRating(req, res);
});
router.get('/:id', authMiddleware, getBooking);
router.put('/:id', authMiddleware, updateBooking);
// Update booking status (for testing purposes)
router.patch('/:id/status', authMiddleware, updateBookingStatus);

// Update booking status (for testing purposes)
router.patch('/:id/status', authMiddleware, updateBookingStatus);
router.put('/:booking_uuid/actual-distance', authMiddleware, updateActualDistance);
router.post('/trip-start-price', authMiddleware, calculateTripStartPrice);
router.post('/check-tolerance', authMiddleware, checkTolerance);
router.post('/check-driver-proximity', authMiddleware, checkAllBookings);
module.exports = router;
