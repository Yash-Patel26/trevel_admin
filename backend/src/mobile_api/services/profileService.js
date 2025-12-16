const { ensurePromoCodesTableExists } = require('../utils/ensurePromoCodesTable');
const userStatisticsService = require('./userStatisticsService');

const normalizeProfileResponse = (record, statistics = null) => {
  // Ensure full_name is never empty - use multiple fallbacks
  const fullName = record.full_name || 
                   record.name || 
                   record.user_metadata?.full_name ||
                   record.user_metadata?.name ||
                   (record.phone ? record.phone.replace(/^\+91/, '') : '') ||
                   'User';
  
  const baseResponse = {
    id: record.id,
    full_name: fullName,
    email: record.email || '',
    phone: record.phone || '',
    emergency_contact: record.emergency_contact || null,
    profile_image_url: record.profile_image_url || record.image_url || null,
    gender: record.gender || null,
    date_of_birth: record.date_of_birth || null,
    address: record.address || null,
    created_at: record.created_at,
    updated_at: record.updated_at || record.created_at
  };

  // Add statistics if provided
  if (statistics) {
    baseResponse.total_trips = statistics.total_trips || 0;
    baseResponse.co2_savings = statistics.co2_savings || '0g';
    baseResponse.trees_planted = statistics.trees_planted || 0.00;
  } else {
    // Default values if statistics not provided
    baseResponse.total_trips = 0;
    baseResponse.co2_savings = '0g';
    baseResponse.trees_planted = 0.00;
  }

  return baseResponse;
};

const getUserById = async (db, userId) => {
  const { rows } = await db.query('SELECT * FROM users WHERE id = $1 LIMIT 1', [userId]);
  return rows.length > 0 ? rows[0] : null;
};

const getUserStatistics = async (db, userId) => {
  try {
    const results = await userStatisticsService.getBookingStatistics(db, userId);
    
    let completedBookings = 0;
    let totalDistanceKm = 0;
    
    results.forEach(result => {
      const completed = parseInt(result.completed) || 0;
      const distance = parseFloat(result.total_distance) || 0;
      completedBookings += completed;
      totalDistanceKm += distance;
    });
    
    const CO2_GRAMS_PER_KM_SAVED = 100;
    const co2SavingsGrams = Math.round(totalDistanceKm * CO2_GRAMS_PER_KM_SAVED);
    let co2SavingsFormatted;
    if (co2SavingsGrams >= 1000) {
      const kg = (co2SavingsGrams / 1000).toFixed(2);
      co2SavingsFormatted = `${kg}kg`;
    } else {
      co2SavingsFormatted = `${co2SavingsGrams}g`;
    }
    
    const CO2_PER_TREE_PER_YEAR_GRAMS = 21000;
    const treesPlanted = parseFloat((co2SavingsGrams / CO2_PER_TREE_PER_YEAR_GRAMS).toFixed(2));
    const totalTrips = completedBookings;
    
    return {
      total_trips: totalTrips,
      co2_savings: co2SavingsFormatted,
      trees_planted: treesPlanted
    };
  } catch (error) {
    // Return default values if statistics calculation fails
    return {
      total_trips: 0,
      co2_savings: '0g',
      trees_planted: 0.00
    };
  }
};

const createUserProfile = async (db, userData) => {
  const { userId, full_name, email, phone } = userData;
  const insertQuery = `
    INSERT INTO users (id, full_name, email, phone)
    VALUES ($1, $2, $3, $4)
    RETURNING *
  `;
  const insertValues = [userId, full_name, email, phone];
  const insertResult = await db.query(insertQuery, insertValues);
  return insertResult.rows[0];
};

const ensureProfileExists = async (db, userData) => {
  const { userId, full_name, email, phone } = userData;
  const existing = await getUserById(db, userId);
  if (existing) {
    return existing;
  }
  return await createUserProfile(db, { userId, full_name, email, phone });
};

const updateUserFullName = async (db, userId, fullName) => {
  const updateQuery = 'UPDATE users SET full_name = $1, updated_at = NOW() WHERE id = $2 RETURNING *';
  const result = await db.query(updateQuery, [fullName, userId]);
  return result.rows[0];
};

const updateUserProfile = async (db, userId, updateData) => {
  const fields = Object.entries(updateData);
  if (fields.length === 0) {
    throw new Error('No fields to update');
  }

  const setClauses = fields.map(([key], index) => `${key} = $${index + 1}`);
  const values = fields.map(([, value]) => value === null || value === '' ? null : value);
  values.push(userId);

  const updateQuery = `
    UPDATE users
    SET ${setClauses.join(', ')}, updated_at = NOW()
    WHERE id = $${values.length}
    RETURNING *
  `;

  const result = await db.query(updateQuery, values);
  return result.rows[0];
};

const getUserPromoCodes = async (db, userId) => {
  await ensurePromoCodesTableExists(db);

  const query = `
    SELECT
      id,
      code,
      amount,
      booking_id,
      reason,
      status,
      used_at,
      expires_at,
      created_at
    FROM promo_codes
    WHERE user_id = $1
    AND status IN ('active', 'used')
    AND (expires_at IS NULL OR expires_at > NOW())
    ORDER BY created_at DESC
  `;

  const { rows } = await db.query(query, [userId]);

  return rows.map(row => ({
    id: row.id,
    code: row.code,
    amount: parseFloat(row.amount),
    bookingId: row.booking_id,
    reason: row.reason,
    status: row.status,
    usedAt: row.used_at,
    expiresAt: row.expires_at,
    createdAt: row.created_at,
    isExpired: row.expires_at ? new Date(row.expires_at) < new Date() : false
  }));
};

module.exports = {
  normalizeProfileResponse,
  getUserById,
  createUserProfile,
  updateUserFullName,
  ensureProfileExists,
  updateUserProfile,
  getUserPromoCodes,
  getUserStatistics
};

