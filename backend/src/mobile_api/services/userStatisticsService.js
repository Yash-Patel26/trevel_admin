const prisma = require('../../prisma/client').default;

const getBookingStatistics = async (db, userId) => {
  // Use Prisma to get statistics from each booking table
  // We ignore 'db' argument and use imported prisma client

  // 1. Mini Trips
  const miniTripsStats = await prisma.miniTripBooking.aggregate({
    where: { userId: userId },
    _count: {
      _all: true,
      status: true // We'll filter for completed manually or use separate count
    },
    _sum: {
      estimatedDistanceKm: true,
      finalPrice: true
    }
  });

  const miniTripsCompleted = await prisma.miniTripBooking.count({
    where: {
      userId: userId,
      status: 'completed'
    }
  });

  // 2. Hourly Rentals
  const hourlyStats = await prisma.hourlyRentalBooking.aggregate({
    where: { userId: userId },
    _count: { _all: true },
    _sum: {
      coveredDistanceKm: true,
      finalPrice: true
    }
  });

  const hourlyCompleted = await prisma.hourlyRentalBooking.count({
    where: {
      userId: userId,
      status: 'completed'
    }
  });

  // 3. To Airport
  const toAirportStats = await prisma.toAirportTransferBooking.aggregate({
    where: { userId: userId },
    _count: { _all: true },
    _sum: {
      estimatedDistanceKm: true,
      finalPrice: true
    }
  });

  const toAirportCompleted = await prisma.toAirportTransferBooking.count({
    where: {
      userId: userId,
      status: 'completed'
    }
  });

  // 4. From Airport
  const fromAirportStats = await prisma.fromAirportTransferBooking.aggregate({
    where: { userId: userId },
    _count: { _all: true },
    _sum: {
      estimatedDistanceKm: true,
      finalPrice: true
    }
  });

  const fromAirportCompleted = await prisma.fromAirportTransferBooking.count({
    where: {
      userId: userId,
      status: 'completed'
    }
  });

  return [
    {
      type: 'mini_trip',
      total: miniTripsStats._count._all || 0,
      completed: miniTripsCompleted || 0,
      total_distance: miniTripsStats._sum.estimatedDistanceKm || 0,
      total_spent: miniTripsStats._sum.finalPrice || 0
    },
    {
      type: 'hourly_rental',
      total: hourlyStats._count._all || 0,
      completed: hourlyCompleted || 0,
      total_distance: hourlyStats._sum.coveredDistanceKm || 0,
      total_spent: hourlyStats._sum.finalPrice || 0
    },
    {
      type: 'to_airport',
      total: toAirportStats._count._all || 0,
      completed: toAirportCompleted || 0,
      total_distance: toAirportStats._sum.estimatedDistanceKm || 0,
      total_spent: toAirportStats._sum.finalPrice || 0
    },
    {
      type: 'from_airport',
      total: fromAirportStats._count._all || 0,
      completed: fromAirportCompleted || 0,
      total_distance: fromAirportStats._sum.estimatedDistanceKm || 0,
      total_spent: fromAirportStats._sum.finalPrice || 0
    }
  ];
};

const getUserCreationDate = async (db, userId) => {
  try {
    // db argument ignored, using prisma
    // Customer model does NOT have createdAt in this schema.
    // Return null or hardcoded date if needed, but for now just return null to avoid crash.

    // Check if user exists just to be safe, but don't select invalid field.
    const customer = await prisma.customer.findUnique({
      where: { id: userId },
      select: { id: true } // Select minimal field
    });

    return null;
  } catch (error) {
    console.error('Error getting user creation date:', error);
    return null;
  }
};

const getRatingStatistics = async (db, userId) => {
  try {
    // Rating model: rating (Int)
    const aggregations = await prisma.rating.aggregate({
      where: { userId: userId },
      _count: { rating: true },
      _avg: { rating: true }
    });

    return {
      count: aggregations._count.rating || 0,
      average: aggregations._avg.rating ? aggregations._avg.rating.toFixed(1) : '0.0'
    };
  } catch (error) {
    return { count: 0, average: '0.0' };
  }
};

const getPaymentCount = async (db, userId) => {
  try {
    // Payment model: userId, status
    // The raw query used DISTINCT booking_id
    // Prisma distinct is supported.
    const result = await prisma.payment.findMany({
      where: {
        userId: userId,
        status: { in: ['SUCCESS', 'CAPTURED', 'PAID'] }
      },
      distinct: ['tripId'], // Using tripId as booking_id mapper
      select: { tripId: true }
    });

    return result.length;
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

