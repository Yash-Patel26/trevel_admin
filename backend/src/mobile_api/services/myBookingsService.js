const checkTableExists = async (db, tableName) => {
  const { rows } = await db.query('SELECT to_regclass($1) AS exists', [`public.${tableName}`]);
  return Boolean(rows[0]?.exists);
};

const checkColumnExists = async (db, tableName, columnName) => {
  const query = `
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = $1 AND column_name = $2
    LIMIT 1
  `;
  const { rows } = await db.query(query, [tableName, columnName]);
  return rows.length > 0;
};

const fetchBookingsFromSource = async (db, source, userId, status = null) => {
  try {
    const params = [userId];
    let whereClause = 'WHERE b.user_id = $1';

    if (status) {
      const normalizedStatus = status.toLowerCase();
      if (normalizedStatus === 'upcoming' || normalizedStatus === 'in_progress' || normalizedStatus === 'active') {
        whereClause += ` AND b.status IN ('pending', 'confirmed', 'assigned', 'in_progress', 'searching', 'accepted')`;
      } else if (normalizedStatus === 'completed') {
        whereClause += ` AND b.status = 'completed'`;
      } else if (normalizedStatus === 'cancelled') {
        whereClause += ` AND b.status = 'cancelled'`;
      } else {
        params.push(status);
        whereClause += ` AND b.status = $${params.length}`;
      }
    }

    let driverTableExists = false;
    let vehicleHasDriverId = false;
    let vehicleHasImageUrl = false;
    let canJoinDrivers = false;
    let bookingHasMakeId = false;

    try {
      driverTableExists = await checkTableExists(db, 'drivers');
      vehicleHasDriverId = await checkColumnExists(db, 'makes', 'driver_id');
      vehicleHasImageUrl = await checkColumnExists(db, 'makes', 'image_url');
      bookingHasMakeId = await checkColumnExists(db, source.table.replace('public.', '').split('.')[0], 'make_id');
      canJoinDrivers = driverTableExists && vehicleHasDriverId;
    } catch (checkError) {
      }

    const selectFields = ['b.*'];
    const joins = [];
    
    // Only join with makes table if make_id column exists
    if (bookingHasMakeId) {
      selectFields.push('v.model AS vehicle_model', 'v.number_plate AS vehicle_number_plate');
      if (vehicleHasImageUrl) {
        selectFields.push('v.image_url AS make_image_url');
      }
      if (canJoinDrivers) {
        selectFields.push('d.full_name AS driver_name', 'd.phone AS driver_phone');
      }
      joins.push('LEFT JOIN makes v ON b.make_id = v.id');
      if (canJoinDrivers) {
        joins.push('LEFT JOIN drivers d ON v.driver_id = d.id');
      }
    }

    const tableExists = await checkTableExists(db, source.table.replace('public.', '').split('.')[0]);
    if (!tableExists) {
      return [];
    }

    const query = `
      SELECT
        ${selectFields.join(',\n      ')}
      FROM ${source.table} b
      ${joins.join('\n      ')}
      ${whereClause}
    `;

    const { rows } = await db.query(query, params);
    return rows;
  } catch (error) {
    if (error.message && error.message.includes('does not exist')) {
      return [];
    }
    throw error;
  }
};

const fetchBookingById = async (db, source, bookingId, userId) => {
  const driverTableExists = await checkTableExists(db, 'drivers');
  const vehicleHasDriverId = await checkColumnExists(db, 'makes', 'driver_id');
  const vehicleHasImageUrl = await checkColumnExists(db, 'makes', 'image_url');
  const bookingHasMakeId = await checkColumnExists(db, source.table.replace('public.', '').split('.')[0], 'make_id');
  const canJoinDrivers = driverTableExists && vehicleHasDriverId;

  const selectFields = ['b.*'];
  const joins = [];
  
  // Only join with makes table if make_id column exists
  if (bookingHasMakeId) {
    selectFields.push('v.model AS vehicle_model', 'v.number_plate AS vehicle_number_plate');
    if (vehicleHasImageUrl) {
      selectFields.push('v.image_url AS make_image_url');
    }
    if (canJoinDrivers) {
      selectFields.push('d.full_name AS driver_name', 'd.phone AS driver_phone');
    }
    joins.push('LEFT JOIN makes v ON b.make_id = v.id');
    if (canJoinDrivers) {
      joins.push('LEFT JOIN drivers d ON v.driver_id = d.id');
    }
  }

  const query = `
    SELECT
      ${selectFields.join(',\n      ')}
    FROM ${source.table} b
    ${joins.join('\n      ')}
    WHERE b.id = $1 AND b.user_id = $2
    LIMIT 1
  `;

  const { rows } = await db.query(query, [bookingId, userId]);
  return rows.length > 0 ? rows[0] : null;
};

const fetchUpcomingRidesFromSource = async (db, source, userId, nowStr, sevenDaysStr) => {
  try {
    const params = [userId, nowStr, sevenDaysStr];
    const whereClause = `
      WHERE b.user_id = $1
      AND (
        (b.status IN ('in_progress', 'assigned', 'searching', 'accepted'))
        OR
        (b.pickup_date >= $2 AND b.pickup_date <= $3 AND b.status IN ('pending', 'confirmed'))
      )
    `;

    let driverTableExists = false;
    let vehicleHasDriverId = false;
    let vehicleHasImageUrl = false;
    let canJoinDrivers = false;
    let bookingHasMakeId = false;

    try {
      driverTableExists = await checkTableExists(db, 'drivers');
      vehicleHasDriverId = await checkColumnExists(db, 'makes', 'driver_id');
      vehicleHasImageUrl = await checkColumnExists(db, 'makes', 'image_url');
      bookingHasMakeId = await checkColumnExists(db, source.table.replace('public.', '').split('.')[0], 'make_id');
      canJoinDrivers = driverTableExists && vehicleHasDriverId;
    } catch (checkError) {
      }

    const tableExists = await checkTableExists(db, source.table.replace('public.', '').split('.')[0]);
    if (!tableExists) {
      return [];
    }

    const selectFields = ['b.*'];
    const joins = [];
    
    // Only join with makes table if make_id column exists
    if (bookingHasMakeId) {
      selectFields.push('v.model AS vehicle_model', 'v.number_plate AS vehicle_number_plate');
      if (vehicleHasImageUrl) {
        selectFields.push('v.image_url AS make_image_url');
      }
      if (canJoinDrivers) {
        selectFields.push('d.full_name AS driver_name', 'd.phone AS driver_phone');
      }
      joins.push('LEFT JOIN makes v ON b.make_id = v.id');
      if (canJoinDrivers) {
        joins.push('LEFT JOIN drivers d ON v.driver_id = d.id');
      }
    }

    const query = `
      SELECT
        ${selectFields.join(',\n      ')}
      FROM ${source.table} b
      ${joins.join('\n      ')}
      ${whereClause}
    `;

    const { rows } = await db.query(query, params);
    return rows;
  } catch (error) {
    if (error.message && error.message.includes('does not exist')) {
      return [];
    }
    throw error;
  }
};

module.exports = {
  checkTableExists,
  checkColumnExists,
  fetchBookingsFromSource,
  fetchBookingById,
  fetchUpcomingRidesFromSource
};

