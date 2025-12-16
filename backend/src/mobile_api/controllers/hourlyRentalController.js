const db = require('../config/postgresClient');
const pricingService = require('../services/pricingService');
const hourlyRentalService = require('../services/hourlyRentalService');
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
const formatDateForStorage = (value) => {
if (!value) return null;
const trimmed = String(value).trim();
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
let [ , hourStr, minuteStr, suffix ] = amPmMatch;
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
const createHourlyRentalBooking = async (req, res) => {
try {
const body = req.body || {};
const passengerName = body.passenger_name || body.passengerName;
const passengerPhone = body.passenger_phone || body.passengerPhone;
const passengerEmail = body.passenger_email || body.passengerEmail || null;
const pickupLocation = body.pickup_location || body.pickupLocation;
const pickupDateRaw = body.pickup_date || body.pickupDate;
const pickupTimeRaw = body.pickup_time || body.pickupTime;
const makeSelected = body.make_selected || body.makeSelected || 'Not Specified';
const makeImage =
body.make_image_url ||
body.makeImageUrl ||
null;
const rentalHoursValue = body.rental_hours ?? body.rentalHours;
const distanceValue = body.covered_distance_km ?? body.coveredDistanceKm;
const basePriceValue = body.base_price ?? body.basePrice;
const gstValue = body.gst_amount ?? body.gstAmount ?? 0;
const finalPriceValue = body.final_price ?? body.finalPrice;
if (
!passengerName ||
!passengerPhone ||
!pickupLocation ||
!pickupDateRaw ||
!pickupTimeRaw ||
!makeSelected ||
rentalHoursValue === undefined ||
distanceValue === undefined ||
basePriceValue === undefined ||
finalPriceValue === undefined
) {
return res.status(400).json({
success: false,
error: 'Missing required fields',
message:
'passenger_name, passenger_phone, pickup_location, pickup_date, pickup_time, make_selected, rental_hours, covered_distance_km, base_price, and final_price are required'
});
}
const userId = await resolveUserId(req.user, body, passengerName, passengerPhone, passengerEmail);
if (!userId) {
return res.status(401).json({
success: false,
error: 'Missing user context',
message: 'Unable to identify user. Provide user_id, authenticate, or include a valid passenger_phone.'
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

const rentalHoursNumber = ensureNumber(rentalHoursValue, 'rental_hours');
if (rentalHoursNumber <= 0) {
return res.status(400).json({
success: false,
error: 'Invalid rental hours',
message: 'rental_hours must be greater than 0'
});
}
const distanceNumber = ensureNumber(distanceValue, 'covered_distance_km');
if (distanceNumber < 0) {
return res.status(400).json({
success: false,
error: 'Invalid covered distance',
message: 'covered_distance_km must be a non-negative number'
});
}
let calculatedPricing;
try {
calculatedPricing = pricingService.calculateHourlyRentalPrice(rentalHoursNumber);
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
const originalFinalPrice = finalPriceNumber;
const routePreference = body.route_preference || body.routePreference || 'shortest';
if (basePriceValue !== undefined || finalPriceValue !== undefined) {
const clientBase = basePriceValue ? ensureNumber(basePriceValue, 'base_price') : null;
const clientFinal = finalPriceValue ? ensureNumber(finalPriceValue, 'final_price') : null;
if (clientBase && Math.abs(clientBase - basePriceNumber) > 0.01) {
}
if (clientFinal && Math.abs(clientFinal - finalPriceNumber) > 0.01) {
}
}
const pickupLat = body.pickup_latitude || body.pickupLatitude ||
(body.pickup && (body.pickup.lat || body.pickup.latitude)) || null;
const pickupLng = body.pickup_longitude || body.pickupLongitude ||
(body.pickup && (body.pickup.lng || body.pickup.longitude)) || null;

let makeId = null;
const makeIdInput = body.make_id || body.makeId;
if (makeIdInput) {
const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
if (uuidRegex.test(makeIdInput)) {
makeId = makeIdInput;
}
}

const bookingData = {
userId,
passengerName,
passengerEmail,
passengerPhone,
pickupLocation,
pickupCity: body.pickup_city || body.pickupCity || null,
pickupState: body.pickup_state || body.pickupState || null,
pickupDate,
pickupTime,
makeId: makeId,
makeSelected: makeSelected,
makeImage: makeImage,
rentalHoursNumber,
distanceNumber,
basePriceNumber,
gstNumber,
finalPriceNumber,
originalFinalPrice,
routePreference,
pickupLat: pickupLat ? parseFloat(pickupLat) : null,
pickupLng: pickupLng ? parseFloat(pickupLng) : null,
currency: body.currency || 'INR',
status: body.status || 'pending',
notes: body.notes || null
};

const responsePayload = await hourlyRentalService.createBooking(db, bookingData);
res.status(201).json({
success: true,
message: 'Hourly rental booking created successfully',
data: responsePayload
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to create hourly rental booking',
message: error.message
});
}
};
const listHourlyRentalBookings = async (req, res) => {
try {
const { status, pickup_date, pickup_city, limit } = req.query;
const filters = {
status,
pickup_date: pickup_date ? formatDateForStorage(pickup_date) : null,
pickup_city,
limit
};

const bookings = await hourlyRentalService.listBookings(db, filters);
res.status(200).json({
success: true,
count: bookings.length,
data: bookings
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to fetch hourly rental bookings',
message: error.message
});
}
};
const getHourlyRentalBookingById = async (req, res) => {
try {
const { id } = req.params;

const booking = await hourlyRentalService.getBookingById(db, id);
if (!booking) {
return res.status(404).json({
success: false,
error: 'Hourly rental booking not found'
});
}
res.status(200).json({
success: true,
data: booking
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to fetch hourly rental booking',
message: error.message
});
}
};
const updateHourlyRentalWithExtensions = async (req, res) => {
try {
const { id } = req.params;
const body = req.body || {};
const extensionMinutes = body.extension_minutes ?? body.extensionMinutes ?? 0;
const airportVisitsCount = body.airport_visits_count ?? body.airportVisitsCount ?? 0;
if (extensionMinutes < 0) {
return res.status(400).json({
success: false,
error: 'Invalid extension minutes',
message: 'extension_minutes must be a non-negative number'
});
}
if (airportVisitsCount < 0) {
return res.status(400).json({
success: false,
error: 'Invalid airport visits count',
message: 'airport_visits_count must be a non-negative number'
});
}

const existingBooking = await hourlyRentalService.getBookingForUpdate(db, id);
if (!existingBooking) {
return res.status(404).json({
success: false,
error: 'Hourly rental booking not found'
});
}
const baseHours = parseFloat(existingBooking.rental_hours) || 2;
const originalFinalPrice = parseFloat(existingBooking.original_final_price) || parseFloat(existingBooking.final_price);
const newPricing = pricingService.calculateHourlyRentalTotalPrice(
baseHours,
extensionMinutes,
airportVisitsCount
);

const responsePayload = await hourlyRentalService.updateBookingWithExtensions(db, id, {
extensionMinutes,
airportVisitsCount,
newPricing,
originalFinalPrice
});
res.status(200).json({
success: true,
message: 'Hourly rental updated with extension and airport visit charges',
data: responsePayload,
pricing: {
basePrice: newPricing.basePrice,
baseFinalPrice: newPricing.baseFinalPrice,
extensionMinutes: newPricing.extensionMinutes,
extensionCharge: newPricing.extensionCharge,
extensionBaseCharge: newPricing.extensionBaseCharge,
extensionGST: newPricing.extensionGST,
airportVisitsCount: newPricing.airportVisitsCount,
airportVisitCharge: newPricing.airportVisitCharge,
airportVisitBaseCharge: newPricing.airportVisitBaseCharge,
airportVisitGST: newPricing.airportVisitGST,
additionalChargesGST: newPricing.additionalChargesGST,
finalPrice: newPricing.finalPrice
}
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to update hourly rental booking',
message: error.message
});
}
};
module.exports = {
createHourlyRentalBooking,
listHourlyRentalBookings,
getHourlyRentalBookingById,
updateHourlyRentalWithExtensions
};
