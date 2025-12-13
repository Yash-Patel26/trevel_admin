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
        const booking = await prisma.booking.findUnique({
            where: { id: parseInt(req.params.id) },
            include: {
                customer: {
                    select: {
                        id: true,
                        name: true,
                        mobile: true,
                        email: true
                    }
                }
            }
        });

        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found' });
        }

        res.json({ success: true, data: booking });
    } catch (error) {
        console.error('Error fetching booking:', error);
        res.status(500).json({ success: false, message: 'Failed to fetch booking' });
    }
});

// Update booking (for admin to assign driver, update status, etc.)
router.put('/:id', authMiddleware, async (req, res) => {
    try {
        const { vehicleId, status, notes } = req.body;

        const updateData: any = {};
        if (vehicleId) updateData.vehicleId = vehicleId;
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
                }
            }
        });

        res.json({ success: true, data: booking });
    } catch (error) {
        console.error('Error updating booking:', error);
        res.status(500).json({ success: false, message: 'Failed to update booking' });
    }
});

export default router;
