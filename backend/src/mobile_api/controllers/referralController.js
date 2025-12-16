const db = require('../config/postgresClient');
const referralService = require('../services/referralService');

const getReferralInfo = async (req, res) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({
        success: false,
        error: 'Unauthorized'
      });
    }

    let referralRecord = await referralService.getUserReferral(db, userId);
    let referralCode;
    if (!referralRecord) {
      referralCode = referralService.generateReferralCode(userId);
      await referralService.createUserReferral(db, userId, referralCode);
    } else {
      referralCode = referralRecord.referral_code;
    }

    const statsData = await referralService.getReferralStats(db, userId);

    res.status(200).json({
      success: true,
      data: {
        referral_code: referralCode,
        total_referrals: parseInt(statsData.total_referrals || 0),
        successful_referrals: parseInt(statsData.successful_referrals || 0),
        total_earnings: parseFloat(statsData.total_earnings || 0),
        currency: 'INR',
        reward_per_referral: 100 // ₹100 per successful referral
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to fetch referral info',
      message: error.message
    });
  }
};

const applyReferralCode = async (req, res) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({
        success: false,
        error: 'Unauthorized'
      });
    }

    const { referral_code } = req.body;

    if (!referral_code) {
      return res.status(400).json({
        success: false,
        error: 'Referral code is required'
      });
    }

    const referrer = await referralService.getReferrerByCode(db, referral_code);
    if (!referrer) {
      return res.status(404).json({
        success: false,
        error: 'Invalid referral code'
      });
    }

    const referrerId = referrer.user_id;
    if (referrerId === userId) {
      return res.status(400).json({
        success: false,
        error: 'Cannot use your own referral code'
      });
    }

    const hasExisting = await referralService.hasExistingReferralTransaction(db, userId);
    if (hasExisting) {
      return res.status(400).json({
        success: false,
        error: 'Referral code already applied'
      });
    }

    const transactionId = await referralService.createReferralTransaction(
      db,
      referrerId,
      userId,
      referral_code
    );

    res.status(200).json({
      success: true,
      message: 'Referral code applied successfully',
      data: {
        referral_code: referral_code.toUpperCase(),
        transaction_id: transactionId
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to apply referral code',
      message: error.message
    });
  }
};

module.exports = {
  getReferralInfo,
  applyReferralCode
};

