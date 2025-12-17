const db = require('../config/postgresClient');
const staticVehicles = require('../data/staticVehicles');
const myBookingsService = require('../services/myBookingsService');
const normalizeString = (value) => (typeof value === 'string' ? value.trim().toLowerCase() : '');
const STATIC_VEHICLE_MAP = (() => {
const byId = new Map();
const byName = new Map();
for (const vehicle of staticVehicles) {
if (vehicle.id) {
byId.set(vehicle.id, vehicle);
}
if (vehicle.name) {
byName.set(vehicle.name.toLowerCase(), vehicle);
}
}
return { byId, byName };
})();
const DEFAULT_MAKE_IMAGE =
staticVehicles.find((vehicle) => vehicle?.imageUrl)?.imageUrl ||
`${process.env.CDN_URL || 'https://cdn.trevel.app'}/assets/vehicle-placeholder.png`;
const resolveMakeImage = (record) => {
if (record.make_image_url) {
return record.make_image_url;
}
const makeId = record.make_id;
if (makeId && STATIC_VEHICLE_MAP.byId.has(makeId)) {
return STATIC_VEHICLE_MAP.byId.get(makeId).imageUrl || DEFAULT_MAKE_IMAGE;
}
const normalizedLabel = normalizeString(record.make_selected || record.vehicle_model);
if (normalizedLabel && STATIC_VEHICLE_MAP.byName.has(normalizedLabel)) {
return STATIC_VEHICLE_MAP.byName.get(normalizedLabel).imageUrl || DEFAULT_MAKE_IMAGE;
}
return DEFAULT_MAKE_IMAGE;
};

const BOOKING_SOURCES = [
{
type: 'mini_trip',
label: 'Mini Trip',
table: 'mini_trip_bookings',
dropoffField: 'dropoff_location'
},
{
type: 'hourly_rental',
label: 'Hourly Rental',
table: 'hourly_rental_bookings',
dropoffField: null
},
{
type: 'to_airport',
label: 'To Airport',
table: 'to_airport_transfer_bookings',
dropoffField: 'destination_airport'
},
{
type: 'from_airport',
label: 'From Airport',
table: 'from_airport_transfer_bookings',
dropoffField: 'destination_airport'
}
];
const toShortNumericId = (uuid) => {
if (!uuid) return null;
const cleaned = uuid.replace(/-/g, '');
const segment = cleaned.slice(0, 8);
const num = parseInt(segment, 16);
return Number.isNaN(num) ? null : num;
};
const deriveOtpFromUuid = (uuid) => {
const shortId = toShortNumericId(uuid);
if (shortId === null) return null;
return String(shortId).slice(-4).padStart(4, '0');
};
const formatDateForResponse = (value) => {
if (!value) return null;
const date = new Date(value);
if (Number.isNaN(date.getTime())) return value;
const day = String(date.getUTCDate()).padStart(2, '0');
const month = String(date.getUTCMonth() + 1).padStart(2, '0');
const year = date.getUTCFullYear();
return `${day}-${month}-${year}`;
};
const combineDateTime = (dateValue, timeValue) => {
if (!dateValue) return null;
const datePart =
typeof dateValue === 'string' ? dateValue : new Date(dateValue).toISOString().slice(0, 10);
if (!timeValue) {
return `${datePart}T00:00:00.000Z`;
}
const timeString = typeof timeValue === 'string' ? timeValue : timeValue.toString();
return `${datePart}T${timeString}`;
};
const timeToMinutes = (timeValue) => {
if (!timeValue) return null;
if (typeof timeValue === 'number') return Math.trunc(timeValue);
const [h = '0', m = '0', s = '0'] = String(timeValue).split(':');
const hours = Number(h);
const minutes = Number(m);
const seconds = Number(s);
if ([hours, minutes, seconds].some((n) => Number.isNaN(n))) return null;
return hours * 60 + minutes + Math.floor(seconds / 60);
};
const normalizeStatusLabel = (status) => (status ? status.toUpperCase() : 'PENDING');
const buildLocations = (record, source) => {
const pickup = {
location: record.pickup_location,
city: record.pickup_city,
state: record.pickup_state,
datetime: combineDateTime(record.pickup_date, record.pickup_time),
date: formatDateForResponse(record.pickup_date),
time: record.pickup_time
};
let dropoffLocation = null;
let dropoffCity = null;
let dropoffState = null;
if (source.type === 'mini_trip') {
dropoffLocation = record.dropoff_location;
dropoffCity = record.dropoff_city;
dropoffState = record.dropoff_state;
} else if (source.type === 'hourly_rental') {
dropoffLocation = record.notes || 'Hourly rental itinerary';
} else if (source.type === 'to_airport') {
dropoffLocation = record.destination_airport;
} else if (source.type === 'from_airport') {
dropoffLocation = record.destination_airport;
}
const dropoff = dropoffLocation
? { location: dropoffLocation, city: dropoffCity, state: dropoffState }
: null;
return { pickup, dropoff };
};
const mapBookingRecord = (record, source) => {
const { pickup, dropoff } = buildLocations(record, source);
const estimatedMinutes = timeToMinutes(record.estimated_time_min);
return {
id: toShortNumericId(record.id),
booking_uuid: record.id,
ride_type: source.type,
ride_label: source.label,
status: record.status || 'pending',
status_label: normalizeStatusLabel(record.status),
otp_code: record.otp_code || deriveOtpFromUuid(record.id),
pickup,
dropoff,
passenger: {
name: record.passenger_name,
phone: record.passenger_phone,
email: record.passenger_email
},
fare: {
currency: record.currency || 'INR',
base_price: record.base_price,
gst_amount: record.gst_amount,
final_price: record.final_price
},
make: {
id: record.make_id,
label: record.make_selected || record.vehicle_model || null,
model: record.vehicle_model || null,
number_plate: record.vehicle_number_plate || null,
image_url: resolveMakeImage(record),
driver_name: record.driver_name || null,
driver_phone: record.driver_phone || null
},
estimated_distance_km: record.estimated_distance_km,
estimated_time_minutes: estimatedMinutes,
eta_minutes: estimatedMinutes,
created_at: record.created_at,
updated_at: record.updated_at,
notes: record.notes || null
};
};
const fetchBookingsFromSource = async (source, userId, status) => {
  try {
    const rows = await myBookingsService.fetchBookingsFromSource(db, source, userId, status);
    return rows.map((row) => mapBookingRecord(row, source));
  } catch (error) {
    console.error(`Error fetching bookings from ${source.table}:`, error);
    // Return empty array instead of throwing to prevent 500 errors
    return [];
  }
};
const getMyBookings = async (req, res) => {
try {
const userId = req.user?.id;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized',
message: 'User authentication required'
});
}
let { status, limit = '20', page = '1' } = req.query;
const normalizedStatus = typeof status === 'string' && status.toLowerCase() === 'all' ? null : status;
const limitIsAll = typeof limit === 'string' && limit.toLowerCase() === 'all';
const numericLimit = limitIsAll ? null : Math.min(100, Math.max(1, Number(limit) || 20));
const numericPage = limitIsAll ? 1 : Math.max(1, Number(page) || 1);
const resultsPerSource = await Promise.all(
BOOKING_SOURCES.map((source) => fetchBookingsFromSource(source, userId, normalizedStatus))
);
const combined = resultsPerSource.flat();
combined.sort((a, b) => {
const dateA = new Date(a.pickup.datetime || 0).getTime();
const dateB = new Date(b.pickup.datetime || 0).getTime();
return dateB - dateA;
});
const paginated = numericLimit
? combined.slice((numericPage - 1) * numericLimit, (numericPage - 1) * numericLimit + numericLimit)
: combined;
res.status(200).json({
success: true,
count: combined.length,
page: numericPage,
page_size: numericLimit,
data: paginated
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to fetch bookings',
message: error.message,
...(process.env.NODE_ENV === 'development' && { stack: error.stack })
});
}
};
const fetchBookingById = async (source, bookingId, userId) => {

const row = await myBookingsService.fetchBookingById(db, source, bookingId, userId);
if (!row) {
return null;
}
return mapBookingRecord(row, source);
};
const getMyBookingById = async (req, res) => {
try {
const userId = req.user?.id;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized',
message: 'User authentication required'
});
}
const { id } = req.params;
for (const source of BOOKING_SOURCES) {
const booking = await fetchBookingById(source, id, userId);
if (booking) {
return res.status(200).json({
success: true,
data: booking
});
}
}
res.status(404).json({
success: false,
error: 'Booking not found'
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to fetch booking details',
message: error.message
});
}
};
const getUpcomingRides = async (req, res) => {
try {
const userId = req.user?.id;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized',
message: 'User authentication required'
});
}
const now = new Date();
const sevenDaysFromNow = new Date(now);
sevenDaysFromNow.setDate(sevenDaysFromNow.getDate() + 7);
const fortyEightHoursFromNow = new Date(now);
fortyEightHoursFromNow.setHours(fortyEightHoursFromNow.getHours() + 48);
const nowStr = now.toISOString().split('T')[0];
const sevenDaysStr = sevenDaysFromNow.toISOString().split('T')[0];

