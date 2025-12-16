const { ensureMiniTripTableExists } = require('../utils/ensureMiniTripTable');
const { ensurePromoCodesTableExists } = require('../utils/ensurePromoCodesTable');
const { generateUniquePromoCode } = require('../utils/promoCodeGenerator');

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

const createBooking = async (db, bookingData) => {
  await ensureMiniTripTableExists(db);

  // Check which columns exist
  const columnChecks = await Promise.all([
    checkColumnExists(db, 'mini_trip_bookings', 'make_id'),
    checkColumnExists(db, 'mini_trip_bookings', 'make_selected'),
    checkColumnExists(db, 'mini_trip_bookings', 'make_image_url'),
    checkColumnExists(db, 'mini_trip_bookings', 'vehicle_selected'), // Check for old column name
    checkColumnExists(db, 'mini_trip_bookings', 'original_final_price'),
    checkColumnExists(db, 'mini_trip_bookings', 'route_preference'),
    checkColumnExists(db, 'mini_trip_bookings', 'pickup_latitude'),
    checkColumnExists(db, 'mini_trip_bookings', 'pickup_longitude'),
    checkColumnExists(db, 'mini_trip_bookings', 'dropoff_latitude'),
    checkColumnExists(db, 'mini_trip_bookings', 'dropoff_longitude')
  ]);

  const [hasMakeId, hasMakeSelected, hasMakeImageUrl, hasVehicleSelected, hasOriginalFinalPrice, hasRoutePreference, hasPickupLat, hasPickupLng, hasDropoffLat, hasDropoffLng] = columnChecks;

  // Controller provides insertValues array in this order:
  // [0] id, [1] userId, [2] passengerName, [3] email, [4] phone,
  // [5] pickupLoc, [6] pickupCity, [7] pickupState,
  // [8] dropoffLoc, [9] dropoffCity, [10] dropoffState,
  // [11] pickupDate, [12] pickupTime,
  // [13] make_id, [14] make_selected, [15] make_image_url,
  // [16] distance, [17] time, [18] basePrice, [19] gst, [20] finalPrice,
  // [21] originalFinalPrice, [22] routePref,
  // [23] pickupLat, [24] pickupLng, [25] dropoffLat, [26] dropoffLng,
  // [27] currency, [28] status, [29] notes

  const originalValues = bookingData.insertValues || [];
  
  // Build insert query dynamically - start with required fields
  const insertFields = ['id', 'user_id', 'passenger_name', 'passenger_email', 'passenger_phone', 'pickup_location', 'pickup_city', 'pickup_state', 'dropoff_location', 'dropoff_city', 'dropoff_state', 'pickup_date', 'pickup_time'];
  const insertValues = [
    originalValues[0], // id
    originalValues[1], // userId
    originalValues[2], // passengerName
    originalValues[3], // email
    originalValues[4], // phone
    originalValues[5], // pickupLoc
    originalValues[6], // pickupCity
    originalValues[7], // pickupState
    originalValues[8], // dropoffLoc
    originalValues[9], // dropoffCity
    originalValues[10], // dropoffState
    originalValues[11], // pickupDate
    originalValues[12]  // pickupTime
  ];

  // Add optional make columns after pickup_time
  // Ensure we always have a value for make_selected (never NULL)
  const makeSelectedValue = originalValues[14] || 'Not Specified';
  
  if (hasMakeId) {
    insertFields.push('make_id');
    insertValues.push(originalValues[13] || null);
  }
  if (hasMakeSelected) {
    insertFields.push('make_selected');
    insertValues.push(makeSelectedValue); // Always provide a value, never NULL
  }
  if (hasMakeImageUrl) {
    insertFields.push('make_image_url');
    insertValues.push(originalValues[15] || null);
  }
  
  // Handle old vehicle_selected column (for backward compatibility)
  // If vehicle_selected exists, set it to the same value as make_selected
  if (hasVehicleSelected) {
    insertFields.push('vehicle_selected');
    insertValues.push(makeSelectedValue); // Use same value as make_selected
  }

  // Add distance and time
  insertFields.push('estimated_distance_km', 'estimated_time_min');
  insertValues.push(originalValues[16] || null, originalValues[17] || null);

  // Add pricing fields
  insertFields.push('base_price', 'gst_amount', 'final_price');
  insertValues.push(originalValues[18] || null, originalValues[19] || null, originalValues[20] || null);

  // Add optional pricing fields
  if (hasOriginalFinalPrice) {
    insertFields.push('original_final_price');
    insertValues.push(originalValues[21] || null);
  }

  // Add optional route and location fields
  if (hasRoutePreference) {
    insertFields.push('route_preference');
    insertValues.push(originalValues[22] || null);
  }
  if (hasPickupLat) {
    insertFields.push('pickup_latitude');
    insertValues.push(originalValues[23] || null);
  }
  if (hasPickupLng) {
    insertFields.push('pickup_longitude');
    insertValues.push(originalValues[24] || null);
  }
  if (hasDropoffLat) {
    insertFields.push('dropoff_latitude');
    insertValues.push(originalValues[25] || null);
  }
  if (hasDropoffLng) {
    insertFields.push('dropoff_longitude');
    insertValues.push(originalValues[26] || null);
  }

  // Add currency, status, and notes (required)
  insertFields.push('currency', 'status', 'notes');
  insertValues.push(originalValues[27] || 'INR', originalValues[28] || 'pending', originalValues[29] || null);

  const placeholders = insertFields.map((_, index) => `$${index + 1}`).join(', ');
  const fieldsList = insertFields.join(', ');

  const insertQuery = `
    INSERT INTO mini_trip_bookings (${fieldsList})
    VALUES (${placeholders})
    RETURNING *;
  `;

  try {
    const { rows } = await db.query(insertQuery, insertValues);
    if (!rows || rows.length === 0) {
      throw new Error('No rows returned from INSERT query');
    }
    return rows[0];
  } catch (error) {
    throw error;
  }
};

