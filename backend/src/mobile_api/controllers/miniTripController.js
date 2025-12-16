const db = require('../config/postgresClient');
const crypto = require('crypto');
const miniTripService = require('../services/miniTripService');
const pricingService = require('../services/pricingService');
const googleMapsService = require('../services/googleMapsService');
const parseNumber = (value) => {
if (value === undefined || value === null || value === '') return null;
const num = Number(value);
return Number.isNaN(num) ? null : num;
};
const ensureNumber = (value, label) => {
const parsed = parseNumber(value);
if (parsed === null) {
throw new Error(`${label} must be a valid number`);
}
return parsed;
};
const parseDurationToMinutes = (value) => {
if (value === undefined || value === null || value === '') return null;
if (typeof value === 'number' && Number.isFinite(value)) return Math.trunc(value);
const trimmed = String(value).trim();
if (/^\d+:\d+(:\d+)?$/.test(trimmed)) {
const [h = '0', m = '0', s = '0'] = trimmed.split(':');
const hours = Number(h);
const minutes = Number(m);
const seconds = Number(s);
if ([hours, minutes, seconds].some((n) => Number.isNaN(n))) return null;
return hours * 60 + minutes + Math.floor(seconds / 60);
}
const numericPortion = trimmed.replace(/[^0-9.]/g, '');
if (!numericPortion) return null;
const numeric = Number(numericPortion);
if (Number.isNaN(numeric)) return null;
return Math.trunc(numeric);
};
const minutesToHHMMSS = (minutes) => {
if (minutes === null || minutes === undefined) return null;
const total = Math.max(0, Number(minutes) || 0);
const h = Math.floor(total / 60);
const m = total % 60;
return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:00`;
};
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
const formatDateForResponse = (value) => {
if (!value) return null;
const date = new Date(value);
if (Number.isNaN(date.getTime())) return value;
const day = String(date.getUTCDate()).padStart(2, '0');
const month = String(date.getUTCMonth() + 1).padStart(2, '0');
const year = date.getUTCFullYear();
return `${day}-${month}-${year}`;
};
const formatTimeForStorage = (value) => {
if (!value) return null;
const trimmed = String(value).trim();
const amPmMatch = /^(\d{1,2}):(\d{2})\s?(AM|PM)$/i.exec(trimmed);
if (amPmMatch) {
let [, hourStr, minuteStr, suffix] = amPmMatch;
let hour = Number(hourStr);
const minutes = Number(minuteStr);
const isPm = suffix.toUpperCase() === 'PM';
if (hour === 12) {
hour = isPm ? 12 : 0;
} else if (isPm) {
hour += 12;
}
return `${String(hour).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:00`;
}
if (/^\d{2}:\d{2}$/.test(trimmed)) return `${trimmed}:00`;
if (/^\d{2}:\d{2}:\d{2}$/.test(trimmed)) return trimmed;
return trimmed;
};
const formatTimeForResponse = (value) => {
if (!value) return null;
const match = /^(\d{2}):(\d{2})(?::(\d{2}))?/.exec(value);
if (!match) return value;
const [, hh, mm, ss = '00'] = match;
return `${hh}:${mm}:${ss}`;
};
const toShortNumericId = (uuid) => {
if (!uuid) return null;
const cleaned = uuid.replace(/-/g, '');
const segment = cleaned.slice(0, 8);
const num = parseInt(segment, 16);
return Number.isNaN(num) ? null : num;
};
const normalizePhone = (value) => {
if (!value) return null;
const trimmed = String(value).trim();
const plusPrefixed = trimmed.startsWith('+');
const digitsOnly = trimmed.replace(/[^0-9]/g, '');
return plusPrefixed ? `+${digitsOnly}` : digitsOnly;
};
const resolveUserId = async (reqUser, body, passengerName, passengerPhone, passengerEmail) => {

const providedUserId = reqUser?.id || body.user_id || body.userId;
if (providedUserId) {
return providedUserId;
}

return null;
};
const buildResponsePayload = (record) => ({
id: toShortNumericId(record.id),
booking_uuid: record.id,
user_id: toShortNumericId(record.user_id),
passenger_name: record.passenger_name,
passenger_email: record.passenger_email,
passenger_phone: record.passenger_phone,
pickup_location: record.pickup_location,
pickup_city: record.pickup_city,
pickup_state: record.pickup_state,
dropoff_location: record.dropoff_location,
dropoff_city: record.dropoff_city,
dropoff_state: record.dropoff_state,
pickup_date: formatDateForResponse(record.pickup_date),
pickup_time: formatTimeForResponse(record.pickup_time),
  make_selected: record.make_selected,
  make_image_url: record.make_image_url,
  make_id: record.make_id,
estimated_distance_km: record.estimated_distance_km,
estimated_time_min: formatTimeForResponse(record.estimated_time_min),
base_price: record.base_price,
gst_amount: record.gst_amount,
final_price: record.final_price,
original_final_price: record.original_final_price,
driver_arrival_time: record.driver_arrival_time,
customer_arrival_time: record.customer_arrival_time,
driver_compensation: record.driver_compensation || 0,
customer_late_fee: record.customer_late_fee || 0,
currency: record.currency,
notes: record.notes,
status: record.status,
created_at: record.created_at,
updated_at: record.updated_at
});
const createMiniTripBooking = async (req, res) => {
try {
const body = req.body || {};
const passengerName = body.passenger_name || body.passengerName || '';
const passengerPhone = body.passenger_phone || body.passengerPhone || '';
const passengerEmail = body.passenger_email || body.passengerEmail || '';

const pickupLocation = body.pickup_location || body.pickupLocation ||
  (body.pickup && (body.pickup.address || body.pickup.name || body.pickup.location)) || '';
const dropoffLocation = body.dropoff_location || body.dropoffLocation ||
  (body.dropoff && (body.dropoff.address || body.dropoff.name || body.dropoff.location)) || '';
const pickupDateRaw = body.pickup_date || body.pickupDate;
const pickupTimeRaw = body.pickup_time || body.pickupTime;
const makeSelected = body.make_selected || body.makeSelected || 'Not Specified';
const makeImage = body.make_image_url || body.makeImageUrl || '';
const vehicleLuggage = body.vehicle_luggage || body.vehicleLuggage || '0';
const vehicleCapacity = body.vehicle_capacity || body.vehicleCapacity || '4';
const estimatedDistance = body.estimated_distance_km || body.estimatedDistanceKm || '0';
const estimatedTime = body.estimated_time_min || body.estimatedTimeMin || '0';
const basePrice = body.base_price || body.basePrice || '0';
const gstAmount = body.gst_amount || body.gstAmount || '0';
const finalPrice = body.final_price || body.finalPrice || '0';
const promoCode = body.promo_code || body.promoCode || '';
const promoDiscount = body.promo_discount || body.promoDiscount || 0;
const travellingFor = body.travelling_for || body.travellingFor || 'Myself';
let userId;
try {
userId = await resolveUserId(req.user, body, passengerName, passengerPhone, passengerEmail);
if (!userId) {
return res.status(401).json({
success: false,
error: 'User authentication failed',
message: 'Unable to identify user. Please provide valid user credentials.'
});
}
} catch (error) {
return res.status(500).json({
success: false,
error: 'User resolution error',
message: 'An error occurred while processing your request.'
});
}
const pickupDate = formatDateForStorage(pickupDateRaw);
const pickupTime = formatTimeForStorage(pickupTimeRaw);

// Validate pickup time (must be at least 2 hours from now)
const pickupTimeValidator = require('../utils/pickupTimeValidator');
const timeValidation = pickupTimeValidator.validatePickupTime(pickupDate, pickupTimeRaw || pickupTime, 2);
if (!timeValidation.valid) {
  return res.status(400).json({
    success: false,
    error: 'Invalid pickup time',
    message: timeValidation.error
  });
}

let distanceNumber = parseFloat(estimatedDistance) || 0;
if (distanceNumber <= 0) {

  if (body.pickup && body.dropoff &&
      (body.pickup.lat || body.pickup.latitude) &&
      (body.pickup.lng || body.pickup.longitude) &&
      (body.dropoff.lat || body.dropoff.latitude) &&
      (body.dropoff.lng || body.dropoff.longitude)) {

    try {
      const googleMapsService = require('../services/googleMapsService');
      const pickupCoords = {
        lat: parseFloat(body.pickup.lat || body.pickup.latitude),
        lng: parseFloat(body.pickup.lng || body.pickup.longitude)
      };
      const dropoffCoords = {
        lat: parseFloat(body.dropoff.lat || body.dropoff.latitude),
        lng: parseFloat(body.dropoff.lng || body.dropoff.longitude)
      };

      const R = 6371; // Earth's radius in km
      const dLat = (dropoffCoords.lat - pickupCoords.lat) * Math.PI / 180;
      const dLng = (dropoffCoords.lng - pickupCoords.lng) * Math.PI / 180;
      const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                Math.cos(pickupCoords.lat * Math.PI / 180) * Math.cos(dropoffCoords.lat * Math.PI / 180) *
                Math.sin(dLng/2) * Math.sin(dLng/2);
      const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
      distanceNumber = R * c;
    } catch (error) {

    }
  }
}
let durationMinutes = parseInt(estimatedTime) || 0;
const promoDiscountNumber = parseFloat(promoDiscount) || 0;
if (distanceNumber <= 0) {
return res.status(400).json({
success: false,
error: 'Invalid distance',
message: 'estimated_distance_km must be greater than 0. Please provide distance or valid pickup/dropoff coordinates.'
});
}
durationMinutes = parseDurationToMinutes(estimatedTime);
if (durationMinutes === null) {
return res.status(400).json({
success: false,
error: 'Invalid duration',
message: 'estimated_time_min must be a number of minutes or HH:MM string'
});
}
let calculatedPricing;
try {
calculatedPricing = pricingService.calculateMiniTravelPrice(distanceNumber, pickupTime);
} catch (error) {
return res.status(400).json({
success: false,
error: 'Pricing calculation failed',
message: error.message
});
}
const basePriceNumber = calculatedPricing.basePrice;
const gstNumber = calculatedPricing.gstAmount;
const finalPriceNumber = calculatedPricing.finalPrice;
const clientBasePrice = basePrice ? parseFloat(basePrice) : null;
const clientFinalPrice = finalPrice ? parseFloat(finalPrice) : null;
if (clientBasePrice && Math.abs(clientBasePrice - basePriceNumber) > 0.01) {
}
if (clientFinalPrice && Math.abs(clientFinalPrice - finalPriceNumber) > 0.01) {
}
const bookingId = crypto.randomUUID();
const routePreference = body.route_preference || body.routePreference || 'fastest';
const pickupLat = body.pickup_latitude || body.pickupLatitude ||
(body.pickup && (body.pickup.lat || body.pickup.latitude)) || null;
const pickupLng = body.pickup_longitude || body.pickupLongitude ||
(body.pickup && (body.pickup.lng || body.pickup.longitude)) || null;
const dropoffLat = body.dropoff_latitude || body.dropoffLatitude ||
(body.dropoff && (body.dropoff.lat || body.dropoff.latitude)) || null;
const dropoffLng = body.dropoff_longitude || body.dropoffLongitude ||
(body.dropoff && (body.dropoff.lng || body.dropoff.longitude)) || null;

const insertValues = [
bookingId,
userId,
passengerName.trim(),
passengerEmail ? passengerEmail.trim().toLowerCase() : null,
normalizePhone(passengerPhone),
pickupLocation.trim(),
body.pickup_city || body.pickupCity || null,
body.pickup_state || body.pickupState || null,
dropoffLocation.trim(),
body.dropoff_city || body.dropoffCity || null,
body.dropoff_state || body.dropoffState || null,
pickupDate,
pickupTime,
(() => {
const makeId = body.make_id || body.makeId;
if (makeId) {
const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
if (uuidRegex.test(makeId)) {
return makeId;
} else {
return null;
}
}
return null;
})(),
makeSelected,
makeImage || null,
distanceNumber,
minutesToHHMMSS(durationMinutes),
basePriceNumber,
gstNumber,
finalPriceNumber,
finalPriceNumber,
routePreference,
pickupLat ? parseFloat(pickupLat) : null,
pickupLng ? parseFloat(pickupLng) : null,
dropoffLat ? parseFloat(dropoffLat) : null,
dropoffLng ? parseFloat(dropoffLng) : null,
body.currency || 'INR',
body.status || 'pending',
body.notes || null
];
try {
const bookingRecord = await miniTripService.createBooking(db, { insertValues });
const response = buildResponsePayload(bookingRecord);
return res.status(201).json({
success: true,
message: 'Mini trip booking created successfully',
data: response,
next_steps: [
'Proceed to payment',
'Track your booking status',
'Contact support if needed'
]
});
} catch (error) {

if (error.code === '23505') {
return res.status(409).json({
success: false,
error: 'Duplicate booking',
message: 'A similar booking already exists.'
});
}
if (error.code === '23502') {
return res.status(400).json({
success: false,
error: 'Missing required field',
message: error.message || 'One or more required fields are missing.',
details: process.env.NODE_ENV === 'development' ? error.detail : undefined
});
}
return res.status(500).json({
success: false,
error: 'Database operation failed',
message: 'Failed to create booking. Please try again.',
details: process.env.NODE_ENV === 'development' ? error.message : undefined
});
}
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to create mini trip booking',
message: error.message
});
}
};
const listMiniTripBookings = async (req, res) => {
try {
const { status, pickup_date, pickup_city, limit } = req.query;

const bookings = await miniTripService.listBookings(db, {
status,
pickup_date: pickup_date ? formatDateForStorage(pickup_date) : null,
pickup_city,
limit
});
res.status(200).json({
success: true,
count: bookings.length,
data: bookings.map((record) => buildResponsePayload(record))
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to fetch mini trip bookings',
message: error.message
});
}
};
const getMiniTripBookingById = async (req, res) => {
try {
const { id } = req.params;

const booking = await miniTripService.getBookingById(db, id);
if (!booking) {
return res.status(404).json({
success: false,
error: 'Mini trip booking not found'
});
}
res.status(200).json({
success: true,
data: buildResponsePayload(booking)
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to fetch mini trip booking',
message: error.message
});
}
};
const updateMiniTripArrivalTimes = async (req, res) => {
try {
const { id } = req.params;
const body = req.body || {};
const driverArrivalTimeRaw = body.driver_arrival_time || body.driverArrivalTime;
const customerArrivalTimeRaw = body.customer_arrival_time || body.customerArrivalTime;
if (!driverArrivalTimeRaw && !customerArrivalTimeRaw) {
return res.status(400).json({
success: false,
error: 'Missing arrival times',
message: 'At least one of driver_arrival_time or customer_arrival_time is required'
});
}

const existingBooking = await miniTripService.getBookingForUpdate(db,
id,
'pickup_date, pickup_time, original_final_price, final_price, user_id'
);
if (!existingBooking) {
return res.status(404).json({
success: false,
error: 'Mini trip booking not found'
});
}
const baseFinalPrice = parseFloat(existingBooking.original_final_price) || parseFloat(existingBooking.final_price);
const scheduledDateTime = new Date(`${existingBooking.pickup_date}T${existingBooking.pickup_time}`);
let driverArrivalTime = null;
let customerArrivalTime = null;
if (driverArrivalTimeRaw) {
driverArrivalTime = new Date(driverArrivalTimeRaw);
if (isNaN(driverArrivalTime.getTime())) {
return res.status(400).json({
success: false,
error: 'Invalid driver arrival time',
message: 'driver_arrival_time must be a valid date/time'
});
}
}
if (customerArrivalTimeRaw) {
customerArrivalTime = new Date(customerArrivalTimeRaw);
if (isNaN(customerArrivalTime.getTime())) {
return res.status(400).json({
success: false,
error: 'Invalid customer arrival time',
message: 'customer_arrival_time must be a valid date/time'
});
}
}
const pricingResult = pricingService.calculateMiniTripFinalPrice(
scheduledDateTime,
baseFinalPrice,
driverArrivalTime,
customerArrivalTime
);

let promoCodeData = null;
if (pricingResult.customerCompensation > 0 && existingBooking.user_id) {
try {
const expiresAt = new Date();
expiresAt.setMonth(expiresAt.getMonth() + 3);
promoCodeData = await miniTripService.createCompensationPromoCode(db, {
userId: existingBooking.user_id,
bookingId: id,
amount: pricingResult.customerCompensation,
reason: `Driver compensation for late arrival (${pricingResult.customerCompensationDetails?.delayMinutes || 0} minutes late)`,
expiresAt
});
} catch (error) {

}
}

const updatedBooking = await miniTripService.updateBookingWithArrivalTimes(db, id, {
driverArrivalTime,
customerArrivalTime,
driverCompensation: pricingResult.driverCompensation,
customerLateFee: pricingResult.customerLateFee,
finalPrice: pricingResult.finalPrice,
baseFinalPrice
});
if (!updatedBooking) {
return res.status(404).json({
success: false,
error: 'Failed to update booking'
});
}
const responsePayload = buildResponsePayload(updatedBooking);
res.status(200).json({
success: true,
message: 'Mini trip updated with arrival times and charges',
data: responsePayload,
pricing: {
baseFinalPrice: pricingResult.baseFinalPrice,
driverCompensation: pricingResult.driverCompensation,
customerLateFee: pricingResult.customerLateFee,
customerCompensation: pricingResult.customerCompensation,
finalPrice: pricingResult.finalPrice,
compensationDetails: pricingResult.compensationDetails,
lateFeeDetails: pricingResult.lateFeeDetails,
customerCompensationDetails: pricingResult.customerCompensationDetails
},
promoCode: promoCodeData ? {
code: promoCodeData.code,
amount: parseFloat(promoCodeData.amount),
expiresAt: promoCodeData.expires_at,
message: `You've received a ₹${parseFloat(promoCodeData.amount)} promo code for your next ride!`
} : null
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to update mini trip booking',
message: error.message
});
}
};
const getRoutesForBooking = async (req, res) => {
try {
const { pickup_location, dropoff_location, pickup_date, pickup_time } = req.query;
if (!pickup_location || !dropoff_location) {
return res.status(400).json({
success: false,
error: 'Missing required parameters',
message: 'pickup_location and dropoff_location are required'
});
}
const pickupDateTime = pickup_date && pickup_time
? new Date(`${pickup_date}T${pickup_time}`)
: new Date();
const routes = await googleMapsService.getRoutesWithPricing(
pickup_location,
dropoff_location,
pickupDateTime,
pricingService
);
res.status(200).json({
success: true,
data: {
routes: routes,
pickup_location: pickup_location,
dropoff_location: dropoff_location,
pickup_time: pickupDateTime.toISOString()
}
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to get routes',
message: error.message
});
}
};
const updateRouteAtTripStart = async (req, res) => {
try {
const { id } = req.params;
const body = req.body || {};
const tripStartDistance = parseFloat(body.trip_start_distance || body.tripStartDistance);
const selectedRouteType = body.selected_route_type || body.selectedRouteType || 'fastest';
const acceptPriceChange = body.accept_price_change !== undefined ? body.accept_price_change : true;
const acceptTolls = body.accept_tolls !== undefined ? body.accept_tolls : true;
const tollAmount = parseFloat(body.toll_amount || body.tollAmount || 0);
if (!tripStartDistance || tripStartDistance <= 0) {
return res.status(400).json({
success: false,
error: 'Invalid trip start distance',
message: 'trip_start_distance must be greater than 0'
});
}

const existingBooking = await miniTripService.getBookingForUpdate(db,
id,
'estimated_distance_km, final_price, original_final_price, route_preference, pickup_date, pickup_time'
);
if (!existingBooking) {
return res.status(404).json({
success: false,
error: 'Mini trip booking not found'
});
}
const bookingDistance = parseFloat(existingBooking.estimated_distance_km);
const bookingPrice = parseFloat(existingBooking.original_final_price) || parseFloat(existingBooking.final_price);
const routeType = existingBooking.route_preference || 'fastest';
const tolerance = pricingService.TOLERANCE_THRESHOLDS[routeType] || pricingService.TOLERANCE_THRESHOLDS.fastest;
const tolerancePercent = tolerance.tolerancePercent;
const distanceChange = tripStartDistance - bookingDistance;
const percentageChange = (distanceChange / bookingDistance) * 100;
const maxAllowedDistance = bookingDistance * (1 + tolerancePercent / 100);
const withinTolerance = tripStartDistance <= maxAllowedDistance;
let newPrice = bookingPrice;
let priceChange = 0;
let finalPrice = bookingPrice;
let requiresCustomerApproval = false;
if (distanceChange < 0) {
newPrice = bookingPrice;
priceChange = 0;
finalPrice = bookingPrice;
} else if (withinTolerance) {
newPrice = bookingPrice;
priceChange = 0;
finalPrice = bookingPrice;
} else {
const pickupDateTime = new Date(`${existingBooking.pickup_date}T${existingBooking.pickup_time}`);
const newPricing = pricingService.calculateMiniTravelPrice(tripStartDistance, pickupDateTime);
newPrice = newPricing.finalPrice;
priceChange = newPrice - bookingPrice;
const maxAllowedIncrease = bookingPrice * pricingService.MAX_PRICE_INCREASE_CAP;
if (priceChange > maxAllowedIncrease) {
newPrice = bookingPrice + maxAllowedIncrease;
priceChange = maxAllowedIncrease;
}
if (!acceptPriceChange) {
requiresCustomerApproval = true;
return res.status(200).json({
success: true,
requires_approval: true,
message: 'Route distance exceeds tolerance. Customer approval required.',
pricing: {
original_distance_km: bookingDistance,
trip_start_distance_km: tripStartDistance,
distance_change_km: distanceChange,
percentage_change: parseFloat(percentageChange.toFixed(2)),
tolerance_percent: tolerancePercent,
within_tolerance: false,
original_price: bookingPrice,
new_price: newPrice,
price_change: priceChange,
toll_amount: tollAmount,
final_price_with_tolls: newPrice + tollAmount
}
});
}
finalPrice = newPrice;
}
if (acceptTolls && tollAmount > 0) {
finalPrice += tollAmount;
}

const updatedBooking = await miniTripService.updateBookingRoute(db, id, {
tripStartDistance,
finalPrice,
selectedRouteType
});
if (!updatedBooking) {
return res.status(404).json({
success: false,
error: 'Failed to update booking'
});
}
const responsePayload = buildResponsePayload(updatedBooking);
res.status(200).json({
success: true,
message: 'Route updated successfully',
data: responsePayload,
pricing: {
original_distance_km: bookingDistance,
trip_start_distance_km: tripStartDistance,
distance_change_km: distanceChange,
percentage_change: parseFloat(percentageChange.toFixed(2)),
tolerance_percent: tolerancePercent,
within_tolerance: withinTolerance,
original_price: bookingPrice,
new_price: newPrice,
price_change: priceChange,
toll_amount: acceptTolls ? tollAmount : 0,
final_price: finalPrice
}
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to update route',
message: error.message
});
}
};
module.exports = {
createMiniTripBooking,
listMiniTripBookings,
getMiniTripBookingById,
updateMiniTripArrivalTimes,
getRoutesForBooking,
updateRouteAtTripStart
};