const resultsPerSource = await Promise.all(
BOOKING_SOURCES.map(async (source) => {
const rows = await myBookingsService.fetchUpcomingRidesFromSource(db, source, userId, nowStr, sevenDaysStr);
return rows.map((row) => mapBookingRecord(row, source));
})
);
const combined = resultsPerSource.flat();
const upcoming = combined
.filter((booking) => {
const status = (booking.status || '').toLowerCase();
const isActiveRide = ['in_progress', 'assigned', 'searching', 'accepted'].includes(status);
if (isActiveRide) return true;
if (!booking.pickup?.datetime) return false;
const pickupDate = new Date(booking.pickup.datetime);
return pickupDate >= now && pickupDate <= sevenDaysFromNow;
})
.sort((a, b) => {
const statusA = (a.status || '').toLowerCase();
const statusB = (b.status || '').toLowerCase();
const isActiveA = ['in_progress', 'assigned', 'searching', 'accepted'].includes(statusA);
const isActiveB = ['in_progress', 'assigned', 'searching', 'accepted'].includes(statusB);
if (isActiveA && !isActiveB) return -1;
if (!isActiveA && isActiveB) return 1;
const dateA = new Date(a.pickup?.datetime || 0).getTime();
const dateB = new Date(b.pickup?.datetime || 0).getTime();
return dateA - dateB;
});
const needsReminder = upcoming.filter((booking) => {
if (!booking.pickup?.datetime) return false;
const pickupDate = new Date(booking.pickup.datetime);
return pickupDate >= now && pickupDate <= fortyEightHoursFromNow;
});
res.status(200).json({
success: true,
count: upcoming.length,
needs_reminder_count: needsReminder.length,
data: upcoming,
needs_reminder: needsReminder
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to fetch upcoming rides',
message: error.message
});
}
};
module.exports = {
getMyBookings,
getMyBookingById,
getUpcomingRides,
BOOKING_SOURCES,
fetchBookingById,
mapBookingRecord
};