const listBookings = async (db, filters = {}) => {
  await ensureMiniTripTableExists(db);

  const { status, pickup_date, pickup_city, limit } = filters;
  const filtersArray = [];
  const params = [];

  if (status && status !== 'all') {
    params.push(status);
    filtersArray.push(`status = $${params.length}`);
  }
  if (pickup_date) {
    params.push(pickup_date);
    filtersArray.push(`pickup_date = $${params.length}`);
  }
  if (pickup_city) {
    params.push(`%${pickup_city}%`);
    filtersArray.push(`pickup_city ILIKE $${params.length}`);
  }

  let listQuery = `SELECT * FROM mini_trip_bookings`;
  if (filtersArray.length > 0) {
    listQuery += ` WHERE ${filtersArray.join(' AND ')}`;
  }

  const limitValue = Math.min(parseInt(limit) || 100, 1000);
  listQuery += `
    ORDER BY created_at DESC, pickup_date ASC, pickup_time ASC
    LIMIT $${params.length + 1}
  `;
  params.push(limitValue);

  const { rows } = await db.query(listQuery, params);
  return rows;
};

const getBookingById = async (db, bookingId) => {
  await ensureMiniTripTableExists(db);

  const { rows } = await db.query(
    `SELECT *
     FROM mini_trip_bookings
     WHERE id = $1
     LIMIT 1`,
    [bookingId]
  );
  return rows.length > 0 ? rows[0] : null;
};

const getBookingForUpdate = async (db, bookingId, fields = '*') => {
  await ensureMiniTripTableExists(db);

  const query = `SELECT ${fields} FROM mini_trip_bookings WHERE id = $1`;
  const { rows } = await db.query(query, [bookingId]);
  return rows.length > 0 ? rows[0] : null;
};

const updateBookingWithArrivalTimes = async (db, bookingId, updateData) => {
  await ensureMiniTripTableExists(db);

  const {
    driverArrivalTime,
    customerArrivalTime,
    driverCompensation,
    customerLateFee,
    finalPrice,
    baseFinalPrice
  } = updateData;

  const updateFields = [];
  const updateValues = [];
  let paramIndex = 1;

  if (driverArrivalTime) {
    updateFields.push(`driver_arrival_time = $${paramIndex++}`);
    updateValues.push(driverArrivalTime.toISOString());
  }
  if (customerArrivalTime) {
    updateFields.push(`customer_arrival_time = $${paramIndex++}`);
    updateValues.push(customerArrivalTime.toISOString());
  }
  updateFields.push(`driver_compensation = $${paramIndex++}`);
  updateValues.push(driverCompensation);
  updateFields.push(`customer_late_fee = $${paramIndex++}`);
  updateValues.push(customerLateFee);
  updateFields.push(`final_price = $${paramIndex++}`);
  updateValues.push(finalPrice);
  updateFields.push(`original_final_price = COALESCE(original_final_price, $${paramIndex++})`);
  updateValues.push(baseFinalPrice);
  updateFields.push(`updated_at = NOW()`);
  updateValues.push(bookingId);

  const updateQuery = `
    UPDATE mini_trip_bookings
    SET ${updateFields.join(', ')}
    WHERE id = $${paramIndex}
    RETURNING *;
  `;

  const { rows } = await db.query(updateQuery, updateValues);
  return rows.length > 0 ? rows[0] : null;
};

const createCompensationPromoCode = async (db, promoData) => {
  await ensurePromoCodesTableExists(db);

  const { userId, bookingId, amount, reason, expiresAt } = promoData;
  const promoCode = await generateUniquePromoCode(db);

  const insertPromoQuery = `
    INSERT INTO promo_codes (
      user_id, code, amount, booking_id, reason, status, expires_at
    ) VALUES ($1, $2, $3, $4, $5, $6, $7)
    RETURNING id, code, amount, expires_at, created_at
  `;

  const { rows } = await db.query(insertPromoQuery, [
    userId,
    promoCode,
    amount,
    bookingId,
    reason,
    'active',
    expiresAt
  ]);

  return rows.length > 0 ? rows[0] : null;
};

const updateBookingRoute = async (db, bookingId, updateData) => {
  await ensureMiniTripTableExists(db);

  const { tripStartDistance, finalPrice, selectedRouteType } = updateData;

  const updateQuery = `
    UPDATE mini_trip_bookings
    SET
      estimated_distance_km = $1,
      final_price = $2,
      route_preference = $3,
      updated_at = NOW()
    WHERE id = $4
    RETURNING *;
  `;

  const { rows } = await db.query(updateQuery, [
    tripStartDistance,
    finalPrice,
    selectedRouteType,
    bookingId
  ]);

  return rows.length > 0 ? rows[0] : null;
};

module.exports = {
  createBooking,
  listBookings,
  getBookingById,
  getBookingForUpdate,
  updateBookingWithArrivalTimes,
  createCompensationPromoCode,
  updateBookingRoute
};

