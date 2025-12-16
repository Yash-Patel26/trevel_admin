const findBookingInTables = async (db, bookingUuid, bookingType = null) => {
  if (bookingType) {
    let tableName;
    switch (bookingType) {
      case 'mini_trip':
        tableName = 'mini_trip_bookings';
        break;
      case 'to_airport':
        tableName = 'to_airport_transfer_bookings';
        break;
      case 'from_airport':
        tableName = 'from_airport_transfer_bookings';
        break;
      default:
        return null;
    }
    const result = await db.query(
      `SELECT * FROM ${tableName} WHERE id = $1`,
      [bookingUuid]
    );
    return result.rows.length > 0 ? { table: tableName, record: result.rows[0] } : null;
  } else {

    const tables = [
      { name: 'mini_trip_bookings', type: 'mini_trip' },
      { name: 'to_airport_transfer_bookings', type: 'to_airport' },
      { name: 'from_airport_transfer_bookings', type: 'from_airport' }
    ];

    for (const table of tables) {
      const result = await db.query(
        `SELECT * FROM ${table.name} WHERE id = $1`,
        [bookingUuid]
      );
      if (result.rows.length > 0) {
        return { table: table.name, record: result.rows[0] };
      }
    }
    return null;
  }
};

const updateBookingWithActualDistance = async (db, tableName, bookingUuid, updateData) => {
  const {
    actual_distance_km,
    actual_time_minutes,
    route_type,
    price_adjusted,
    adjusted_final_price,
    price_adjustment_reason,
    final_price
  } = updateData;

  const updateQuery = `
    UPDATE ${tableName}
    SET
      actual_distance_km = $1,
      actual_time_minutes = $2,
      route_type = $3,
      price_adjusted = $4,
      adjusted_final_price = $5,
      price_adjustment_reason = $6,
      final_price = $7,
      updated_at = NOW()
    WHERE id = $8
    RETURNING *
  `;

  const updateValues = [
    actual_distance_km,
    actual_time_minutes || null,
    route_type,
    price_adjusted,
    adjusted_final_price,
    price_adjustment_reason,
    final_price,
    bookingUuid
  ];

  const { rows } = await db.query(updateQuery, updateValues);
  return rows.length > 0 ? rows[0] : null;
};

module.exports = {
  findBookingInTables,
  updateBookingWithActualDistance
};

