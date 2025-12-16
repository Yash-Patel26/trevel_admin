const db = require('../config/postgresClient');
const { BOOKING_SOURCES, fetchBookingById, mapBookingRecord } = require('./myBookingsController');
const { createNotification } = require('./notificationController');
const bookingManagementService = require('../services/bookingManagementService');
const createBooking = async (req, res) => {
try {
const userId = req.user?.id;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized',
message: 'User authentication required. Please provide a valid token from /api/auth/verify-otp'
});
}

const { trip_type } = req.body;
if (!trip_type) {
return res.status(400).json({
success: false,
error: 'Missing trip_type',
message: 'trip_type is required in request body. Valid values: mini, hourly, to_airport, from_airport'
});
}

if (trip_type === 'mini' || trip_type === 'mini_trip') {
const miniTripController = require('./miniTripController');
return miniTripController.createMiniTripBooking(req, res);
} else if (trip_type === 'hourly' || trip_type === 'hourly_rental') {
const hourlyRentalController = require('./hourlyRentalController');
return hourlyRentalController.createHourlyRentalBooking(req, res);
} else if (trip_type === 'to_airport' || trip_type === 'airport_to') {
const airportController = require('./airportTransferController');
return airportController.createToAirportTransferBooking(req, res);
} else if (trip_type === 'from_airport' || trip_type === 'airport_from') {
const airportController = require('./airportTransferController');
return airportController.createFromAirportTransferBooking(req, res);
} else {
return res.status(400).json({
success: false,
error: 'Invalid trip_type',
message: `trip_type "${trip_type}" is not valid. Must be one of: mini, hourly, to_airport, from_airport`
});
}
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to create booking',
message: error.message || 'An unexpected error occurred while creating the booking'
});
}
};
const cancelBooking = async (req, res) => {
try {
const userId = req.user?.id;
const { id } = req.params;
const { reason } = req.body;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized'
});
}
const result = await bookingManagementService.findBookingById(db, id, userId);
if (!result) {
return res.status(404).json({
success: false,
error: 'Booking not found'
});
}
const { source } = result;
try {
const bookingData = await bookingManagementService.cancelBooking(db, id, userId, reason);
await createNotification(
userId,
'Booking Cancelled',
`Your ${source.label} booking has been cancelled.`,
'booking',
id
);
return res.status(200).json({
success: true,
message: 'Booking cancelled successfully',
data: bookingData
});
} catch (error) {
return res.status(400).json({
success: false,
error: 'Cannot cancel booking',
message: error.message
});
}
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to cancel booking',
message: error.message
});
}
};
const updateBooking = async (req, res) => {
try {
const userId = req.user?.id;
const { id } = req.params;
const { pickup_date, pickup_time, pickup, dropoff } = req.body;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized'
});
}
const result = await bookingManagementService.findBookingById(db, id, userId);
if (!result) {
return res.status(404).json({
success: false,
error: 'Booking not found'
});
}
const { source } = result;

// Validate pickup time if provided (must be at least 2 hours from now)
if (pickup_date && pickup_time) {
  const pickupTimeValidator = require('../utils/pickupTimeValidator');
  
  // Format date and time for validation
  const formatDateForStorage = (value) => {
    if (!value) return null;
    const trimmed = value.trim();
    const ddmmyyyy = /^(\d{2})-(\d{2})-(\d{4})$/;
    const ymd = /^(\d{4})-(\d{2})-(\d{2})$/;
    if (ddmmyyyy.test(trimmed)) {
      const [, dd, mm, yyyy] = trimmed.match(ddmmyyyy);
      return `${yyyy}-${mm}-${dd}`;
    }
    if (ymd.test(trimmed)) return trimmed;
    return trimmed;
  };
  
  const formattedDate = formatDateForStorage(pickup_date);
  const timeValidation = pickupTimeValidator.validatePickupTime(formattedDate, pickup_time, 2);
  if (!timeValidation.valid) {
    return res.status(400).json({
      success: false,
      error: 'Invalid pickup time',
      message: timeValidation.error
    });
  }
}

try {
const bookingData = await bookingManagementService.updateBooking(db, id, userId, {
pickup_date,
pickup_time,
pickup,
dropoff
});
await createNotification(
userId,
'Booking Updated',
`Your ${source.label} booking has been updated.`,
'booking',
id
);
return res.status(200).json({
success: true,
message: 'Booking updated successfully',
data: bookingData
});
} catch (error) {
return res.status(400).json({
success: false,
error: 'Cannot update booking',
message: error.message
});
}
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to update booking',
message: error.message
});
}
};
const getBookingDriver = async (req, res) => {
try {
const userId = req.user?.id;
const { id } = req.params;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized'
});
}

