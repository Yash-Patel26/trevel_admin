import prisma from '../prisma/client';

/**
 * Syncs a MiniTripBooking to the Booking table for admin panel visibility
 * Maps mobile-specific fields to admin panel fields
 */
export async function syncMiniTripToBooking(miniTripId: string) {
    try {
        // Fetch the mini trip booking
        const miniTrip = await prisma.miniTripBooking.findUnique({
            where: { id: miniTripId },
            include: { user: true }
        });

        if (!miniTrip) {
            throw new Error(`MiniTripBooking ${miniTripId} not found`);
        }

        // SYNC DISABLED: We now query specific tables directly in the admin panel.
        console.log(`ℹ️ Sync disabled for MiniTripBooking ${miniTripId}`);
        return null;

        /* 
        // Sync logic retained for reference but disabled
        // Combine date and time into a single DateTime
        const pickupDateTime = new Date(miniTrip.pickupDate);
        const timeComponents = miniTrip.pickupTime.toISOString().split('T')[1];
        const [hours, minutes] = timeComponents.split(':');
        pickupDateTime.setHours(parseInt(hours), parseInt(minutes), 0, 0);

        // Map status: pending → upcoming, confirmed → today, etc.
        const statusMap: Record<string, string> = {
            'pending': 'upcoming',
            'confirmed': 'upcoming',
            'in_progress': 'today',
            'completed': 'completed',
            'cancelled': 'canceled'
        };

        const bookingStatus = statusMap[miniTrip.status] || 'upcoming';

        // Create or update booking in admin table
        const booking = await prisma.booking.create({
            data: {
                customerId: miniTrip.userId,
                pickupLocation: miniTrip.pickupLocation,
                destinationLocation: miniTrip.dropoffLocation,
                pickupTime: pickupDateTime,
                vehicleModel: miniTrip.vehicleSelected,
                status: bookingStatus,
                createdAt: miniTrip.createdAt
            }
        });

        console.log(`✅ Synced MiniTripBooking ${miniTripId} to Booking ${booking.id}`);

        return booking; 
        */
    } catch (error) {
        console.error(`❌ Failed to sync MiniTripBooking ${miniTripId}:`, error);
        throw error;
    }
}

/**
 * Syncs an HourlyRentalBooking to the Booking table
 */
export async function syncHourlyRentalToBooking(rentalId: string) {
    try {
        const rental = await prisma.hourlyRentalBooking.findUnique({
            where: { id: rentalId },
            include: { user: true }
        });

        if (!rental) {
            throw new Error(`HourlyRentalBooking ${rentalId} not found`);
        }

        // SYNC DISABLED
        console.log(`ℹ️ Sync disabled for HourlyRentalBooking ${rentalId}`);
        return null;

        /*
        const pickupDateTime = new Date(rental.pickupDate);
        const timeComponents = rental.pickupTime.toISOString().split('T')[1];
        const [hours, minutes] = timeComponents.split(':');
        pickupDateTime.setHours(parseInt(hours), parseInt(minutes), 0, 0);

        const statusMap: Record<string, string> = {
            'pending': 'upcoming',
            'confirmed': 'upcoming',
            'in_progress': 'today',
            'completed': 'completed',
            'cancelled': 'canceled'
        };

        const bookingStatus = statusMap[rental.status] || 'upcoming';

        const booking = await prisma.booking.create({
            data: {
                customerId: rental.userId,
                pickupLocation: rental.pickupLocation,
                destinationLocation: `${rental.rentalHours}hr Rental - ${rental.coveredDistanceKm}km`,
                pickupTime: pickupDateTime,
                vehicleModel: rental.vehicleSelected,
                status: bookingStatus,
                createdAt: rental.createdAt
            }
        });

        console.log(`✅ Synced HourlyRentalBooking ${rentalId} to Booking ${booking.id}`);

        return booking;
        */
    } catch (error) {
        console.error(`❌ Failed to sync HourlyRentalBooking ${rentalId}:`, error);
        throw error;
    }
}

/**
 * Syncs an airport transfer booking to the Booking table
 */
export async function syncAirportTransferToBooking(transferId: string, isToAirport: boolean) {
    try {
        const transfer = isToAirport
            ? await prisma.toAirportTransferBooking.findUnique({
                where: { id: transferId },
                include: { user: true }
            })
            : await prisma.fromAirportTransferBooking.findUnique({
                where: { id: transferId },
                include: { user: true }
            });

        if (!transfer) {
            throw new Error(`Airport transfer ${transferId} not found`);
        }

        // SYNC DISABLED
        console.log(`ℹ️ Sync disabled for AirportTransfer ${transferId}`);
        return null;

        /*
        const pickupDateTime = new Date(transfer.pickupDate);
        const timeComponents = transfer.pickupTime.toISOString().split('T')[1];
        const [hours, minutes] = timeComponents.split(':');
        pickupDateTime.setHours(parseInt(hours), parseInt(minutes), 0, 0);

        const statusMap: Record<string, string> = {
            'pending': 'upcoming',
            'confirmed': 'upcoming',
            'in_progress': 'today',
            'completed': 'completed',
            'cancelled': 'canceled'
        };

        const bookingStatus = statusMap[transfer.status] || 'upcoming';

        const booking = await prisma.booking.create({
            data: {
                customerId: transfer.userId,
                pickupLocation: transfer.pickupLocation,
                destinationLocation: `${isToAirport ? 'To' : 'From'} ${transfer.destinationAirport}`,
                pickupTime: pickupDateTime,
                vehicleModel: transfer.vehicleSelected || 'Airport Transfer',
                status: bookingStatus,
                createdAt: transfer.createdAt
            }
        });

        console.log(`✅ Synced Airport Transfer ${transferId} to Booking ${booking.id}`);

        return booking;
        */
    } catch (error) {
        console.error(`❌ Failed to sync Airport Transfer ${transferId}:`, error);
        throw error;
    }
}
