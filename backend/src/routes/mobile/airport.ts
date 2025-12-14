import { Router } from "express";
import { z } from "zod";
import prisma from "../../prisma/client";
import { mobileAuthMiddleware } from "../../middleware/mobileAuth";
import { validateBody } from "../../validation/validate";
import { pricingService } from "../../services/pricing";
import { calculateEstimatedTimeMinutes, minutesToTimeObject } from "../../utils/timeUtils";

const airportRouter = Router();

// Public routes (Autocheck? Mobile app uses auth for getting airports?)
// Mobile route: router.get('/', getAirports); -> apparently public in route file but controller doesn't check auth.
// But some lines in route file had authMiddleware.
// router.get('/', getAirports); <- No auth middleware in original file.
// router.get('/:id', getAirportById); <- No auth middleware.

airportRouter.get("/", async (req, res) => {
    try {
        const { city, country, limit } = req.query;
        const limitVal = Math.min(Number(limit) || 50, 100);

        const where: any = {};
        if (city) where.city = { contains: String(city), mode: "insensitive" };
        if (country) where.country = { contains: String(country), mode: "insensitive" };

        const airports = await prisma.airport.findMany({
            where,
            take: limitVal,
            orderBy: { airportName: "asc" }
        });

        res.json({ success: true, count: airports.length, data: airports });
    } catch (error) {
        res.status(500).json({ success: false, message: "Failed to fetch airports", error: String(error) });
    }
});

airportRouter.get("/:id", async (req, res) => {
    try {
        const { id } = req.params;
        // Support finding by code (3 letters) or UUID
        const isCode = id.length === 3 && /^[A-Z]{3}$/.test(id);

        const airport = await prisma.airport.findFirst({
            where: isCode ? { airportCode: id } : { id },
        });

        if (!airport) return res.status(404).json({ success: false, error: "Airport not found" });

        res.json({ success: true, data: airport });
    } catch (error) {
        res.status(500).json({ success: false, message: "Failed to fetch airport", error: String(error) });
    }
});

airportRouter.post("/estimate", async (req, res) => {
    try {
        console.log("Hits /estimate endpoint", req.body);
        const { type, pickup_time } = req.body || {};

        // Default to drop if not specified or invalid
        const isPickup = type === 'pickup';
        const pricing = isPickup
            ? pricingService.calculateAirportPickupPrice(pickup_time || new Date())
            : pricingService.calculateAirportDropPrice(pickup_time || new Date());

        const basePrice = pricing.finalPrice; // Using totalPrice as base for display

        const vehicles = [
            {
                name: "MG Windsor",
                seats: 4,
                time: "60 mins", // Mock time for now, or calculate if distance provided
                dist: "40 kms", // Mock distance
                price: `₹${basePrice}`,
                image: "assets/images/taxi.png", // Ensure these match frontend assets
            },
            {
                name: "BYD emax",
                seats: 6,
                time: "60 mins",
                dist: "40 kms",
                price: `₹${basePrice}`,
                image: "assets/images/taxi.png",
            },
            {
                name: "Kia Carens",
                seats: 7,
                time: "60 mins",
                dist: "40 kms",
                price: `₹${Math.round(basePrice * 1.2)}`, // 20% premium
                image: "assets/images/taxi.png",
            },
            {
                name: "BMW",
                seats: 4,
                time: "60 mins",
                dist: "40 kms",
                price: `₹${Math.round(basePrice * 2.0)}`, // 100% premium
                image: "assets/images/taxi.png",
            }
        ];

        res.json({ success: true, data: vehicles });
    } catch (error: any) {
        console.error("Estimate Error:", error);
        res.status(500).json({
            success: false,
            message: "Failed to get estimates",
            error: String(error),
            stack: error?.stack
        });
    }
});

// Protected Routes
// airportRouter.use(mobileAuthMiddleware); // Removed to avoid affecting estimate route

