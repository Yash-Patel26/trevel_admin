const db = require('../config/postgresClient');
const pricingService = require('../services/pricingService');
const airportTransferService = require('../services/airportTransferService');
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
  const str = String(value).trim();
  if (/^\d+:\d+(:\d+)?$/.test(str)) {
    const [h = '0', m = '0', s = '0'] = str.split(':');
    const hours = Number(h);
    const minutes = Number(m);
    const seconds = Number(s);
    if ([hours, minutes, seconds].some((n) => Number.isNaN(n))) return null;
    return hours * 60 + minutes + Math.floor(seconds / 60);
  }
  const parsed = Number(str);
  return Number.isNaN(parsed) ? null : Math.trunc(parsed);
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
  const trimmed = value.trim();
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
const minutesToHHMMSS = (minutes) => {
  if (minutes === null || minutes === undefined) return null;
  const total = Math.max(0, Number(minutes) || 0);
  const h = Math.floor(total / 60);
  const m = total % 60;
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:00`;
};
const resolveUserId = async (reqUser, body, passengerName, passengerPhone, passengerEmail) => {

  const providedUserId = reqUser?.id || body.user_id || body.userId;
  if (providedUserId) {
    return providedUserId;
  }

  return null;
};
const TABLES = airportTransferService.TABLES;
const createAirportTransferBookingHandler = async (req, res, tableName) => {
  try {
    const body = req.body || {};
    const passengerName = body.passenger_name || body.passengerName;
    const passengerPhone = body.passenger_phone || body.passengerPhone;
    const passengerEmail = body.passenger_email || body.passengerEmail || null;
    const pickupLocation = body.pickup_location || body.pickupLocation;
    const pickupDateRaw = body.pickup_date || body.pickupDate;
    const pickupTimeRaw = body.pickup_time || body.pickupTime;
    const destinationAirport = body.destination_airport || body.destinationAirport;
    const makeSelected = body.make_selected || body.makeSelected || 'Not Specified';
    const makeImage = body.make_image_url || body.makeImageUrl || null;
    const distanceValue = body.estimated_distance_km ?? body.estimatedDistanceKm;
    const timeValue = body.estimated_time_min ?? body.estimatedTimeMin;
    const basePriceValue = body.base_price ?? body.basePrice;
    const taxValue = body.gst_amount ?? body.gstAmount ?? body.tax_amount ?? body.taxAmount;
    const finalPriceValue = body.final_price ?? body.finalPrice;
    if (
      !passengerName ||
      !passengerPhone ||
      !pickupLocation ||
      !pickupDateRaw ||
      !pickupTimeRaw ||
      !destinationAirport ||
      !makeSelected ||
      distanceValue === undefined ||
      timeValue === undefined ||
      basePriceValue === undefined ||
      taxValue === undefined ||
      finalPriceValue === undefined
    ) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields',
        message:
          'passenger_name, passenger_phone, pickup_location, pickup_date, pickup_time, destination_airport, make_selected, estimated_distance_km, estimated_time_min, base_price, gst_amount and final_price are required'
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

    const distanceNumber = ensureNumber(distanceValue, 'estimated_distance_km');
    const isToAirport = tableName === TABLES.toAirport;
    let calculatedPricing;
    try {
      if (isToAirport) {
        calculatedPricing = pricingService.calculateAirportDropPrice(pickupTime);
      } else {
        calculatedPricing = pricingService.calculateAirportPickupPrice(pickupTime);
      }
    } catch (error) {
      return res.status(400).json({
        success: false,
        error: 'Pricing calculation failed',
        message: error.message
      });
    }
    const basePriceNumber = calculatedPricing.basePrice;
    const taxNumber = calculatedPricing.gstAmount;
    const finalPriceNumber = calculatedPricing.finalPrice;
    const originalFinalPrice = finalPriceNumber;
    const routePreference = body.route_preference || body.routePreference || 'shortest';
    const timeMinutes = parseDurationToMinutes(timeValue);
    if (timeMinutes === null) {
      return res.status(400).json({
        success: false,
        error: 'Invalid duration',
        message: 'estimated_time_min must be a number or time in HH:MM or HH:MM:SS format'
      });
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
      pickupDate,
      pickupTime,
      destinationAirport,
      makeId: makeId,
      makeSelected: makeSelected,
      makeImage: makeImage,
      distanceNumber,
      timeMinutes: minutesToHHMMSS(timeMinutes),
      basePriceNumber,
      taxNumber,
      finalPriceNumber,
      originalFinalPrice,
      routePreference,
      pickupLat: pickupLat ? parseFloat(pickupLat) : null,
      pickupLng: pickupLng ? parseFloat(pickupLng) : null,
      currency: body.currency || 'INR',
      status: body.status || 'pending'
    };

    const responsePayload = await airportTransferService.createBooking(db, tableName, bookingData);
    res.status(201).json({
      success: true,
      message: 'Airport transfer booking created successfully',
      data: responsePayload
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to create airport transfer booking',
      message: error.message
    });
  }
};
const createToAirportTransferBooking = (req, res) =>
  createAirportTransferBookingHandler(req, res, TABLES.toAirport);
const createFromAirportTransferBooking = (req, res) =>
  createAirportTransferBookingHandler(req, res, TABLES.fromAirport);
const listAirportTransferBookings = async (req, res, tableName) => {
  try {
    const { status, pickup_date, limit } = req.query;
    const filters = {
      status,
      pickup_date: pickup_date ? formatDateForStorage(pickup_date) : null,
      limit
    };

    const bookings = await airportTransferService.listBookings(db, tableName, filters);
    res.status(200).json({
      success: true,
      count: bookings.length,
      data: bookings
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to fetch airport transfer bookings',
      message: error.message
    });
  }
};
const listToAirportTransferBookings = (req, res) =>
  listAirportTransferBookings(req, res, TABLES.toAirport);
const listFromAirportTransferBookings = (req, res) =>
  listAirportTransferBookings(req, res, TABLES.fromAirport);
const getAirportTransferBookingById = async (req, res, tableName) => {
  try {
    const { id } = req.params;

    const booking = await airportTransferService.getBookingById(db, tableName, id);
    if (!booking) {
      return res.status(404).json({
        success: false,
        error: 'Airport transfer booking not found'
      });
    }
    res.status(200).json({
      success: true,
      data: booking
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to fetch airport transfer booking',
      message: error.message
    });
  }
};
const getToAirportTransferBookingById = (req, res) =>
  getAirportTransferBookingById(req, res, TABLES.toAirport);
const getFromAirportTransferBookingById = (req, res) =>
  getAirportTransferBookingById(req, res, TABLES.fromAirport);
module.exports = {
  createToAirportTransferBooking,
  createFromAirportTransferBooking,
  listToAirportTransferBookings,
  listFromAirportTransferBookings,
  getToAirportTransferBookingById,
  getFromAirportTransferBookingById
};
