import { Router } from 'express';
import prisma from '../prisma/client';
import { authMiddleware } from '../middleware/auth';

const router = Router();

// Get all bookings for admin panel
router.get('/', authMiddleware, async (req, res) => {
    try {
        const { status, page = 1, limit = 20 } = req.query;

        const where: any = {};
        if (status && typeof status === 'string') {
            where.status = status;
        }

        const skip = (Number(page) - 1) * Number(limit);

        const [bookings, total] = await Promise.all([
            prisma.booking.findMany({
                where,
                include: {
                    customer: {
                        select: {
                            id: true,
                            name: true,
                            mobile: true,
                            email: true
                        }
                    }
                },
                orderBy: { createdAt: 'desc' },
                skip,
                take: Number(limit)
            }),
            prisma.booking.count({ where })
        ]);

        res.json({
            success: true,
            data: {
                bookings,
                pagination: {
                    page: Number(page),
                    limit: Number(limit),
                    total,
                    totalPages: Math.ceil(total / Number(limit))
                }
            }
        });
    } catch (error) {
        console.error('Error fetching bookings:', error);
        res.status(500).json({ success: false, message: 'Failed to fetch bookings' });
    }
});

// Get single booking by ID
router.get('/:id', authMiddleware, async (req, res) => {
    try {
        const idParam = req.params.id;

        // 1. Try Legacy Booking (Int ID)
        if (/^\d+$/.test(idParam)) {
            const booking = await prisma.booking.findUnique({
                where: { id: parseInt(idParam) },
                include: {
                    customer: {
                        select: {
                            id: true,
                            name: true,
                            mobile: true,
                            email: true
                        }
                    },
                    vehicle: true,
                    driver: true
                }
            });

            if (booking) {
                return res.json({ success: true, data: booking });
            }
        }

        // 2. Try Mobile App Bookings (UUID)
        // We check all specific tables. Ideally we should know the type, but ID is unique enough (UUID).
        const [mini, hourly, toAir, fromAir] = await Promise.all([
            prisma.miniTripBooking.findUnique({ where: { id: idParam }, include: { user: true, vehicle: true } }),
            prisma.hourlyRentalBooking.findUnique({ where: { id: idParam }, include: { user: true, vehicle: true } }),
            prisma.toAirportTransferBooking.findUnique({ where: { id: idParam }, include: { user: true, vehicle: true } }),
            prisma.fromAirportTransferBooking.findUnique({ where: { id: idParam }, include: { user: true, vehicle: true } })
        ]);

        const item = mini || hourly || toAir || fromAir;

        if (!item) {
            return res.status(404).json({ success: false, message: 'Booking not found' });
        }

        // Map to common structure expected by Admin App
        // This mapping logic mirrors customers.ts but tailored for detailed view if needed

        let type = 'unknown';
        if (mini) type = 'mini-trip';
        else if (hourly) type = 'hourly';
        else if (toAir) type = 'to-airport';
        else if (fromAir) type = 'from-airport';

        // Helper to construct DateTime from Date + Time fields if present
        const resolveDateTime = (dateVal: Date, timeVal?: Date) => {
            if (!timeVal) return dateVal;
            const d = new Date(dateVal);
            const t = new Date(timeVal);
            d.setHours(t.getHours(), t.getMinutes(), t.getSeconds());
            return d;
        };

        const pickupTime = resolveDateTime(item.pickupDate, item.pickupTime); // All these models have pickupDate

        // Destination mapping
        let destinationLocation = null;
        if ((item as any).dropoffLocation) destinationLocation = (item as any).dropoffLocation;
        else if ((item as any).destinationAirport) destinationLocation = (item as any).destinationAirport; // to/from airport

        const booking = {
            id: item.id,
            customerId: item.userId,
            customer: {
                id: item.user.id,
                name: item.user.name,
                mobile: item.user.mobile,
                email: item.user.email
            },
            pickupLocation: item.pickupLocation,
            // These new tables don't store lat/lng apparently, sending null or 0 if needed
            pickupLatitude: null,
            pickupLongitude: null,
            destinationLocation: destinationLocation,
            destinationLatitude: null,
            destinationLongitude: null,

            pickupTime: pickupTime,
            destinationTime: null, // calculated or estimated? table has estimatedTimeMin usually

            vehicleModel: (item as any).vehicleSelected || item.vehicle?.model,
            status: item.status, // mobile statuses (pending, assigned, etc)

            vehicleId: item.vehicleId,
            vehicle: item.vehicle, // Include full vehicle object if linked

            driverId: null, // Driver not linked in these schemas yet directly? 
            driver: null,   // We might need to fetch driver if driverId was stored, but schema showed no driver relation in some?
            // Wait, schema for MiniTripBooking doesn't have driverId relation line?
            // Checked schema: MiniTripBooking doesn't have `driver` relation defined, only `vehicle`.
            // But `customers.ts` handles logic differently? 
            // Actually `customers.ts` fetch driver manually if driverId exists.

            otpCode: null,
            otpExpiresAt: null,
            createdAt: item.createdAt,
            type: type
        };

        res.json({ success: true, data: booking });

    } catch (error) {
        console.error('Error fetching booking:', error);
        res.status(500).json({ success: false, message: 'Failed to fetch booking' });
    }
});

// Update booking (for admin to assign driver, update status, etc.)
router.put('/:id', authMiddleware, async (req, res) => {
    try {
        const { vehicleId, driverId, status, notes } = req.body;

        const updateData: any = {};
        if (vehicleId) updateData.vehicleId = vehicleId;
        if (driverId) updateData.driverId = driverId;
        if (status) updateData.status = status;
        if (notes !== undefined) updateData.notes = notes;

        const booking = await prisma.booking.update({
            where: { id: parseInt(req.params.id) },
            data: updateData,
            include: {
                customer: {
                    select: {
                        id: true,
                        name: true,
                        mobile: true,
                        email: true
                    }
                },
                vehicle: true,
                driver: true
            }
        });

        res.json({ success: true, data: booking });
    } catch (error) {
        console.error('Error updating booking:', error);
        res.status(500).json({ success: false, message: 'Failed to update booking' });
    }
});

// Assign driver and vehicle to booking
router.post('/:id/assign', authMiddleware, async (req, res) => {
    try {
        const { vehicleId, driverId } = req.body;

        if (!vehicleId && !driverId) {
            return res.status(400).json({ success: false, message: 'VehicleId or DriverId is required' });
        }

        const updateData: any = {
            status: 'assigned' // Auto update status to assigned
        };

        if (vehicleId) updateData.vehicleId = vehicleId;
        if (driverId) updateData.driverId = driverId;

        const booking = await prisma.booking.update({
            where: { id: parseInt(req.params.id) },
            data: updateData,
            include: {
                customer: {
                    select: {
                        id: true,
                        name: true,
                        mobile: true,
                        email: true
                    }
                },
                vehicle: true,
                driver: true
            }
        });

        res.json({ success: true, data: booking });
    } catch (error) {
        console.error('Error assigning booking:', error);
        res.status(500).json({ success: false, message: 'Failed to assign booking' });
    }
});

export default router;
