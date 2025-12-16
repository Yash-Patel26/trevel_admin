const { createNotification } = require('../controllers/notificationController');
function calculateDistanceMeters(lat1, lon1, lat2, lon2) {
const R = 6371e3;
const φ1 = (lat1 * Math.PI) / 180;
const φ2 = (lat2 * Math.PI) / 180;
const Δφ = ((lat2 - lat1) * Math.PI) / 180;
const Δλ = ((lon2 - lon1) * Math.PI) / 180;
const a =
Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
return R * c;
}
async function checkDriverProximity(db, bookingId, bookingType, driverLat, driverLng) {
try {
const bookingTables = {
mini_trip: 'mini_trip_bookings',
hourly_rental: 'hourly_rental_bookings',
to_airport: 'to_airport_transfer_bookings',
from_airport: 'from_airport_transfer_bookings'
};
const tableName = bookingTables[bookingType];
if (!tableName) {
throw new Error(`Invalid booking type: ${bookingType}`);
}
const { rows: bookings } = await db.query(
`SELECT
id,
user_id,
make_id,
pickup_location,
status,
pickup_latitude,
pickup_longitude
FROM ${tableName}
WHERE id = $1`,
[bookingId]
);
if (bookings.length === 0) {
return { error: 'Booking not found' };
}
const booking = bookings[0];
const activeStatuses = ['assigned', 'confirmed', 'in_progress', 'searching'];
if (!activeStatuses.includes(booking.status?.toLowerCase())) {
return { error: 'Booking not in active state' };
}
let pickupLat = booking.pickup_latitude;
let pickupLng = booking.pickup_longitude;
if (!pickupLat || !pickupLng) {
return { error: 'Pickup coordinates not available' };
}
const distanceMeters = calculateDistanceMeters(
parseFloat(pickupLat),
parseFloat(pickupLng),
parseFloat(driverLat),
parseFloat(driverLng)
);
const { rows: existingNotifications } = await db.query(
`SELECT type, metadata
FROM notifications
WHERE user_id = $1
AND related_booking_id = $2
AND type IN ('driver_arriving', 'driver_arrived')
AND created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 2`,
[booking.user_id, bookingId]
);
const hasArrivingNotification = existingNotifications.some(n => n.type === 'driver_arriving');
const hasArrivedNotification = existingNotifications.some(n => n.type === 'driver_arrived');
let notificationSent = false;
let notificationType = null;
if (distanceMeters <= 10 && !hasArrivedNotification) {
await createNotification(
booking.user_id,
'Driver Arrived',
'Your driver has arrived at the pickup location. Please proceed to the vehicle.',
'driver_arrived',
bookingId,
{
booking_id: bookingId,
booking_type: bookingType,
distance_meters: Math.round(distanceMeters),
driver_latitude: driverLat,
driver_longitude: driverLng,
pickup_latitude: pickupLat,
pickup_longitude: pickupLng
}
);
notificationSent = true;
notificationType = 'driver_arrived';
}
else if (distanceMeters <= 50 && distanceMeters > 10 && !hasArrivingNotification && !hasArrivedNotification) {
await createNotification(
booking.user_id,
'Driver Arriving',
`Your driver is arriving soon! They are approximately ${Math.round(distanceMeters)} meters away from your pickup location.`,
'driver_arriving',
bookingId,
{
booking_id: bookingId,
booking_type: bookingType,
distance_meters: Math.round(distanceMeters),
driver_latitude: driverLat,
driver_longitude: driverLng,
pickup_latitude: pickupLat,
pickup_longitude: pickupLng
}
);
notificationSent = true;
notificationType = 'driver_arriving';
}
return {
success: true,
distance_meters: Math.round(distanceMeters),
distance_km: (distanceMeters / 1000).toFixed(2),
notification_sent: notificationSent,
notification_type: notificationType,
driver_latitude: driverLat,
driver_longitude: driverLng,
pickup_latitude: pickupLat,
pickup_longitude: pickupLng
};
} catch (error) {
return { error: error.message };
}
}
async function checkAllActiveBookings(db) {
try {
const activeBookings = [];
const { rows: miniTrips } = await db.query(
`SELECT id, user_id, make_id, status, pickup_latitude, pickup_longitude
FROM mini_trip_bookings
WHERE status IN ('assigned', 'confirmed', 'in_progress', 'searching')
AND make_id IS NOT NULL
AND pickup_latitude IS NOT NULL
AND pickup_longitude IS NOT NULL`
);
miniTrips.forEach(booking => {
activeBookings.push({ ...booking, type: 'mini_trip' });
});
const { rows: hourlyRentals } = await db.query(
`SELECT id, user_id, make_id, status, pickup_latitude, pickup_longitude
FROM hourly_rental_bookings
WHERE status IN ('assigned', 'confirmed', 'in_progress', 'searching')
AND make_id IS NOT NULL
AND pickup_latitude IS NOT NULL
AND pickup_longitude IS NOT NULL`
);
hourlyRentals.forEach(booking => {
activeBookings.push({ ...booking, type: 'hourly_rental' });
});
const { rows: toAirport } = await db.query(
`SELECT id, user_id, make_id, status, pickup_latitude, pickup_longitude
FROM to_airport_transfer_bookings
WHERE status IN ('assigned', 'confirmed', 'in_progress', 'searching')
AND make_id IS NOT NULL
AND pickup_latitude IS NOT NULL
AND pickup_longitude IS NOT NULL`
);
toAirport.forEach(booking => {
activeBookings.push({ ...booking, type: 'to_airport' });
});
const { rows: fromAirport } = await db.query(
`SELECT id, user_id, make_id, status, pickup_latitude, pickup_longitude
FROM from_airport_transfer_bookings
WHERE status IN ('assigned', 'confirmed', 'in_progress', 'searching')
AND make_id IS NOT NULL
AND pickup_latitude IS NOT NULL
AND pickup_longitude IS NOT NULL`
);
fromAirport.forEach(booking => {
activeBookings.push({ ...booking, type: 'from_airport' });
});
for (const booking of activeBookings) {
try {
const { rows: vehicles } = await db.query(
`SELECT current_latitude, current_longitude
FROM makes
WHERE id = $1
AND current_latitude IS NOT NULL
AND current_longitude IS NOT NULL`,
[booking.make_id]
);
if (vehicles.length === 0) {
continue;
}
const vehicle = vehicles[0];
const driverLat = parseFloat(vehicle.current_latitude);
const driverLng = parseFloat(vehicle.current_longitude);
if (isNaN(driverLat) || isNaN(driverLng)) {
continue;
}
await checkDriverProximity(
db,
booking.id,
booking.type,
driverLat,
driverLng
);
} catch (error) {
}
}
return {
success: true,
checked: activeBookings.length,
message: `Checked ${activeBookings.length} active bookings`
};
} catch (error) {
return { error: error.message };
}
}
async function checkBookingDriverProximity(db, bookingId, userId) {
try {

const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
if (!uuidRegex.test(bookingId)) {
return { error: 'Invalid booking ID format. Expected UUID format. Use booking_uuid from the booking response.' };
}

const bookingSources = [
{ table: 'mini_trip_bookings', type: 'mini_trip' },
{ table: 'hourly_rental_bookings', type: 'hourly_rental' },
{ table: 'to_airport_transfer_bookings', type: 'to_airport' },
{ table: 'from_airport_transfer_bookings', type: 'from_airport' }
];
let booking = null;
let bookingType = null;

for (const source of bookingSources) {

const { rows } = await db.query(
`SELECT id, user_id, make_id, status, pickup_latitude, pickup_longitude
FROM ${source.table}
WHERE id = $1 AND user_id = $2`,
[bookingId, userId]
);
if (rows.length > 0) {
booking = rows[0];
bookingType = source.type;
break;
}
}
if (!booking) {
return { error: 'Booking not found' };
}
if (!booking.make_id) {
return { error: 'No vehicle assigned to this booking' };
}
if (!booking.pickup_latitude || !booking.pickup_longitude) {
return { error: 'Pickup location coordinates not available' };
}
const { rows: vehicles } = await db.query(
`SELECT current_latitude, current_longitude
FROM makes
WHERE id = $1`,
[booking.make_id]
);
if (vehicles.length === 0) {
return { error: 'Vehicle not found' };
}
const vehicle = vehicles[0];
if (!vehicle.current_latitude || !vehicle.current_longitude) {
return { error: 'Driver location not available' };
}
const driverLat = parseFloat(vehicle.current_latitude);
const driverLng = parseFloat(vehicle.current_longitude);
if (isNaN(driverLat) || isNaN(driverLng)) {
return { error: 'Invalid driver coordinates' };
}
const result = await checkDriverProximity(
db,
bookingId,
bookingType,
driverLat,
driverLng
);
return result;
} catch (error) {
return { error: error.message };
}
}
module.exports = {
checkDriverProximity,
checkAllActiveBookings,
checkBookingDriverProximity,
calculateDistanceMeters
};