const driverData = await bookingManagementService.getBookingDriver(db, id, userId);
if (!driverData) {
return res.status(200).json({
success: true,
message: 'No driver assigned yet',
data: null
});
}
res.status(200).json({
success: true,
data: driverData
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to fetch driver details',
message: error.message
});
}
};
const getBookingStatus = async (req, res) => {
try {
const userId = req.user?.id;
const { id } = req.params;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized'
});
}
const booking = await fetchBookingById(BOOKING_SOURCES[0], id, userId) ||
await fetchBookingById(BOOKING_SOURCES[1], id, userId) ||
await fetchBookingById(BOOKING_SOURCES[2], id, userId) ||
await fetchBookingById(BOOKING_SOURCES[3], id, userId);
if (!booking) {
return res.status(404).json({
success: false,
error: 'Booking not found'
});
}
res.status(200).json({
success: true,
data: {
status: booking.status,
status_label: booking.status_label,
booking_uuid: booking.booking_uuid,
ride_type: booking.ride_type
}
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to fetch booking status',
message: error.message
});
}
};
const getLiveLocation = async (req, res) => {
try {
const userId = req.user?.id;
const { id } = req.params;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized'
});
}

const vehicleId = await bookingManagementService.getBookingVehicleId(db, id, userId);
if (!vehicleId) {
return res.status(404).json({
success: false,
error: 'Booking or vehicle not found'
});
}
const tracking = await bookingManagementService.getLiveLocation(db, vehicleId);
if (!tracking) {
return res.status(200).json({
success: true,
message: 'Live location not available',
data: null
});
}
res.status(200).json({
success: true,
data: tracking
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to fetch live location',
message: error.message
});
}
};
const callDriver = async (req, res) => {
try {
const userId = req.user?.id;
const { id } = req.params;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized'
});
}

const driverPhone = await bookingManagementService.getDriverPhone(db, id, userId);
if (!driverPhone) {
return res.status(404).json({
success: false,
error: 'Driver not found or not assigned'
});
}
res.status(200).json({
success: true,
message: 'Call initiated',
data: {
driver_phone: driverPhone,
call_id: `call_${Date.now()}`
}
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to call driver',
message: error.message
});
}
};
const shareRide = async (req, res) => {
try {
const userId = req.user?.id;
const { id } = req.params;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized'
});
}
const booking = await fetchBookingById(BOOKING_SOURCES[0], id, userId) ||
await fetchBookingById(BOOKING_SOURCES[1], id, userId) ||
await fetchBookingById(BOOKING_SOURCES[2], id, userId) ||
await fetchBookingById(BOOKING_SOURCES[3], id, userId);
if (!booking) {
return res.status(404).json({
success: false,
error: 'Booking not found'
});
}
const shareLink = `${process.env.FRONTEND_URL}/share/ride/${id}`;
res.status(200).json({
success: true,
data: {
share_link: shareLink,
booking_id: id,
message: `Track my ride: ${shareLink}`
}
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to share ride',
message: error.message
});
}
};
const changeRoute = async (req, res) => {
try {
const userId = req.user?.id;
const { id } = req.params;
const { new_dropoff } = req.body;
if (!userId || !new_dropoff) {
return res.status(400).json({
success: false,
error: 'Missing required fields'
});
}

try {
const bookingData = await bookingManagementService.changeRoute(db, id, userId, new_dropoff);
return res.status(200).json({
success: true,
message: 'Route updated successfully',
data: bookingData
});
} catch (error) {
if (error.message.includes('not found')) {
return res.status(404).json({
success: false,
error: 'Booking not found'
});
}
return res.status(400).json({
success: false,
error: 'Cannot change route',
message: error.message
});
}
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to change route',
message: error.message
});
}
};
const getWaitingTime = async (req, res) => {
try {
const userId = req.user?.id;
const { id } = req.params;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized'
});
}
const booking = await fetchBookingById(BOOKING_SOURCES[0], id, userId) ||
await fetchBookingById(BOOKING_SOURCES[1], id, userId) ||
await fetchBookingById(BOOKING_SOURCES[2], id, userId) ||
await fetchBookingById(BOOKING_SOURCES[3], id, userId);
if (!booking) {
return res.status(404).json({
success: false,
error: 'Booking not found'
});
}
const estimatedMinutes = booking.estimated_time_minutes || 15;
res.status(200).json({
success: true,
data: {
estimated_waiting_time_minutes: estimatedMinutes,
estimated_arrival: new Date(Date.now() + estimatedMinutes * 60000).toISOString()
}
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to fetch waiting time',
message: error.message
});
}
};
const downloadReceipt = async (req, res) => {
try {
const userId = req.user?.id;
const { id } = req.params;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized'
});
}
const booking = await fetchBookingById(BOOKING_SOURCES[0], id, userId) ||
await fetchBookingById(BOOKING_SOURCES[1], id, userId) ||
await fetchBookingById(BOOKING_SOURCES[2], id, userId) ||
await fetchBookingById(BOOKING_SOURCES[3], id, userId);
if (!booking) {
return res.status(404).json({
success: false,
error: 'Booking not found'
});
}
const receiptData = {
booking_id: booking.id,
booking_uuid: booking.booking_uuid,
ride_type: booking.ride_type,
status: booking.status,
pickup: booking.pickup,
dropoff: booking.dropoff,
passenger: booking.passenger,
fare: booking.fare,
vehicle: booking.vehicle,
created_at: booking.created_at,
receipt_url: `${process.env.API_URL}/api/bookings/${id}/receipt/pdf`
};
res.status(200).json({
success: true,
data: receiptData
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to generate receipt',
message: error.message
});
}
};
const rebookRide = async (req, res) => {
try {
const userId = req.user?.id;
const { previous_booking_id, pickup_date, pickup_time } = req.body;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized'
});
}

