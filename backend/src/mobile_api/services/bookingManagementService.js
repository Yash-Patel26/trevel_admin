const { BOOKING_SOURCES, mapBookingRecord } = require('../controllers/myBookingsController');

const findBookingById = async (db, bookingId, userId) => {
  for (const source of BOOKING_SOURCES) {
    const { rows } = await db.query(
      `SELECT * FROM ${source.table} WHERE id = $1 AND user_id = $2`,
      [bookingId, userId]
    );
    if (rows.length > 0) {
      return { booking: rows[0], source };
    }
  }
  return null;
};

const cancelBooking = async (db, bookingId, userId, reason) => {
  const result = await findBookingById(db, bookingId, userId);
  if (!result) {
    return null;
  }

  const { booking, source } = result;
  if (booking.status === 'cancelled' || booking.status === 'completed') {
    throw new Error(`Booking is already ${booking.status}`);
  }

  const { rows } = await db.query(
    `UPDATE ${source.table}
     SET status = 'cancelled', notes = COALESCE(notes || '\n', '') || $1
     WHERE id = $2 AND user_id = $3
     RETURNING *`,
    [reason ? `Cancellation reason: ${reason}` : 'Cancelled by user', bookingId, userId]
  );

  return mapBookingRecord(rows[0], source);
};

const updateBooking = async (db, bookingId, userId, updateData) => {
  const result = await findBookingById(db, bookingId, userId);
  if (!result) {
    return null;
  }

  const { booking, source } = result;
  if (booking.status === 'cancelled' || booking.status === 'completed') {
    throw new Error(`Cannot update ${booking.status} booking`);
  }

  const { pickup_date, pickup_time, pickup, dropoff } = updateData;
  const updateFields = [];
  const values = [];
  let paramIndex = 1;

  if (pickup_date) {
    updateFields.push(`pickup_date = $${paramIndex++}`);
    values.push(pickup_date);
  }
  if (pickup_time) {
    updateFields.push(`pickup_time = $${paramIndex++}`);
    values.push(pickup_time);
  }
  if (pickup?.location) {
    updateFields.push(`pickup_location = $${paramIndex++}`);
    values.push(pickup.location);
  }
  if (pickup?.city) {
    updateFields.push(`pickup_city = $${paramIndex++}`);
    values.push(pickup.city);
  }
  if (pickup?.state) {
    updateFields.push(`pickup_state = $${paramIndex++}`);
    values.push(pickup.state);
  }
  if (dropoff?.location) {
    if (source.type === 'mini_trip') {
      updateFields.push(`dropoff_location = $${paramIndex++}`);
      values.push(dropoff.location);
    } else if (source.type === 'to_airport' || source.type === 'from_airport') {
      updateFields.push(`destination_airport = $${paramIndex++}`);
      values.push(dropoff.location);
    }
  }

  if (updateFields.length === 0) {
    throw new Error('No fields to update');
  }

  values.push(bookingId, userId);
  const { rows } = await db.query(
    `UPDATE ${source.table}
     SET ${updateFields.join(', ')}
     WHERE id = $${paramIndex++} AND user_id = $${paramIndex}
     RETURNING *`,
    values
  );

  return mapBookingRecord(rows[0], source);
};

const getDriverRatingForCustomer = async (db, driverId) => {
  try {
    const { rows } = await db.query(
      `SELECT
       COALESCE(AVG(r.driver_rating), 0) as average_rating,
       COUNT(r.driver_rating) as total_ratings
       FROM (
         SELECT r.driver_rating
         FROM ratings r
         INNER JOIN mini_trip_bookings b ON r.booking_id = b.id AND r.booking_type = 'mini_trip'
         INNER JOIN makes v ON b.make_id = v.id
         WHERE v.driver_id = $1 AND r.driver_rating IS NOT NULL
         UNION ALL
         SELECT r.driver_rating
         FROM ratings r
         INNER JOIN hourly_rental_bookings b ON r.booking_id = b.id AND r.booking_type = 'hourly_rental'
         INNER JOIN makes v ON b.make_id = v.id
         WHERE v.driver_id = $1 AND r.driver_rating IS NOT NULL
         UNION ALL
         SELECT r.driver_rating
         FROM ratings r
         INNER JOIN to_airport_transfer_bookings b ON r.booking_id = b.id AND r.booking_type = 'to_airport'
         INNER JOIN makes v ON b.make_id = v.id
         WHERE v.driver_id = $1 AND r.driver_rating IS NOT NULL
         UNION ALL
         SELECT r.driver_rating
         FROM ratings r
         INNER JOIN from_airport_transfer_bookings b ON r.booking_id = b.id AND r.booking_type = 'from_airport'
         INNER JOIN makes v ON b.make_id = v.id
         WHERE v.driver_id = $1 AND r.driver_rating IS NOT NULL
       ) r`,
      [driverId]
    );
    const averageRating = parseFloat(rows[0]?.average_rating || 0);
    const totalRatings = parseInt(rows[0]?.total_ratings || 0);
    return {
      average_rating: averageRating > 0 ? parseFloat(averageRating.toFixed(2)) : null,
      total_ratings: totalRatings
    };
  } catch (error) {
    return {
      average_rating: null,
      total_ratings: 0
    };
  }
};

