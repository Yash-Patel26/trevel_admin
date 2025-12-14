import { Router } from "express";
import { z } from "zod";
import prisma from "../../prisma/client";
import { mobileAuthMiddleware } from "../../middleware/mobileAuth";
import { validateBody } from "../../validation/validate";
import { pricingService } from "../../services/pricing";
import { googleMapsService } from "../../services/googleMaps";
import { syncMiniTripToBooking } from "../../services/bookingSync";
import { calculateEstimatedTimeMinutes, minutesToTimeObject, parseTimeToMinutes } from "../../utils/timeUtils";

const miniTripRouter = Router();

miniTripRouter.use(mobileAuthMiddleware);

const createMiniTripSchema = z.object({
    passenger_name: z.string().optional(),
    passenger_phone: z.string().optional(),
    passenger_email: z.string().email().optional(),
    pickup_location: z.string(),
    pickup_city: z.string().optional(),
    pickup_state: z.string().optional(),
    dropoff_location: z.string(),
    dropoff_city: z.string().optional(),
    dropoff_state: z.string().optional(),
    pickup_date: z.string(), // YYYY-MM-DD
    pickup_time: z.string(), // HH:mm
    vehicle_selected: z.string(),
    vehicle_image_url: z.string().optional(),
    estimated_distance_km: z.coerce.number(),
    estimated_time_min: z.string(), // Minutes or HH:mm
    base_price: z.coerce.number(),
    gst_amount: z.coerce.number().optional(),
    final_price: z.coerce.number(),
    currency: z.string().default("INR"),
    notes: z.string().optional(),
});

const estimateTripSchema = z.object({
    pickup_location: z.string(),
    dropoff_location: z.string(),
    pickup_time: z.string().optional() // ISO string or similar
});

const estimateMiniTripSchema = z.object({
    distance_km: z.coerce.number(),
    pickup_time: z.string(),
});

// GET /info - Returns available vehicles for Mini Trip
miniTripRouter.get("/info", (req, res) => {
    // Fixed vehicles for now. In future, fetch from DB.
    const vehicles = [
        {
            name: "Sedan",
            seats: 4,
            image: "assets/images/taxi.jpeg",
            priceMultiplier: 1.0,
        },
        {
            name: "SUV",
            seats: 6,
            image: "assets/images/taxi.jpeg",
            priceMultiplier: 1.5,
        }
    ];

    res.json({
        success: true,
        data: { vehicles }
    });
});

// POST /estimate-trip - Calculates distance/time and base price
miniTripRouter.post("/estimate-trip", validateBody(estimateTripSchema), async (req, res) => {
    try {
        const { pickup_location, dropoff_location, pickup_time } = req.body;

        // 1. Get Distance & Duration from Google Maps
        const routeInfo = await googleMapsService.getDistanceWithTraffic(
            pickup_location,
            dropoff_location,
            pickup_time
        );

        // 2. Calculate BASE Price (for Sedan/Standard)
        const priceDetails = pricingService.calculateMiniTravelPrice(
            routeInfo.distance_km,
            pickup_time || new Date()
        );

        res.json({
            success: true,
            data: {
                distance_km: routeInfo.distance_km,
                duration_min: routeInfo.duration_minutes,
                base_price: priceDetails.finalPrice, // Use final price as base for multiplier application
                currency: "INR"
            }
        });

    } catch (error) {
        console.error("Estimate Trip Error:", error);
        res.status(500).json({
            success: false,
            message: "Failed to estimate trip",
            error: String(error)
        });
    }
});

// Legacy /estimate endpoint (can keep or remove, keeping for compatibility if utilized elsewhere)
miniTripRouter.post("/estimate", validateBody(estimateMiniTripSchema), async (req, res) => {
    try {
        const { distance_km, pickup_time } = req.body;
        const priceDetails = pricingService.calculateMiniTravelPrice(distance_km, pickup_time);
        res.json({
            success: true,
            data: priceDetails
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: "Failed to estimate price",
            error: String(error)
        });
    }
});

miniTripRouter.post("/bookings", validateBody(createMiniTripSchema), async (req, res) => {
    try {
        const customer = req.customer;
        if (!customer) return res.status(401).json({ message: "Unauthorized" });

        const data = req.body;

        // Construct Date objects
        // data.pickup_date is YYYY-MM-DD
        // data.pickup_time is HH:mm or HH:mm:ss
        const pickupDateObj = new Date(data.pickup_date);

        // Parse time string (handle HH:mm, HH:mm:ss, HH:mm AM/PM)
        let timeStr = data.pickup_time.trim();
        const isPM = /pm/i.test(timeStr);
        const isAM = /am/i.test(timeStr);
        const bareTime = timeStr.replace(/am|pm/i, '').trim();
        const parts = bareTime.split(':');

        let hours = 0;
        let minutes = 0;
        if (parts.length >= 2) {
            hours = parseInt(parts[0], 10) || 0;
            minutes = parseInt(parts[1], 10) || 0;
        }

        if (isPM && hours < 12) hours += 12;
        if (isAM && hours === 12) hours = 0;

        const isoTime = `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:00`;
        const pickupTimeObj = new Date(`1970-01-01T${isoTime}Z`);

        // Calculate estimated time based on distance
        const estimatedMinutes = calculateEstimatedTimeMinutes(
            data.estimated_distance_km,
            pricingService.isPeakHours(data.pickup_time, 'miniTravel')
        );

        const booking = await prisma.miniTripBooking.create({
            data: {
                userId: customer.id,
                pickupLocation: data.pickup_location,
                pickupCity: data.pickup_city ?? null,
                pickupState: data.pickup_state ?? null,
                dropoffLocation: data.dropoff_location,
                dropoffCity: data.dropoff_city ?? null,
                dropoffState: data.dropoff_state ?? null,
                pickupDate: pickupDateObj,
                pickupTime: pickupTimeObj,
                vehicleSelected: data.vehicle_selected,
                vehicleImageUrl: data.vehicle_image_url ?? null,
                passengerName: data.passenger_name || customer.name || "Unknown",
                passengerPhone: data.passenger_phone || customer.mobile || "",
                passengerEmail: (data.passenger_email || customer.email) ?? null,
                estimatedDistanceKm: data.estimated_distance_km,
                estimatedTimeMin: minutesToTimeObject(estimatedMinutes),
                basePrice: data.base_price,
                gstAmount: data.gst_amount || 0,
                finalPrice: data.final_price,
                currency: data.currency,
                notes: data.notes ?? null,
                status: "pending"
            }
        });

        // Sync to admin Booking table for visibility
        try {
            await syncMiniTripToBooking(booking.id);
        } catch (syncError) {
            console.error("Failed to sync booking to admin panel:", syncError);
            // Don't fail the request if sync fails
        }

        return res.status(201).json({
            success: true,
            data: booking
        });

    } catch (error) {
        console.error("Create MiniTrip Error:", error);
        return res.status(500).json({
            success: false,
            message: "Failed to create booking",
            error: String(error)
        });
    }
});

export { miniTripRouter };
