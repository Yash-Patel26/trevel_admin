import { Router } from "express";
import { z } from "zod";
import prisma from "../../prisma/client";
import { mobileAuthMiddleware } from "../../middleware/mobileAuth";
import { validateBody } from "../../validation/validate";
import { pricingService } from "../../services/pricing";
import { syncHourlyRentalToBooking } from "../../services/bookingSync";

const hourlyRentalRouter = Router();

// Public route for info (vehicles & pricing)
hourlyRentalRouter.get("/info", async (req, res) => {
    // Mock vehicles similar to airport.ts but for hourly rentals
    // Ideally this should be in DB, but for now complying with request to Fetch from Backend via constant.
    const vehicles = [
        {
            name: "MG Windsor",
            seats: 4,
            bags: 3,
            image: "assets/images/taxi.jpeg",
            priceMultiplier: 1.0,
        },
        {
            name: "BYD emax",
            seats: 7,
            bags: 3,
            image: "assets/images/taxi.jpeg",
            priceMultiplier: 1.0,
        },
        {
            name: "Kia cerens",
            seats: 7,
            bags: 4,
            image: "assets/images/taxi.jpeg",
            priceMultiplier: 1.0,
        },
        {
            name: "BMW iX1",
            seats: 4,
            bags: 4,
            image: "assets/images/taxi.jpeg",
            priceMultiplier: 1.5, // Example premium multiplier
        },
    ];

    const pricing = await pricingService.getHourlyRentalPackages();

    res.json({
        success: true,
        data: {
            vehicles,
            pricing
        }
    });
});

hourlyRentalRouter.use(mobileAuthMiddleware);

const createHourlyRentalSchema = z.object({
    passenger_name: z.string().optional(),
    passenger_phone: z.string().optional(),
    passenger_email: z.string().email().optional(),
    pickup_location: z.string(),
    pickup_city: z.string().optional(),
    pickup_state: z.string().optional(),
    pickup_date: z.string(), // YYYY-MM-DD
    pickup_time: z.string(), // HH:mm
    vehicle_selected: z.string(),
    vehicle_image_url: z.string().optional(),
    rental_hours: z.coerce.number().min(1),
    covered_distance_km: z.coerce.number().min(0),
    base_price: z.coerce.number(),
    gst_amount: z.coerce.number().optional(),
    final_price: z.coerce.number(),
    currency: z.string().default("INR"),
    notes: z.string().optional(),
});

hourlyRentalRouter.post("/bookings", validateBody(createHourlyRentalSchema), async (req, res) => {
    try {
        const customer = req.customer;
        if (!customer) return res.status(401).json({ message: "Unauthorized" });

        const data = req.body;

        const pickupDateObj = new Date(data.pickup_date);
        const pickupTimeObj = new Date(`1970-01-01T${data.pickup_time.length === 5 ? data.pickup_time + ':00' : data.pickup_time}Z`);

        const booking = await prisma.hourlyRentalBooking.create({
            data: {
                userId: customer.id,
                pickupLocation: data.pickup_location,
                pickupCity: data.pickup_city,
                pickupState: data.pickup_state,
                pickupDate: pickupDateObj,
                pickupTime: pickupTimeObj,
                vehicleSelected: data.vehicle_selected,
                vehicleImageUrl: data.vehicle_image_url,
                passengerName: data.passenger_name || customer.name || "Unknown",
                passengerPhone: data.passenger_phone || customer.mobile || "",
                passengerEmail: data.passenger_email || customer.email,
                rentalHours: data.rental_hours,
                coveredDistanceKm: data.covered_distance_km,
                basePrice: data.base_price,
                gstAmount: data.gst_amount || 0,
                finalPrice: data.final_price,
                currency: data.currency,
                notes: data.notes,
                status: "pending"
            }
        });

        // Sync to admin Booking table
        try {
            await syncHourlyRentalToBooking(booking.id);
        } catch (syncError) {
            console.error("Failed to sync hourly rental to admin panel:", syncError);
        }

        return res.status(201).json({
            success: true,
            data: booking
        });

    } catch (error) {
        console.error("Create HourlyRental Error:", error);
        return res.status(500).json({
            success: false,
            message: "Failed to create booking",
            error: String(error)
        });
    }
});

// TODO: Port updateHourlyRentalWithExtensions if needed

export { hourlyRentalRouter };
