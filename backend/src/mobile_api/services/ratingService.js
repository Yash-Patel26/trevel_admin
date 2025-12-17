const getRatings = async (db, filters = {}) => {
  const { userId, booking_id, booking_type, user_id, all } = filters;

  let query = 'SELECT * FROM ratings';
  const params = [];
  let paramIndex = 1;
  const conditions = [];

  if (all !== 'true' && !user_id) {
    conditions.push(`user_id = $${paramIndex++}`);
    params.push(userId);
  } else if (user_id) {
    conditions.push(`user_id = $${paramIndex++}`);
    params.push(user_id);
  }

  if (booking_id && booking_type) {
    conditions.push(`booking_id = $${paramIndex++} AND booking_type = $${paramIndex++}`);
    params.push(booking_id, booking_type);
  }

  if (conditions.length > 0) {
    query += ` WHERE ${conditions.join(' AND ')}`;
  }
  query += ' ORDER BY created_at DESC';

  const { rows } = await db.query(query, params);
  return rows;
};

const getRatingByBooking = async (db, userId, bookingId, bookingType) => {
  const { rows } = await db.query(
    'SELECT * FROM ratings WHERE user_id = $1 AND booking_id = $2 AND booking_type = $3',
    [userId, bookingId, bookingType]
  );
  return rows.length > 0 ? rows[0] : null;
};

const getRatingById = async (db, ratingId, userId = null) => {
  let query, params;
  if (userId) {
    query = 'SELECT * FROM ratings WHERE id = $1 AND user_id = $2';
    params = [ratingId, userId];
  } else {
    query = 'SELECT * FROM ratings WHERE id = $1';
    params = [ratingId];
  }
  const { rows } = await db.query(query, params);
  return rows.length > 0 ? rows[0] : null;
};

const crypto = require('crypto');

const createOrUpdateRating = async (db, ratingData) => {
  const {
    userId,
    booking_id,
    booking_type,
    rating,
    title,
    review,
    driver_rating,
    vehicle_rating,
    service_rating
  } = ratingData;

  const id = crypto.randomUUID();

  const { rows } = await db.query(
    `INSERT INTO ratings
     (id, user_id, booking_id, booking_type, rating, title, review, driver_rating, vehicle_rating, service_rating)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
     ON CONFLICT (user_id, booking_id, booking_type)
     DO UPDATE SET
       rating = EXCLUDED.rating,
       title = EXCLUDED.title,
       review = EXCLUDED.review,
       driver_rating = EXCLUDED.driver_rating,
       vehicle_rating = EXCLUDED.vehicle_rating,
       service_rating = EXCLUDED.service_rating,
       updated_at = NOW()
     RETURNING *`,
    [
      id,
      userId,
      booking_id,
      booking_type,
      rating,
      title || null,
      review || null,
      driver_rating || null,
      vehicle_rating || null,
      service_rating || null
    ]
  );

  return rows[0];
};

const updateRating = async (db, ratingId, userId, updateData, isAdminUpdate = false) => {
  const { rating, title, review, driver_rating, vehicle_rating, service_rating, is_featured } = updateData;

  const existing = await getRatingById(db, ratingId);
  if (!existing) {
    return null;
  }

  const updateFields = [];
  const values = [];
  let paramIndex = 1;

  if (rating !== undefined) {
    updateFields.push(`rating = $${paramIndex++}`);
    values.push(rating);
  }
  if (title !== undefined) {
    updateFields.push(`title = $${paramIndex++}`);
    values.push(title);
  }
  if (review !== undefined) {
    updateFields.push(`review = $${paramIndex++}`);
    values.push(review);
  }
  if (driver_rating !== undefined) {
    updateFields.push(`driver_rating = $${paramIndex++}`);
    values.push(driver_rating);
  }
  if (vehicle_rating !== undefined) {
    updateFields.push(`vehicle_rating = $${paramIndex++}`);
    values.push(vehicle_rating);
  }
  if (service_rating !== undefined) {
    updateFields.push(`service_rating = $${paramIndex++}`);
    values.push(service_rating);
  }
  if (is_featured !== undefined) {
    updateFields.push(`is_featured = $${paramIndex++}`);
    values.push(is_featured);
  }

  if (updateFields.length === 0) {
    throw new Error('No fields to update');
  }

  if (!isAdminUpdate) {
    values.push(ratingId, userId);
    const { rows } = await db.query(
      `UPDATE ratings
       SET ${updateFields.join(', ')}, updated_at = NOW()
       WHERE id = $${paramIndex++} AND user_id = $${paramIndex}
       RETURNING *`,
      values
    );
    return rows.length > 0 ? rows[0] : null;
  } else {
    values.push(ratingId);
    const { rows } = await db.query(
      `UPDATE ratings
       SET ${updateFields.join(', ')}, updated_at = NOW()
       WHERE id = $${paramIndex}
       RETURNING *`,
      values
    );
    return rows.length > 0 ? rows[0] : null;
  }
};

module.exports = {
  getRatings,
  getRatingByBooking,
  getRatingById,
  createOrUpdateRating,
  updateRating
};

