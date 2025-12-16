const getSavedLocations = async (db, userId) => {
  const { rows } = await db.query(
    'SELECT * FROM saved_locations WHERE user_id = $1 ORDER BY is_default DESC, created_at DESC',
    [userId]
  );
  return rows;
};

const getSavedLocationById = async (db, locationId, userId) => {
  const { rows } = await db.query(
    'SELECT * FROM saved_locations WHERE id = $1 AND user_id = $2',
    [locationId, userId]
  );
  return rows.length > 0 ? rows[0] : null;
};

const unsetDefaultLocations = async (db, userId, excludeId = null) => {
  if (excludeId) {
    await db.query(
      'UPDATE saved_locations SET is_default = FALSE WHERE user_id = $1 AND id != $2',
      [userId, excludeId]
    );
  } else {
    await db.query(
      'UPDATE saved_locations SET is_default = FALSE WHERE user_id = $1',
      [userId]
    );
  }
};

const createSavedLocation = async (db, locationData) => {
  const {
    userId,
    name,
    address,
    latitude,
    longitude,
    city,
    state,
    country,
    postal_code,
    is_default
  } = locationData;

  if (is_default === true) {
    await unsetDefaultLocations(db, userId);
  }

  const { rows } = await db.query(
    `INSERT INTO saved_locations
     (user_id, name, address, latitude, longitude, city, state, country, postal_code, is_default)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
     RETURNING *`,
    [
      userId,
      name,
      address,
      latitude || null,
      longitude || null,
      city || null,
      state || null,
      country || 'India',
      postal_code || null,
      is_default || false
    ]
  );

  return rows[0];
};

const updateSavedLocation = async (db, locationId, userId, updateData) => {
  const { name, address, latitude, longitude, city, state, country, postal_code, is_default } = updateData;

  const existing = await getSavedLocationById(db, locationId, userId);
  if (!existing) {
    return null;
  }

  if (is_default === true) {
    await unsetDefaultLocations(db, userId, locationId);
  }

  const updateFields = [];
  const values = [];
  let paramIndex = 1;

  if (name !== undefined) {
    updateFields.push(`name = $${paramIndex++}`);
    values.push(name);
  }
  if (address !== undefined) {
    updateFields.push(`address = $${paramIndex++}`);
    values.push(address);
  }
  if (latitude !== undefined) {
    updateFields.push(`latitude = $${paramIndex++}`);
    values.push(latitude);
  }
  if (longitude !== undefined) {
    updateFields.push(`longitude = $${paramIndex++}`);
    values.push(longitude);
  }
  if (city !== undefined) {
    updateFields.push(`city = $${paramIndex++}`);
    values.push(city);
  }
  if (state !== undefined) {
    updateFields.push(`state = $${paramIndex++}`);
    values.push(state);
  }
  if (country !== undefined) {
    updateFields.push(`country = $${paramIndex++}`);
    values.push(country);
  }
  if (postal_code !== undefined) {
    updateFields.push(`postal_code = $${paramIndex++}`);
    values.push(postal_code);
  }
  if (is_default !== undefined) {
    updateFields.push(`is_default = $${paramIndex++}`);
    values.push(is_default);
  }

  if (updateFields.length === 0) {
    throw new Error('No fields to update');
  }

  values.push(locationId, userId);
  const { rows } = await db.query(
    `UPDATE saved_locations
     SET ${updateFields.join(', ')}, updated_at = NOW()
     WHERE id = $${paramIndex++} AND user_id = $${paramIndex}
     RETURNING *`,
    values
  );

  return rows[0];
};

const deleteSavedLocation = async (db, locationId, userId) => {
  const { rows } = await db.query(
    'DELETE FROM saved_locations WHERE id = $1 AND user_id = $2 RETURNING *',
    [locationId, userId]
  );
  return rows.length > 0 ? rows[0] : null;
};

module.exports = {
  getSavedLocations,
  getSavedLocationById,
  createSavedLocation,
  updateSavedLocation,
  deleteSavedLocation
};

