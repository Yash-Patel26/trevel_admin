const db = require('../config/postgresClient');
const userStatisticsService = require('../services/userStatisticsService');

const getUserStatistics = async (req, res) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({
        success: false,
        error: 'Unauthorized'
      });
    }

    const results = await userStatisticsService.getBookingStatistics(db, userId);

    let totalBookings = 0;
    let completedBookings = 0;
    let totalDistanceKm = 0;
    let totalSpent = 0;
    const bookingsByType = {
      mini_trips: 0,
      hourly_rentals: 0,
      airport_transfers: 0
    };

    results.forEach(result => {
      const total = parseInt(result.total) || 0;
      const completed = parseInt(result.completed) || 0;
      const distance = parseFloat(result.total_distance) || 0;
      const spent = parseFloat(result.total_spent) || 0;

      totalBookings += total;
      completedBookings += completed;
      totalDistanceKm += distance;
      totalSpent += spent;

      if (result.type === 'mini_trip') {
        bookingsByType.mini_trips = total;
      } else if (result.type === 'hourly_rental') {
        bookingsByType.hourly_rentals = total;
      } else if (result.type === 'to_airport' || result.type === 'from_airport') {
        bookingsByType.airport_transfers += total;
      }
    });

    const memberSince = await userStatisticsService.getUserCreationDate(db, userId);

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

    const ratingStats = await userStatisticsService.getRatingStatistics(db, userId);
    const averageRating = ratingStats.average;
    const ratingCount = ratingStats.count;

    const paymentCount = await userStatisticsService.getPaymentCount(db, userId);

    res.status(200).json({
      success: true,
      data: {
        total_bookings: totalBookings,
        completed_bookings: completedBookings,
        pending_bookings: totalBookings - completedBookings,
        total_trips: totalTrips,
        total_distance_km: parseFloat(totalDistanceKm.toFixed(2)),
        co2_savings: co2SavingsFormatted,
        co2_savings_grams: co2SavingsGrams,
        trees_planted: treesPlanted,
        total_spent: parseFloat(totalSpent.toFixed(2)),
        currency: 'INR',
        payment_count: paymentCount,
        average_rating_given: averageRating,
        rating_count: ratingCount,
        member_since: memberSince,
        bookings_by_type: bookingsByType
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to fetch user statistics',
      message: error.message
    });
  }
};
module.exports = {
getUserStatistics
};
