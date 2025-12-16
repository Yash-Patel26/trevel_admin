const { ensurePromoCodesTableExists } = require('../utils/ensurePromoCodesTable');

const getPromoCodeByCode = async (db, code, userId) => {
  await ensurePromoCodesTableExists(db);
  const promoCode = code.trim().toUpperCase();
  const query = `
    SELECT
      id,
      code,
      amount,
      status,
      used_at,
      expires_at,
      created_at
    FROM promo_codes
    WHERE code = $1 AND user_id = $2
  `;
  const { rows } = await db.query(query, [promoCode, userId]);
  return rows.length > 0 ? rows[0] : null;
};

const markPromoCodeAsExpired = async (db, promoId) => {
  await db.query(
    'UPDATE promo_codes SET status = $1 WHERE id = $2',
    ['expired', promoId]
  );
};

const findBookingInTables = async (db, bookingId, userId) => {
  const bookingSources = [
    { table: 'mini_trip_bookings', type: 'mini_trip' },
    { table: 'hourly_rental_bookings', type: 'hourly_rental' },
    { table: 'to_airport_transfer_bookings', type: 'to_airport' },
    { table: 'from_airport_transfer_bookings', type: 'from_airport' }
  ];

  for (const source of bookingSources) {
    try {
      const query = `SELECT * FROM ${source.table} WHERE id = $1 AND user_id = $2`;
      const { rows } = await db.query(query, [bookingId, userId]);
      if (rows.length > 0) {
        return { table: source.table, type: source.type, booking: rows[0] };
      }
    } catch (error) {
      continue;
    }
  }
  return null;
};

const applyPromoCodeToBooking = async (db, promoId, bookingId, promoCode, discountAmount, newFinalPrice, userId, tableName) => {
  const client = await db.getClient();
  try {
    await client.query('BEGIN');

    const updateBookingQuery = `
      UPDATE ${tableName}
      SET
        promo_code = $1,
        promo_discount = $2,
        final_price = $3,
        updated_at = NOW()
      WHERE id = $4 AND user_id = $5
      RETURNING *
    `;
    const { rows: updatedRows } = await client.query(updateBookingQuery, [
      promoCode,
      discountAmount,
      newFinalPrice,
      bookingId,
      userId
    ]);

    if (updatedRows.length === 0) {
      await client.query('ROLLBACK');
      return null;
    }

    const updatePromoQuery = `
      UPDATE promo_codes
      SET
        status = 'used',
        used_at = NOW(),
        booking_id = $1,
        updated_at = NOW()
      WHERE id = $2
    `;
    await client.query(updatePromoQuery, [bookingId, promoId]);

    await client.query('COMMIT');
    return updatedRows[0];
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

module.exports = {
  getPromoCodeByCode,
  markPromoCodeAsExpired,
  findBookingInTables,
  applyPromoCodeToBooking
};