const result = await bookingManagementService.getPreviousBooking(db, previous_booking_id, userId);
if (!result) {
return res.status(404).json({
success: false,
error: 'Previous booking not found'
});
}
const { booking: previousBooking, source: bookingSource } = result;
const newBookingData = {
...req.body,
trip_type: bookingSource.type === 'mini_trip' ? 'mini' :
bookingSource.type === 'hourly_rental' ? 'hourly' :
bookingSource.type === 'to_airport' ? 'to_airport' : 'from_airport',
pickup: {
location: previousBooking.pickup_location,
city: previousBooking.pickup_city,
state: previousBooking.pickup_state
},
dropoff: bookingSource.type === 'mini_trip' ? {
location: previousBooking.dropoff_location,
city: previousBooking.dropoff_city,
state: previousBooking.dropoff_state
} : bookingSource.type === 'to_airport' || bookingSource.type === 'from_airport' ? {
location: previousBooking.destination_airport
} : undefined
};
req.body = newBookingData;
return createBooking(req, res);
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to rebook ride',
message: error.message
});
}
};
const getBooking = async (req, res) => {
try {
const { id } = req.params;
const userId = req.user?.id;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized'
});
}
const booking = await fetchBookingById(id, userId);
if (!booking) {
return res.status(404).json({
success: false,
error: 'Booking not found'
});
}
return res.status(200).json({
success: true,
data: booking
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to get booking',
message: error.message
});
}
};
const getBookings = async (req, res) => {
try {
const userId = req.user?.id;
const { status } = req.query;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized'
});
}
const myBookingsController = require('./myBookingsController');
return myBookingsController.getMyBookings(req, res);
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to get bookings',
message: error.message
});
}
};

const updateBookingStatus = async (req, res) => {
try {
const userId = req.user?.id;
const { id } = req.params;
const { status } = req.body;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized',
message: 'User authentication required'
});
}
if (!status) {
return res.status(400).json({
success: false,
error: 'Missing status',
message: 'status is required in request body'
});
}

const validStatuses = ['pending', 'confirmed', 'assigned', 'in_progress', 'searching', 'accepted', 'completed', 'cancelled'];
const normalizedStatus = status.toLowerCase().replace('-', '_');
if (!validStatuses.includes(normalizedStatus)) {
return res.status(400).json({
success: false,
error: 'Invalid status',
message: `Status must be one of: ${validStatuses.join(', ')}`
});
}

try {
const result = await bookingManagementService.updateBookingStatus(db, id, userId, normalizedStatus);
if (!result) {
return res.status(404).json({
success: false,
error: 'Booking not found',
message: 'Booking not found or you do not have permission to update it'
});
}
const { booking: updatedBooking, source: bookingSource } = result;

await createNotification(
userId,
'Booking Status Updated',
`Your ${bookingSource.label} booking status has been updated to ${normalizedStatus}.`,
'booking',
id
);
return res.status(200).json({
success: true,
message: 'Booking status updated successfully',
data: mapBookingRecord(updatedBooking, bookingSource)
});
} catch (error) {
return res.status(400).json({
success: false,
error: 'Cannot update status',
message: error.message
});
}
} catch (error) {
return res.status(500).json({
success: false,
error: 'Failed to update booking status',
message: error.message
});
}
};

module.exports = {
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
};
