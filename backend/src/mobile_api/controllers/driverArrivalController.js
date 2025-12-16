const { checkBookingDriverProximity, checkAllActiveBookings } = require('../services/driverArrivalNotificationService');
const checkDriverProximity = async (req, res) => {
try {
const userId = req.user?.id;
const { id } = req.params;

if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized',
message: 'User authentication required'
});
}

const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
if (!uuidRegex.test(id)) {
return res.status(400).json({
success: false,
error: 'Invalid booking ID format',
message: 'Booking ID must be in UUID format. Use booking_uuid from the booking response.'
});
}
const result = await checkBookingDriverProximity(id, userId);
if (result.error) {
return res.status(400).json({
success: false,
error: result.error,
message: result.error
});
}
return res.status(200).json({
success: true,
data: result
});
} catch (error) {
return res.status(500).json({
success: false,
error: 'Failed to check driver proximity',
message: error.message
});
}
};
const checkAllBookings = async (req, res) => {
try {
const result = await checkAllActiveBookings();
if (result.error) {
return res.status(500).json({
success: false,
error: result.error
});
}
return res.status(200).json({
success: true,
data: result
});
} catch (error) {
return res.status(500).json({
success: false,
error: 'Failed to check bookings',
message: error.message
});
}
};
module.exports = {
checkDriverProximity,
checkAllBookings
};
