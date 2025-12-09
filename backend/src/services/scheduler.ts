import cron from 'node-cron';
import prisma from '../prisma/client';
import { queueNotification } from './notifications';
import pino from 'pino';

const logger = pino();

/**
 * Scheduled job to send vehicle and driver details to customers
 * Runs every 5 minutes and checks for bookings starting in ~1 hour
 */
export function startScheduledJobs() {
    // Run every 5 minutes
    cron.schedule('*/5 * * * *', async () => {
        try {
            await sendPreRideNotifications();
        } catch (error) {
            logger.error({ error }, 'Error in scheduled job');
        }
    });

    logger.info('Scheduled jobs started');
}

/**
 * Send pre-ride notifications to customers 1 hour before pickup
 */
async function sendPreRideNotifications() {
    const now = new Date();
    const oneHourFromNow = new Date(now.getTime() + 60 * 60 * 1000);
    const fiftyFiveMinutesFromNow = new Date(now.getTime() + 55 * 60 * 1000);

    // Find bookings that:
    // 1. Are assigned (have vehicle and driver)
    // 2. Pickup time is between 55-60 minutes from now
    // 3. Haven't been notified yet (we'll track this)
    const upcomingBookings = await prisma.booking.findMany({
        where: {
            status: 'assigned',
            pickupTime: {
                gte: fiftyFiveMinutesFromNow,
                lte: oneHourFromNow,
            },
            vehicleId: { not: null },
            driverId: { not: null },
        },
        include: {
            customer: true,
        },
    });

    logger.info(`Found ${upcomingBookings.length} bookings for pre-ride notifications`);

    for (const booking of upcomingBookings) {
        try {
            // Check if we already sent this notification
            const existingNotification = await prisma.notification.findFirst({
                where: {
                    type: 'booking.pre_ride_details',
                    payload: {
                        path: ['bookingId'],
                        equals: booking.id,
                    },
                },
            });

            if (existingNotification) {
                logger.info(`Pre-ride notification already sent for booking ${booking.id}`);
                continue;
            }

            // Get vehicle and driver details
            const vehicle = await prisma.vehicle.findUnique({
                where: { id: booking.vehicleId! },
            });

            const driver = await prisma.driver.findUnique({
                where: { id: booking.driverId! },
            });

            if (!vehicle || !driver) {
                logger.warn(`Missing vehicle or driver for booking ${booking.id}`);
                continue;
            }

            // Send notification to customer
            await queueNotification({
                targetId: booking.customerId,
                type: 'booking.pre_ride_details',
                channel: 'sms', // Can also be 'email' or 'push'
                payload: {
                    bookingId: booking.id,
                    pickupTime: booking.pickupTime,
                    pickupLocation: booking.pickupLocation,
                    destinationLocation: booking.destinationLocation,
                    vehicle: {
                        id: vehicle.id,
                        numberPlate: vehicle.numberPlate,
                        make: vehicle.make,
                        model: vehicle.model,
                    },
                    driver: {
                        id: driver.id,
                        name: driver.name,
                        mobile: driver.mobile,
                    },
                    otpCode: booking.otpCode,
                    message: `Your ride is scheduled in 1 hour. Driver: ${driver.name} (${driver.mobile}), Vehicle: ${vehicle.make} ${vehicle.model} (${vehicle.numberPlate}). OTP: ${booking.otpCode}`,
                },
            });

            logger.info(`Pre-ride notification sent for booking ${booking.id} to customer ${booking.customerId}`);
        } catch (error) {
            logger.error({ error, bookingId: booking.id }, 'Error sending pre-ride notification');
        }
    }
}

/**
 * Update booking status from 'upcoming' to 'today' for bookings scheduled today
 * Runs every hour
 */
export function startTodayBookingsUpdater() {
    cron.schedule('0 * * * *', async () => {
        try {
            const now = new Date();
            const startOfToday = new Date(now);
            startOfToday.setHours(0, 0, 0, 0);
            const endOfToday = new Date(now);
            endOfToday.setHours(23, 59, 59, 999);

            const result = await prisma.booking.updateMany({
                where: {
                    status: 'upcoming',
                    pickupTime: {
                        gte: startOfToday,
                        lte: endOfToday,
                    },
                },
                data: {
                    status: 'today',
                },
            });

            logger.info(`Updated ${result.count} bookings to 'today' status`);
        } catch (error) {
            logger.error({ error }, 'Error updating today bookings');
        }
    });
}
