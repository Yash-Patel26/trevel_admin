const { ensureTransferTablesExist } = require('../utils/ensureTransferTables');

const TABLES = {
  toAirport: 'to_airport_transfer_bookings',
  fromAirport: 'from_airport_transfer_bookings'
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
  pickup_date: formatDateForResponse(record.pickup_date),
  pickup_time: formatTimeForResponse(record.pickup_time),
  destination_airport: record.destination_airport,
  make_selected: record.make_selected,
  make_image_url: record.make_image_url,
  estimated_distance_km: record.estimated_distance_km,
  estimated_time_min: formatTimeForResponse(record.estimated_time_min),
  base_price: record.base_price,
  gst_amount: record.gst_amount,
  final_price: record.final_price,
  currency: record.currency,
  status: record.status,
  created_at: record.created_at,
  updated_at: record.updated_at
});

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

const createBooking = async (db, tableName, bookingData) => {
  await ensureTransferTablesExist(db);

  // Check which columns exist
  const tableNameOnly = tableName.replace('public.', '').split('.')[0];
  const columnChecks = await Promise.all([
    checkColumnExists(db, tableNameOnly, 'make_id'),
    checkColumnExists(db, tableNameOnly, 'make_selected'),
    checkColumnExists(db, tableNameOnly, 'make_image_url'),
    checkColumnExists(db, tableNameOnly, 'original_final_price'),
    checkColumnExists(db, tableNameOnly, 'route_preference'),
    checkColumnExists(db, tableNameOnly, 'pickup_latitude'),
    checkColumnExists(db, tableNameOnly, 'pickup_longitude')
  ]);

  const [hasMakeId, hasMakeSelected, hasMakeImageUrl, hasOriginalFinalPrice, hasRoutePreference, hasPickupLat, hasPickupLng] = columnChecks;

  // Build insert query dynamically - start with required fields
  const insertFields = ['user_id', 'passenger_name', 'passenger_email', 'passenger_phone', 'pickup_location', 'pickup_date', 'pickup_time', 'destination_airport'];
  const insertValues = [bookingData.userId, bookingData.passengerName, bookingData.passengerEmail, bookingData.passengerPhone, bookingData.pickupLocation, bookingData.pickupDate, bookingData.pickupTime, bookingData.destinationAirport];

  // Add optional vehicle columns after destination_airport
  if (hasMakeId) {
    insertFields.push('make_id');
    insertValues.push(bookingData.makeId);
  }
  if (hasMakeSelected) {
    insertFields.push('make_selected');
    insertValues.push(bookingData.makeSelected || 'Not Specified');
  }
  if (hasMakeImageUrl) {
    insertFields.push('make_image_url');
    insertValues.push(bookingData.makeImage);
  }

  // Add distance and time
  insertFields.push('estimated_distance_km', 'estimated_time_min');
  insertValues.push(bookingData.distanceNumber, bookingData.timeMinutes);

  // Add pricing fields
  insertFields.push('base_price', 'gst_amount');
  insertValues.push(bookingData.basePriceNumber, bookingData.taxNumber);

  // Add optional pricing fields
  if (hasOriginalFinalPrice) {
    insertFields.push('original_final_price');
    insertValues.push(bookingData.originalFinalPrice);
  }

  // Add final price
  insertFields.push('final_price');
  insertValues.push(bookingData.finalPriceNumber);

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

  // Add currency and status (required)
  insertFields.push('currency', 'status');
  insertValues.push(bookingData.currency || 'INR', bookingData.status || 'pending');

  const placeholders = insertFields.map((_, index) => `$${index + 1}`).join(', ');
  const fieldsList = insertFields.join(', ');

  const insertQuery = `
    INSERT INTO ${tableName} (${fieldsList})
    VALUES (${placeholders})
    RETURNING *;
  `;

  const { rows } = await db.query(insertQuery, insertValues);

  return buildResponsePayload(rows[0]);
};

const listBookings = async (db, tableName, filters = {}) => {
  await ensureTransferTablesExist(db);

  const { status, pickup_date, limit } = filters;
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

  let query = `SELECT * FROM ${tableName}`;
  if (whereClauses.length > 0) {
    query += ` WHERE ${whereClauses.join(' AND ')}`;
  }

  const limitValue = Math.min(parseInt(limit) || 100, 1000);
  query += ` ORDER BY created_at DESC, pickup_date ASC, pickup_time ASC LIMIT $${queryParams.length + 1}`;
  queryParams.push(limitValue);

  const { rows } = await db.query(query, queryParams);
  return rows.map((record) => buildResponsePayload(record));
};

const getBookingById = async (db, tableName, bookingId) => {
  await ensureTransferTablesExist(db);

  const query = `SELECT * FROM ${tableName} WHERE id = $1 LIMIT 1`;
  const { rows } = await db.query(query, [bookingId]);

  if (rows.length === 0) {
    return null;
  }

  return buildResponsePayload(rows[0]);
};

module.exports = {
  TABLES,
  createBooking,
  listBookings,
  getBookingById,
  buildResponsePayload
};