const getBookingDriver = async (db, bookingId, userId) => {
  for (const source of BOOKING_SOURCES) {
    const { rows: booking } = await db.query(
      `SELECT b.*, v.driver_id, d.full_name as driver_name, d.phone as driver_phone
       FROM ${source.table} b
       LEFT JOIN makes v ON b.make_id = v.id
       LEFT JOIN drivers d ON v.driver_id = d.id
       WHERE b.id = $1 AND b.user_id = $2`,
      [bookingId, userId]
    );
    if (booking.length > 0) {
      const bookingData = booking[0];
      if (!bookingData.driver_id) {
        return null;
      }
      const rating = await getDriverRatingForCustomer(db, bookingData.driver_id);
      return {
        id: bookingData.driver_id,
        name: bookingData.driver_name,
        phone: bookingData.driver_phone,
        make_id: bookingData.make_id,
        rating
      };
    }
  }
  return null;
};

const getBookingVehicleId = async (db, bookingId, userId) => {
  for (const source of BOOKING_SOURCES) {
    const { rows } = await db.query(
      `SELECT make_id FROM ${source.table} WHERE id = $1 AND user_id = $2`,
      [bookingId, userId]
    );
    if (rows.length > 0) {
      return rows[0].make_id;
    }
  }
  return null;
};

const getLiveLocation = async (db, vehicleId) => {
  const { rows: tracking } = await db.query(
    `SELECT latitude, longitude, speed_kmh, course, tracked_at, status
     FROM vehicle_tracking
     WHERE make_id = $1
     ORDER BY tracked_at DESC
     LIMIT 1`,
    [vehicleId]
  );
  return tracking.length > 0 ? tracking[0] : null;
};

const getDriverPhone = async (db, bookingId, userId) => {
  for (const source of BOOKING_SOURCES) {
    const { rows } = await db.query(
      `SELECT d.phone
       FROM ${source.table} b
       LEFT JOIN makes v ON b.make_id = v.id
       LEFT JOIN drivers d ON v.driver_id = d.id
       WHERE b.id = $1 AND b.user_id = $2`,
      [bookingId, userId]
    );
    if (rows.length > 0 && rows[0].phone) {
      return rows[0].phone;
    }
  }
  return null;
};

const changeRoute = async (db, bookingId, userId, newDropoff) => {
  const result = await findBookingById(db, bookingId, userId);
  if (!result) {
    return null;
  }

  const { booking, source } = result;
  if (booking.status === 'completed' || booking.status === 'cancelled') {
    throw new Error(`Cannot change route for ${booking.status} booking`);
  }

  let updateField = '';
  if (source.type === 'mini_trip') {
    updateField = 'dropoff_location';
  } else if (source.type === 'to_airport' || source.type === 'from_airport') {
    updateField = 'destination_airport';
  } else {
    throw new Error('Route change not supported for this booking type');
  }

  const { rows } = await db.query(
    `UPDATE ${source.table}
     SET ${updateField} = $1
     WHERE id = $2 AND user_id = $3
     RETURNING *`,
    [newDropoff.location || newDropoff, bookingId, userId]
  );

  return mapBookingRecord(rows[0], source);
};

const getPreviousBooking = async (db, previousBookingId, userId) => {
  for (const source of BOOKING_SOURCES) {
    const { rows } = await db.query(
      `SELECT * FROM ${source.table} WHERE id = $1 AND user_id = $2`,
      [previousBookingId, userId]
    );
    if (rows.length > 0) {
      return { booking: rows[0], source };
    }
  }
  return null;
};

const updateBookingStatus = async (db, bookingId, userId, status) => {
  const result = await findBookingById(db, bookingId, userId);
  if (!result) {
    return null;
  }

  const { booking, source } = result;
  if (booking.status === 'completed' || booking.status === 'cancelled') {
    throw new Error(`Cannot change status of ${booking.status} booking`);
  }

  const { rows } = await db.query(
    `UPDATE ${source.table}
     SET status = $1, updated_at = NOW()
     WHERE id = $2 AND user_id = $3
     RETURNING *`,
    [status, bookingId, userId]
  );

  return { booking: rows[0], source };
};

module.exports = {
  findBookingById,
  cancelBooking,
  updateBooking,
  getDriverRatingForCustomer,
  getBookingDriver,
  getBookingVehicleId,
  getLiveLocation,
  getDriverPhone,
  changeRoute,
  getPreviousBooking,
  updateBookingStatus
};

