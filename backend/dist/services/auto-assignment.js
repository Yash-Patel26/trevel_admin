"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.autoAssignBooking = autoAssignBooking;
exports.batchAutoAssign = batchAutoAssign;
const client_1 = __importDefault(require("../prisma/client"));
const notifications_1 = require("./notifications");
const otp_1 = require("../utils/otp");
const audit_1 = require("../utils/audit");
const pino_1 = __importDefault(require("pino"));
const logger = (0, pino_1.default)();
/**
 * Automatically assign driver and vehicle to a booking
 * Called when a new booking is created
 */
async function autoAssignBooking(bookingId) {
    try {
        const booking = await client_1.default.booking.findUnique({
            where: { id: bookingId },
            include: { customer: true },
        });
        if (!booking) {
            logger.error(`Booking ${bookingId} not found`);
            return false;
        }
        // Skip if already assigned
        if (booking.status === 'assigned' || booking.vehicleId || booking.driverId) {
            logger.info(`Booking ${bookingId} already assigned`);
            return true;
        }
        const criteria = {
            vehicleModel: booking.vehicleModel || undefined,
            pickupLocation: booking.pickupLocation,
            pickupTime: booking.pickupTime,
        };
        // Find best available driver and vehicle
        const assignment = await findBestAssignment(criteria);
        if (!assignment) {
            logger.warn(`No available driver/vehicle found for booking ${bookingId}`);
            return false;
        }
        // Generate OTP
        const otpCode = (0, otp_1.generateOtp)();
        const otpExpiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes
        // Update booking with assignment
        const updated = await client_1.default.booking.update({
            where: { id: bookingId },
            data: {
                vehicleId: assignment.vehicleId,
                driverId: assignment.driverId,
                otpCode,
                otpExpiresAt,
                status: 'assigned',
            },
            include: { customer: true },
        });
        // Log audit
        await (0, audit_1.logAudit)({
            action: 'booking:auto_assign',
            entityType: 'booking',
            entityId: String(bookingId),
            before: booking,
            after: updated,
        });
        // Send notifications
        await (0, notifications_1.queueNotification)({
            targetId: assignment.driverId,
            type: 'booking.assigned',
            payload: {
                bookingId,
                otpCode,
                vehicleId: assignment.vehicleId,
                pickupLocation: booking.pickupLocation,
                destinationLocation: booking.destinationLocation,
                pickupTime: booking.pickupTime,
                customerName: booking.customer.name,
                customerMobile: booking.customer.mobile,
            },
        });
        await (0, notifications_1.queueNotification)({
            targetId: booking.customerId,
            type: 'booking.auto_assigned',
            payload: {
                bookingId,
                vehicleId: assignment.vehicleId,
                driverId: assignment.driverId,
                message: 'Your booking has been confirmed! Driver details will be shared 1 hour before pickup.',
            },
        });
        logger.info(`Auto-assigned booking ${bookingId} to driver ${assignment.driverId}, vehicle ${assignment.vehicleId}`);
        return true;
    }
    catch (error) {
        logger.error({ error, bookingId }, 'Error in auto-assignment');
        return false;
    }
}
/**
 * Find the best available driver and vehicle for a booking
 */
async function findBestAssignment(criteria) {
    const { vehicleModel, pickupTime } = criteria;
    // Get all approved/active vehicles
    const vehicles = await client_1.default.vehicle.findMany({
        where: {
            status: { in: ['approved', 'active'] },
            model: vehicleModel || undefined, // Match preferred model if specified
        },
        include: {
            assignments: {
                where: {
                    assignedAt: {
                        lte: new Date(),
                    },
                    unassignedAt: null,
                },
            },
        },
    });
    // Get all approved drivers
    const drivers = await client_1.default.driver.findMany({
        where: {
            status: 'approved',
        },
        include: {
            assignments: {
                where: {
                    assignedAt: {
                        lte: new Date(),
                    },
                    unassignedAt: null,
                },
                include: {
                    vehicle: true,
                },
            },
        },
    });
    // Find available vehicle-driver pairs
    for (const vehicle of vehicles) {
        // Check if vehicle is available (less than 2 active assignments)
        const activeAssignments = vehicle.assignments.length;
        if (activeAssignments >= 2)
            continue;
        // Find drivers assigned to this vehicle
        const assignedDrivers = await client_1.default.vehicleAssignment.findMany({
            where: {
                vehicleId: vehicle.id,
                assignedAt: { lte: new Date() },
                unassignedAt: null,
            },
            include: {
                driver: true,
            },
        });
        for (const assignment of assignedDrivers) {
            const driver = assignment.driver;
            // Check if driver is available at pickup time
            const isAvailable = await isDriverAvailable(driver.id, pickupTime);
            if (!isAvailable)
                continue;
            // Found a match!
            return {
                driverId: driver.id,
                vehicleId: vehicle.id,
            };
        }
    }
    // If no perfect match, try to find any available driver-vehicle pair
    for (const driver of drivers) {
        if (driver.assignments.length === 0)
            continue;
        const assignment = driver.assignments[0];
        const vehicle = assignment.vehicle;
        // Check if driver is available
        const isAvailable = await isDriverAvailable(driver.id, pickupTime);
        if (!isAvailable)
            continue;
        // Check if vehicle matches preferred model (if specified)
        if (vehicleModel && vehicle.model !== vehicleModel)
            continue;
        return {
            driverId: driver.id,
            vehicleId: vehicle.id,
        };
    }
    return null;
}
/**
 * Check if a driver is available at a specific time
 */
async function isDriverAvailable(driverId, pickupTime) {
    // Check for overlapping bookings
    // Assume a booking takes 2 hours (pickup + ride + buffer)
    const startTime = new Date(pickupTime.getTime() - 2 * 60 * 60 * 1000);
    const endTime = new Date(pickupTime.getTime() + 2 * 60 * 60 * 1000);
    const overlappingBookings = await client_1.default.booking.count({
        where: {
            driverId,
            status: { in: ['assigned', 'in_progress'] },
            pickupTime: {
                gte: startTime,
                lte: endTime,
            },
        },
    });
    return overlappingBookings === 0;
}
/**
 * Batch auto-assign all unassigned bookings
 * Can be called manually or scheduled
 */
async function batchAutoAssign() {
    try {
        const unassignedBookings = await client_1.default.booking.findMany({
            where: {
                status: 'upcoming',
                vehicleId: null,
                driverId: null,
            },
            orderBy: {
                pickupTime: 'asc', // Assign earliest bookings first
            },
        });
        logger.info(`Found ${unassignedBookings.length} unassigned bookings`);
        let successCount = 0;
        let failCount = 0;
        for (const booking of unassignedBookings) {
            const success = await autoAssignBooking(booking.id);
            if (success) {
                successCount++;
            }
            else {
                failCount++;
            }
            // Add small delay to avoid overwhelming the system
            await new Promise(resolve => setTimeout(resolve, 100));
        }
        logger.info(`Batch auto-assign completed: ${successCount} successful, ${failCount} failed`);
    }
    catch (error) {
        logger.error({ error }, 'Error in batch auto-assign');
    }
}
