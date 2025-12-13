import { Router } from "express";
import prisma from "../../prisma/client";
import { mobileAuthMiddleware } from "../../middleware/mobileAuth";

const bookingsRouter = Router();

bookingsRouter.use(mobileAuthMiddleware);

/**
 * Get current driver assigned to a vehicle
 */
async function getCurrentDriver(vehicleId: string | null) {
    if (!vehicleId) return null;

    const assignment = await prisma.vehicleAssignment.findFirst({
        where: {
            vehicleId,
            unassignedAt: null // Currently assigned
        },
        include: {
            driver: true
        },
        orderBy: {
            assignedAt: 'desc'
        }
    });

    return assignment?.driver || null;
}

/**
 * Get booking details by ID with driver and vehicle information
 * Supports all booking types: MiniTrip, HourlyRental, ToAirport, FromAirport
 */
bookingsRouter.get("/bookings/:id", async (req, res) => {
    try {
        const customer = req.customer;
        if (!customer) return res.status(401).json({ message: "Unauthorized" });

        const { id } = req.params;

        // Try to find in MiniTripBooking first
        let booking: any = await prisma.miniTripBooking.findUnique({
            where: { id },
            include: {
                user: true,
                vehicle: true
            }
        });

        let bookingType = "mini_trip";

        // If not found, try HourlyRentalBooking
        if (!booking) {
            booking = await prisma.hourlyRentalBooking.findUnique({
                where: { id },
                include: {
                    user: true,
                    vehicle: true
                }
            });
            bookingType = "hourly_rental";
        }

        // If not found, try ToAirportTransferBooking
        if (!booking) {
            booking = await prisma.toAirportTransferBooking.findUnique({
                where: { id },
                include: {
                    user: true,
                    vehicle: true
                }
            });
            bookingType = "to_airport";
        }

        // If not found, try FromAirportTransferBooking
        if (!booking) {
            booking = await prisma.fromAirportTransferBooking.findUnique({
                where: { id },
                include: {
                    user: true,
                    vehicle: true
                }
            });
            bookingType = "from_airport";
        }

        if (!booking) {
            return res.status(404).json({ message: "Booking not found" });
        }

        // Verify booking belongs to authenticated customer
        if (booking.userId !== customer.id) {
            return res.status(403).json({ message: "Access denied" });
        }

        // Get current driver if vehicle is assigned
        const driver = await getCurrentDriver(booking.vehicleId);

        // Format response with driver and vehicle details
        const response = {
            id: booking.id,
            bookingType,
            status: booking.status,

            // Passenger details
            passengerName: booking.passengerName,
            passengerPhone: booking.passengerPhone,
            passengerEmail: booking.passengerEmail,

            // Location details
            pickupLocation: booking.pickupLocation,
            pickupCity: booking.pickupCity,
            pickupState: booking.pickupState,
            destinationLocation: booking.dropoffLocation || booking.destinationAirport,
            destinationCity: booking.dropoffCity,
            destinationState: booking.dropoffState,

            // Date/Time
            pickupDate: booking.pickupDate,
            pickupTime: booking.pickupTime,

            // Pricing
            basePrice: booking.basePrice,
            gstAmount: booking.gstAmount,
            finalPrice: booking.finalPrice,
            currency: booking.currency,

            // Vehicle details (if assigned)
            vehicle: booking.vehicle ? {
                id: booking.vehicle.id,
                model: booking.vehicle.model,
                make: booking.vehicle.make,
                year: booking.vehicle.year,
                licensePlate: booking.vehicle.licensePlate,
                color: booking.vehicle.color,
                seats: booking.vehicle.seats,
                type: booking.vehicle.type,
                status: booking.vehicle.status
            } : null,

            // Driver details (if assigned)
            driver: driver ? {
                id: driver.id,
                name: driver.name,
                mobile: driver.mobile,
                email: driver.email,
                licenseNumber: driver.licenseNumber,
                rating: driver.rating,
                totalTrips: driver.totalTrips,
                profileImageUrl: driver.profileImageUrl,
                status: driver.status
            } : null,

            // Additional booking-specific details
            ...(bookingType === "mini_trip" && {
                estimatedDistanceKm: booking.estimatedDistanceKm,
                estimatedTimeMin: booking.estimatedTimeMin
            }),
            ...(bookingType === "hourly_rental" && {
                rentalHours: booking.rentalHours,
                coveredDistanceKm: booking.coveredDistanceKm
            }),
            ...((bookingType === "to_airport" || bookingType === "from_airport") && {
                flightNumber: booking.flightNumber,
                flightTime: booking.flightTime
            }),

            // Metadata
            notes: booking.notes,
            createdAt: booking.createdAt,
            updatedAt: booking.updatedAt
        };

        return res.json({
            success: true,
            data: response
        });

    } catch (error) {
        console.error("Get booking details error:", error);
        return res.status(500).json({
            success: false,
            message: "Failed to fetch booking details",
            error: String(error)
        });
    }
});

/**
 * Get all bookings for authenticated customer
 */
bookingsRouter.get("/bookings", async (req, res) => {
    try {
        const customer = req.customer;
        if (!customer) return res.status(401).json({ message: "Unauthorized" });

        const { status } = req.query;

        const whereClause = {
            userId: customer.id,
            ...(status && { status: String(status) })
        };

        // Fetch from all booking tables
        const [miniTrips, hourlyRentals, toAirport, fromAirport] = await Promise.all([
            prisma.miniTripBooking.findMany({
                where: whereClause,
                include: { vehicle: true },
                orderBy: { createdAt: 'desc' }
            }),
            prisma.hourlyRentalBooking.findMany({
                where: whereClause,
                include: { vehicle: true },
                orderBy: { createdAt: 'desc' }
            }),
            prisma.toAirportTransferBooking.findMany({
                where: whereClause,
                include: { vehicle: true },
                orderBy: { createdAt: 'desc' }
            }),
            prisma.fromAirportTransferBooking.findMany({
                where: whereClause,
                include: { vehicle: true },
                orderBy: { createdAt: 'desc' }
            })
        ]);

        // Combine and format all bookings
        const allBookings = [
            ...miniTrips.map(b => ({ ...b, bookingType: 'mini_trip' })),
            ...hourlyRentals.map(b => ({ ...b, bookingType: 'hourly_rental' })),
            ...toAirport.map(b => ({ ...b, bookingType: 'to_airport' })),
            ...fromAirport.map(b => ({ ...b, bookingType: 'from_airport' }))
        ].sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());

        return res.json({
            success: true,
            data: allBookings
        });

    } catch (error) {
        console.error("Get bookings error:", error);
        return res.status(500).json({
            success: false,
            message: "Failed to fetch bookings",
            error: String(error)
        });
    }
});

export { bookingsRouter };
