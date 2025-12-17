const crypto = require('crypto');
const { ensureHourlyRentalTableExists } = require('../utils/ensureHourlyRentalTable');

// Helper function to check if column exists
const checkColumnExists = async (db, tableName, columnName) => {
  try {
    const query = `
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = $1 AND column_name = $2
    `;
    const { rows } = await db.query(query, [tableName, columnName]);
    return rows.length > 0;
  } catch (error) {
    return false;
  }
};

const toShortNumericId = (uuid) => {
  if (!uuid) return null;
  const cleaned = uuid.replace(/-/g, '');
  const segment = cleaned.slice(0, 8);
  const num = parseInt(segment, 16);
  return Number.isNaN(num) ? null : num;
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

const formatTimeForResponse = (value) => {
  if (!value) return null;
  const match = /^(\d{2}):(\d{2})(?::(\d{2}))?/.exec(value);
  if (!match) return value;
  const [, hh, mm, ss = '00'] = match;
  return `${hh}:${mm}:${ss}`;
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
  pickup_date: formatDateForResponse(record.pickup_date),
  pickup_time: formatTimeForResponse(record.pickup_time),
  make_selected: record.make_selected,
  make_image_url: record.make_image_url,
  make_id: record.make_id,
  rental_hours: record.rental_hours === null ? null : Number(record.rental_hours),
  covered_distance_km: record.covered_distance_km,
  base_price: record.base_price,
  gst_amount: record.gst_amount,
  final_price: record.final_price,
  original_final_price: record.original_final_price,
  extension_minutes: record.extension_minutes || 0,
  airport_visits_count: record.airport_visits_count || 0,
  extension_charge: record.extension_charge || 0,
  airport_visit_charge: record.airport_visit_charge || 0,
  route_preference: record.route_preference || 'shortest',
  currency: record.currency,
  notes: record.notes,
  status: record.status,
  created_at: record.created_at,
  updated_at: record.updated_at
});

const createBooking = async (db, bookingData) => {
  await ensureHourlyRentalTableExists(db);

  // Check which columns exist
  const columnChecks = await Promise.all([
    checkColumnExists(db, 'hourly_rental_bookings', 'make_id'),
    checkColumnExists(db, 'hourly_rental_bookings', 'make_selected'),
    checkColumnExists(db, 'hourly_rental_bookings', 'vehicle_selected'), // Check for old column name
    checkColumnExists(db, 'hourly_rental_bookings', 'make_image_url'),
    checkColumnExists(db, 'hourly_rental_bookings', 'original_final_price'),
    checkColumnExists(db, 'hourly_rental_bookings', 'route_preference'),
    checkColumnExists(db, 'hourly_rental_bookings', 'pickup_latitude'),
    checkColumnExists(db, 'hourly_rental_bookings', 'pickup_longitude')
  ]);

  const [hasMakeId, hasMakeSelected, hasVehicleSelected, hasMakeImageUrl, hasOriginalFinalPrice, hasRoutePreference, hasPickupLat, hasPickupLng] = columnChecks;

  // Generate UUID
  const bookingId = crypto.randomUUID();

  // Build insert query dynamically - start with required fields
  const insertFields = ['id', 'user_id', 'passenger_name', 'passenger_email', 'passenger_phone', 'pickup_location', 'pickup_city', 'pickup_state', 'pickup_date', 'pickup_time'];
  const insertValues = [bookingId, bookingData.userId, bookingData.passengerName, bookingData.passengerEmail, bookingData.passengerPhone, bookingData.pickupLocation, bookingData.pickupCity, bookingData.pickupState, bookingData.pickupDate, bookingData.pickupTime];

  // Add optional vehicle columns after pickup_time
  // Ensure we always have a value for make_selected/vehicle_selected (never NULL)
  const makeSelectedValue = bookingData.makeSelected || 'Not Specified';

  if (hasMakeId) {
    insertFields.push('make_id');
    insertValues.push(bookingData.makeId);
  }
  // Handle both make_selected (new) and vehicle_selected (old) column names
  if (hasMakeSelected) {
    insertFields.push('make_selected');
    insertValues.push(makeSelectedValue); // Always provide a value, never NULL
  }
  if (hasVehicleSelected && !hasMakeSelected) {
    // If only old column exists, use it
    insertFields.push('vehicle_selected');
    insertValues.push(makeSelectedValue); // Always provide a value, never NULL
  }
  if (hasMakeImageUrl) {
    insertFields.push('make_image_url');
    insertValues.push(bookingData.makeImage);
  }

  // Add rental-specific fields
  insertFields.push('rental_hours', 'covered_distance_km', 'base_price', 'gst_amount', 'final_price');
  insertValues.push(bookingData.rentalHoursNumber, bookingData.distanceNumber, bookingData.basePriceNumber, bookingData.gstNumber, bookingData.finalPriceNumber);

  // Add optional pricing fields
  if (hasOriginalFinalPrice) {
    insertFields.push('original_final_price');
    insertValues.push(bookingData.originalFinalPrice);
  }

  // Add extension and airport fields
  insertFields.push('extension_minutes', 'airport_visits_count', 'extension_charge', 'airport_visit_charge');
  insertValues.push(bookingData.extensionMinutes || 0, bookingData.airportVisitsCount || 0, bookingData.extensionCharge || 0, bookingData.airportVisitCharge || 0);

  // Add optional route and location fields
  if (hasRoutePreference) {
    insertFields.push('route_preference');
    insertValues.push(bookingData.routePreference);
  }
  if (hasPickupLat) {
    insertFields.push('pickup_latitude');
    insertValues.push(bookingData.pickupLat);
  }
  if (hasPickupLng) {
    insertFields.push('pickup_longitude');
    insertValues.push(bookingData.pickupLng);
  }

  // Add currency, status, and notes (required)
  insertFields.push('currency', 'status', 'notes');
  insertValues.push(bookingData.currency || 'INR', bookingData.status || 'pending', bookingData.notes || null);

  const placeholders = insertFields.map((_, index) => `$${index + 1}`).join(', ');
  const fieldsList = insertFields.join(', ');

  const insertQuery = `
    INSERT INTO hourly_rental_bookings (${fieldsList})
    VALUES (${placeholders})
    RETURNING *;
  `;

  const { rows } = await db.query(insertQuery, insertValues);

  return buildResponsePayload(rows[0]);
};

