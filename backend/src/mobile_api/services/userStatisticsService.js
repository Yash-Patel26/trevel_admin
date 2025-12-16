const getBookingStatistics = async (db, userId) => {
  const bookingQueries = [
    {
      query: `
        SELECT
          COUNT(*) as total,
          COUNT(*) FILTER (WHERE status = 'completed') as completed,
          COALESCE(SUM(estimated_distance_km), 0) as total_distance,
          COALESCE(SUM(final_price), 0) as total_spent
        FROM mini_trip_bookings
        WHERE user_id = $1
      `,
      type: 'mini_trip'
    },
    {
      query: `
        SELECT
          COUNT(*) as total,
          COUNT(*) FILTER (WHERE status = 'completed') as completed,
          COALESCE(SUM(covered_distance_km), 0) as total_distance,
          COALESCE(SUM(final_price), 0) as total_spent
        FROM hourly_rental_bookings
        WHERE user_id = $1
      `,
      type: 'hourly_rental'
    },
    {
      query: `
        SELECT
          COUNT(*) as total,
          COUNT(*) FILTER (WHERE status = 'completed') as completed,
          COALESCE(SUM(estimated_distance_km), 0) as total_distance,
          COALESCE(SUM(final_price), 0) as total_spent
        FROM to_airport_transfer_bookings
        WHERE user_id = $1
      `,
      type: 'to_airport'
    },
    {
      query: `
        SELECT
          COUNT(*) as total,
          COUNT(*) FILTER (WHERE status = 'completed') as completed,
          COALESCE(SUM(estimated_distance_km), 0) as total_distance,
          COALESCE(SUM(final_price), 0) as total_spent
        FROM from_airport_transfer_bookings
        WHERE user_id = $1
      `,
      type: 'from_airport'
    }
  ];

  const results = await Promise.all(
    bookingQueries.map(async ({ query, type }) => {
      try {
        const { rows } = await db.query(query, [userId]);
        return {
          type,
          ...rows[0]
        };
      } catch (error) {
        if (error.message.includes('does not exist')) {
          return {
            type,
            total: '0',
            completed: '0',
            total_distance: '0',
            total_spent: '0'
          };
        }
        throw error;
      }
    })
  );

  return results;
};

const getUserCreationDate = async (db, userId) => {
  try {
    const { rows } = await db.query('SELECT created_at FROM users WHERE id = $1', [userId]);
    return rows.length > 0 && rows[0].created_at ? rows[0].created_at : null;
  } catch (error) {
    return null;
  }
};

const getRatingStatistics = async (db, userId) => {
  try {
    const ratingQuery = `
      SELECT
        COUNT(*) as count,
        COALESCE(AVG(rating), 0) as average
      FROM ratings
      WHERE user_id = $1
    `;
    const { rows } = await db.query(ratingQuery, [userId]);
    if (rows.length > 0) {
      return {
        count: parseInt(rows[0].count) || 0,
        average: parseFloat(rows[0].average || 0).toFixed(1)
      };
    }
    return { count: 0, average: '0.0' };
  } catch (error) {
    return { count: 0, average: '0.0' };
  }
};

const getPaymentCount = async (db, userId) => {
  try {
    const paymentQuery = `
      SELECT COUNT(DISTINCT booking_id) as count
      FROM payments
      WHERE user_id = $1 AND status IN ('SUCCESS', 'CAPTURED', 'PAID')
    `;
    const { rows } = await db.query(paymentQuery, [userId]);
    return rows.length > 0 ? parseInt(rows[0].count) || 0 : 0;
  } catch (error) {
    return 0;
  }
};

module.exports = {
  getBookingStatistics,
  getUserCreationDate,
  getRatingStatistics,
  getPaymentCount
};