const transferSchema = z.object({
    passenger_name: z.string().optional(),
    passenger_phone: z.string().optional(),
    passenger_email: z.string().email().optional(),
    pickup_location: z.string(),
    pickup_date: z.string(), // YYYY-MM-DD
    pickup_time: z.string(), // HH:mm
    destination_airport: z.string(),
    vehicle_selected: z.string(),
    vehicle_image_url: z.string().optional(),
    estimated_distance_km: z.coerce.number().min(0),
    estimated_time_min: z.string(), // HH:mm:ss or similar
    base_price: z.coerce.number(),
    gst_amount: z.coerce.number().optional(),
    final_price: z.coerce.number(),
    currency: z.string().default("INR"),
    notes: z.string().optional(),
});

airportRouter.post("/to-airport/transfer-bookings", mobileAuthMiddleware, validateBody(transferSchema), async (req, res) => {
    try {
        const customer = req.customer;
        if (!customer) return res.status(401).json({ message: "Unauthorized" });
        const data = req.body;

        const pickupDateObj = new Date(data.pickup_date);
        const pickupTimeObj = new Date(`1970-01-01T${data.pickup_time.length === 5 ? data.pickup_time + ':00' : data.pickup_time}Z`);

        // Calculate estimated time based on distance
        const estimatedMinutes = calculateEstimatedTimeMinutes(
            data.estimated_distance_km,
            pricingService.isPeakHours(data.pickup_time, 'airport')
        );

        const booking = await prisma.toAirportTransferBooking.create({
            data: {
                userId: customer.id,
                pickupLocation: data.pickup_location,
                // bookingDate: replaced by createdAt
                pickupDate: pickupDateObj,
                pickupTime: pickupTimeObj,
                destinationAirport: data.destination_airport,
                vehicleSelected: data.vehicle_selected,
                vehicleImageUrl: data.vehicle_image_url,
                passengerName: data.passenger_name || customer.name || "Unknown",
                passengerPhone: data.passenger_phone || customer.mobile || "",
                passengerEmail: data.passenger_email || customer.email,
                estimatedDistanceKm: data.estimated_distance_km,
                estimatedTimeMin: minutesToTimeObject(estimatedMinutes),
                basePrice: data.base_price,
                gstAmount: data.gst_amount || 0,
                finalPrice: data.final_price,
                currency: data.currency,
                notes: data.notes,
                status: "pending"
            }
        });

        res.status(201).json({ success: true, message: "Booking created", data: booking });
    } catch (error) {
        res.status(500).json({ success: false, message: "Failed to create booking", error: String(error) });
    }
});

airportRouter.post("/from-airport/transfer-bookings", mobileAuthMiddleware, validateBody(transferSchema), async (req, res) => {
    try {
        const customer = req.customer;
        if (!customer) return res.status(401).json({ message: "Unauthorized" });
        const data = req.body;

        const pickupDateObj = new Date(data.pickup_date);
        const pickupTimeObj = new Date(`1970-01-01T${data.pickup_time.length === 5 ? data.pickup_time + ':00' : data.pickup_time}Z`);

        // Calculate estimated time based on distance
        const estimatedMinutes = calculateEstimatedTimeMinutes(
            data.estimated_distance_km,
            pricingService.isPeakHours(data.pickup_time, 'airport')
        );

        const booking = await prisma.fromAirportTransferBooking.create({
            data: {
                userId: customer.id,
                pickupLocation: data.pickup_location,
                pickupDate: pickupDateObj,
                pickupTime: pickupTimeObj,
                destinationAirport: data.destination_airport,
                vehicleSelected: data.vehicle_selected,
                vehicleImageUrl: data.vehicle_image_url,
                passengerName: data.passenger_name || customer.name || "Unknown",
                passengerPhone: data.passenger_phone || customer.mobile || "",
                passengerEmail: data.passenger_email || customer.email,
                estimatedDistanceKm: data.estimated_distance_km,
                estimatedTimeMin: minutesToTimeObject(estimatedMinutes),
                basePrice: data.base_price,
                gstAmount: data.gst_amount || 0,
                finalPrice: data.final_price,
                currency: data.currency,
                notes: data.notes,
                status: "pending"
            }
        });

        res.status(201).json({ success: true, message: "Booking created", data: booking });
    } catch (error) {
        res.status(500).json({ success: false, message: "Failed to create booking", error: String(error) });
    }
});

export { airportRouter };