const listBookings = async (db, filters = {}) => {
  await ensureHourlyRentalTableExists(db);

  const { status, pickup_date, pickup_city, limit } = filters;
  const queryParams = [];
  const whereClauses = [];

  if (status && status !== 'all') {
    queryParams.push(status);
    whereClauses.push(`status = $${queryParams.length}`);
  }

  if (pickup_date) {
    queryParams.push(pickup_date);
    whereClauses.push(`pickup_date = $${queryParams.length}`);
  }

  if (pickup_city) {
    queryParams.push(`%${pickup_city}%`);
    whereClauses.push(`pickup_city ILIKE $${queryParams.length}`);
  }

  let query = `SELECT * FROM hourly_rental_bookings`;
  if (whereClauses.length > 0) {
    query += ` WHERE ${whereClauses.join(' AND ')}`;
  }

  const limitValue = Math.min(parseInt(limit) || 100, 1000);
  query += ` ORDER BY created_at DESC, pickup_date ASC, pickup_time ASC LIMIT $${queryParams.length + 1}`;
  queryParams.push(limitValue);

  const { rows } = await db.query(query, queryParams);
  return rows.map((record) => buildResponsePayload(record));
};

const getBookingById = async (db, bookingId) => {
  await ensureHourlyRentalTableExists(db);

  const query = `SELECT * FROM hourly_rental_bookings WHERE id = $1 LIMIT 1`;
  const { rows } = await db.query(query, [bookingId]);

  if (rows.length === 0) {
    return null;
  }

  return buildResponsePayload(rows[0]);
};

const getBookingForUpdate = async (db, bookingId) => {
  await ensureHourlyRentalTableExists(db);

  const query = `
    SELECT rental_hours, original_final_price, final_price
    FROM hourly_rental_bookings
    WHERE id = $1
  `;
  const { rows } = await db.query(query, [bookingId]);

  return rows.length > 0 ? rows[0] : null;
};

const updateBookingWithExtensions = async (db, bookingId, updateData) => {
  await ensureHourlyRentalTableExists(db);

  const { extensionMinutes, airportVisitsCount, newPricing, originalFinalPrice } = updateData;

  const updateQuery = `
    UPDATE hourly_rental_bookings
    SET
      extension_minutes = $1,
      airport_visits_count = $2,
      extension_charge = $3,
      airport_visit_charge = $4,
      final_price = $5,
      original_final_price = COALESCE(original_final_price, $6),
      updated_at = NOW()
    WHERE id = $7
    RETURNING *;
  `;

  const { rows } = await db.query(updateQuery, [
    extensionMinutes,
    airportVisitsCount,
    newPricing.extensionCharge,
    newPricing.airportVisitCharge,
    newPricing.finalPrice,
    originalFinalPrice,
    bookingId
  ]);

  return buildResponsePayload(rows[0]);
};

module.exports = {
  createBooking,
  listBookings,
  getBookingById,
  getBookingForUpdate,
  updateBookingWithExtensions,
  buildResponsePayload
};

