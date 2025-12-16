const crypto = require('crypto');

const generateReferralCode = (userId) => {
  const uuid = crypto.randomUUID().replace(/-/g, '').substring(0, 6).toUpperCase();
  const userIdStr = userId.toString().slice(-4);
  return `TREVEL${uuid}${userIdStr}`;
};

const getUserReferral = async (db, userId) => {
  const { rows } = await db.query(
    'SELECT * FROM user_referrals WHERE user_id = $1',
    [userId]
  );
  return rows.length > 0 ? rows[0] : null;
};

const createUserReferral = async (db, userId, referralCode) => {
  await db.query(
    `INSERT INTO user_referrals (user_id, referral_code, total_referrals, total_earnings)
     VALUES ($1, $2, 0, 0)`,
    [userId, referralCode]
  );
  return { user_id: userId, referral_code: referralCode, total_referrals: 0, total_earnings: 0 };
};

const getReferralStats = async (db, userId) => {
  const { rows } = await db.query(
    `SELECT
      COUNT(*) as total_referrals,
      COUNT(*) FILTER (WHERE status = 'completed') as successful_referrals,
      COALESCE(SUM(referrer_reward), 0) as total_earnings
     FROM referral_transactions
     WHERE referrer_id = $1`,
    [userId]
  );
  return rows[0] || {
    total_referrals: 0,
    successful_referrals: 0,
    total_earnings: 0
  };
};

const getReferrerByCode = async (db, referralCode) => {
  const { rows } = await db.query(
    'SELECT * FROM user_referrals WHERE referral_code = $1',
    [referralCode.toUpperCase()]
  );
  return rows.length > 0 ? rows[0] : null;
};

const hasExistingReferralTransaction = async (db, userId) => {
  const { rows } = await db.query(
    'SELECT * FROM referral_transactions WHERE referred_user_id = $1',
    [userId]
  );
  return rows.length > 0;
};

const createReferralTransaction = async (db, referrerId, referredUserId, referralCode) => {
  const transactionId = crypto.randomUUID();
  await db.query(
    `INSERT INTO referral_transactions
     (id, referrer_id, referred_user_id, referral_code, status, referrer_reward, referred_reward)
     VALUES ($1, $2, $3, $4, 'pending', 0, 0)`,
    [transactionId, referrerId, referredUserId, referralCode.toUpperCase()]
  );
  return transactionId;
};

module.exports = {
  generateReferralCode,
  getUserReferral,
  createUserReferral,
  getReferralStats,
  getReferrerByCode,
  hasExistingReferralTransaction,
  createReferralTransaction
};

