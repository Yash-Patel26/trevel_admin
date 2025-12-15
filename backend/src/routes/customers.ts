import { Router } from "express";
import { Prisma } from "@prisma/client";
import { authMiddleware } from "../middleware/auth";
import { requirePermissions } from "../middleware/permissions";
import prisma from "../prisma/client";
import { getPagination } from "../utils/pagination";
import { validateBody } from "../validation/validate";
import { bookingAssignSchema, bookingOtpValidateSchema } from "../validation/schemas";
import { generateOtp } from "../utils/otp";
import { queueNotification } from "../services/notifications";
import { logAudit } from "../utils/audit";
import { z } from "zod";
import { env } from "../config/env";
import redisClient from "../config/redis";

export const customersRouter = Router();

customersRouter.use(authMiddleware);

customersRouter.get(
  "/customers/dashboard/summary",
  requirePermissions(["customer:view", "dashboard:view"]),
  async (_req, res) => {
    const now = new Date();
    const startOfToday = new Date(now);
    startOfToday.setHours(0, 0, 0, 0);
    const endOfToday = new Date(now);
    endOfToday.setHours(23, 59, 59, 999);

    // Count bookings from all tables (legacy + mobile)
    const [
      legacyTotal,
      legacyToday,
      legacyUpcoming,
      miniTotal,
      miniToday,
      miniUpcoming,
      hourlyTotal,
      hourlyToday,
      hourlyUpcoming,
      toAirTotal,
      toAirToday,
      toAirUpcoming,
      fromAirTotal,
      fromAirToday,
      fromAirUpcoming
    ] = await Promise.all([
      // Legacy bookings
      prisma.booking.count(),
      prisma.booking.count({ where: { pickupTime: { gte: startOfToday, lte: endOfToday } } }),
      prisma.booking.count({ where: { pickupTime: { gt: now } } }),

      // Mini trip bookings
      prisma.miniTripBooking.count(),
      prisma.miniTripBooking.count({ where: { pickupDate: { gte: startOfToday, lte: endOfToday } } }),
      prisma.miniTripBooking.count({ where: { pickupDate: { gt: now } } }),

      // Hourly rental bookings
      prisma.hourlyRentalBooking.count(),
      prisma.hourlyRentalBooking.count({ where: { pickupDate: { gte: startOfToday, lte: endOfToday } } }),
      prisma.hourlyRentalBooking.count({ where: { pickupDate: { gt: now } } }),

      // To airport bookings
      prisma.toAirportTransferBooking.count(),
      prisma.toAirportTransferBooking.count({ where: { pickupDate: { gte: startOfToday, lte: endOfToday } } }),
      prisma.toAirportTransferBooking.count({ where: { pickupDate: { gt: now } } }),

      // From airport bookings
      prisma.fromAirportTransferBooking.count(),
      prisma.fromAirportTransferBooking.count({ where: { pickupDate: { gte: startOfToday, lte: endOfToday } } }),
      prisma.fromAirportTransferBooking.count({ where: { pickupDate: { gt: now } } }),
    ]);

    const totalBookings = legacyTotal + miniTotal + hourlyTotal + toAirTotal + fromAirTotal;
    const todaysBookings = legacyToday + miniToday + hourlyToday + toAirToday + fromAirToday;
    const upcomingBookings = legacyUpcoming + miniUpcoming + hourlyUpcoming + toAirUpcoming + fromAirUpcoming;

    return res.json({
      totalBookings,
      todaysBookings,
      upcomingBookings,
    });
  }
);

customersRouter.get(
  "/customers/bookings",
  requirePermissions(["customer:view", "dashboard:view"]),
  async (req, res) => {
    const { skip, take, page, pageSize } = getPagination(req.query);
    const { status, startDate, endDate, search, type } = req.query;

    // Date filter on 'createdAt' or 'pickupTime'? 
    // Unified table used pickupTime. MiniTrip has pickupDate + pickupTime.
    // We'll use 'createdAt' for simplicity in sorting, but dateFilter is typically for 'pickup'.
    // Mapping pickup filter to specific tables is complex due to type differences (Date vs Time columns).
    // We will fetch based on 'createdAt' (most recent first) within reasonable limit if no date filter.

    // Simplification: We will fetch all recent bookings from requested tables and filter/sort in memory.
    // Ideally this should be a UNION view in SQL.

    const limit = 100; // Fetch up to 100 from each table to ensure we have page 1 filled. 
    // If user requests deeper pages, this naive approach fails. But "don't sink" forces this trade-off.

    const queries = [];

    const includeUser = { user: true };

    // Helper to map status search
    // Admin has: upcoming, today, completed, canceled
    // Mobile has: pending, confirmed, in_progress, completed, cancelled
    const mapStatusToMobile = (s: string) => {
      if (s === 'upcoming') return { in: ['pending', 'confirmed'] };
      if (s === 'today') return { in: ['in_progress'] };
      if (s === 'canceled') return 'cancelled'; // Note double 'l' in schemas sometimes
      return s;
    };

    const baseWhere: any = {};
    if (status && status !== 'All') {
      const mobileStatus = mapStatusToMobile(String(status));
      baseWhere.status = mobileStatus;
    }

    // 1. Mini Trip
    if (!type || type === 'mini-trip') {
      queries.push(prisma.miniTripBooking.findMany({
        where: baseWhere,
        include: includeUser,
        orderBy: { createdAt: 'desc' },
        take: limit
      }).then(rows => rows.map(r => ({ ...r, type: 'mini-trip' }))));
    }

    // 2. Hourly Rental
    if (!type || type === 'hourly' || type === 'hourly-rental') {
      queries.push(prisma.hourlyRentalBooking.findMany({
        where: baseWhere,
        include: includeUser,
        orderBy: { createdAt: 'desc' },
        take: limit
      }).then(rows => rows.map(r => ({ ...r, type: 'hourly' }))));
    }

    // 3. Airport
    if (!type || type === 'airport') {
      queries.push(prisma.toAirportTransferBooking.findMany({
        where: baseWhere,
        include: includeUser,
        orderBy: { createdAt: 'desc' },
        take: limit
      }).then(rows => rows.map(r => ({ ...r, type: 'to-airport' }))));

      queries.push(prisma.fromAirportTransferBooking.findMany({
        where: baseWhere,
        include: includeUser,
        orderBy: { createdAt: 'desc' },
        take: limit
      }).then(rows => rows.map(r => ({ ...r, type: 'from-airport' }))));
    }

    const results = await Promise.all(queries);
    const flatResults = results.flat();

    // Sort combined results by createdAt desc
    flatResults.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());

    // Search Filter (In Memory)
    let filtered = flatResults;
    if (search) {
      const lowerSearch = String(search).toLowerCase();
      filtered = filtered.filter(item =>
        (item.user?.name && item.user.name.toLowerCase().includes(lowerSearch)) ||
        (item.user?.mobile && item.user.mobile.includes(lowerSearch)) ||
        (item.pickupLocation && item.pickupLocation.toLowerCase().includes(lowerSearch))
      );
    }

    const total = filtered.length;
    // Manual Pagination
    const paginated = filtered.slice(skip, skip + take);

    // Map to Booking Interface
    const responseData = paginated.map(item => {
      // Construct Pickup DateTime
      const pickupDate = new Date(item.pickupDate);
      if (item.pickupTime) {
        const timeStr = item.pickupTime.toISOString().split('T')[1]; // HH:mm:ss.msZ
        const [h, m] = timeStr.split(':');
        pickupDate.setHours(parseInt(h), parseInt(m), 0, 0);
      }

      // Status mapping back to Admin expected values
      let adminStatus = 'upcoming';
      if (item.status === 'in_progress') adminStatus = 'today';
      if (item.status === 'completed') adminStatus = 'completed';
      if (item.status === 'cancelled' || item.status === 'canceled') adminStatus = 'canceled';

      // Destination label
      let dest = (item as any).dropoffLocation || (item as any).destinationAirport;
      if (item.type === 'hourly') {
        dest = `${(item as any).rentalHours}hr Rental`;
      } else if (item.type === 'to-airport') {
        dest = `To ${(item as any).destinationAirport}`;
      } else if (item.type === 'from-airport') {
        dest = `From ${(item as any).destinationAirport}`;
      }

      return {
        id: item.id, // UUID
        customerId: item.userId,
        customer: item.user, // The frontend uses customer.name/email/mobile
        pickupLocation: item.pickupLocation,
        destinationLocation: dest,
        pickupTime: pickupDate,
        vehicleModel: item.vehicleSelected,
        status: adminStatus,
        vehicleId: item.vehicleId,
        driverId: null, // Driver not directly linked in specific tables yet
        otpCode: null, // No OTP in specific tables
        createdAt: item.createdAt,
        // Include raw type for debug if needed
        rawType: item.type
      };
    });

    return res.json({ data: responseData, page, pageSize, total: total > limit ? "100+" : total });
  }
);

customersRouter.get(
  "/bookings/:id",
  requirePermissions(["customer:view", "dashboard:view"]),
  async (req, res) => {
    const idParam = req.params.id;

    try {
      // 1. Try Legacy Booking (Int ID)
      if (/^\d+$/.test(idParam)) {
        const id = parseInt(idParam);
        const booking = await prisma.booking.findUnique({
          where: { id },
          include: { customer: true },
        });
        if (booking) return res.json(booking);
      }

      // 2. Try Mobile App Bookings (UUID)
      const [mini, hourly, toAir, fromAir] = await Promise.all([
        prisma.miniTripBooking.findUnique({ where: { id: idParam }, include: { user: true, vehicle: true } }),
        prisma.hourlyRentalBooking.findUnique({ where: { id: idParam }, include: { user: true, vehicle: true } }),
        prisma.toAirportTransferBooking.findUnique({ where: { id: idParam }, include: { user: true, vehicle: true } }),
        prisma.fromAirportTransferBooking.findUnique({ where: { id: idParam }, include: { user: true, vehicle: true } })
      ]);

      const item = mini || hourly || toAir || fromAir;

      if (!item) {
        return res.status(404).json({ message: "Not found" });
      }

      // Map to proper Booking response for Admin
      let type = 'unknown';
      if (mini) type = 'mini-trip';
      else if (hourly) type = 'hourly';
      else if (toAir) type = 'to-airport';
      else if (fromAir) type = 'from-airport';

      const resolveDateTime = (dateVal: Date, timeVal?: Date) => {
        if (!timeVal) return dateVal;
        const d = new Date(dateVal);
        const t = new Date(timeVal);
        d.setHours(t.getHours(), t.getMinutes(), t.getSeconds());
        return d;
      };

      const pickupTime = resolveDateTime(item.pickupDate, item.pickupTime);

      let destinationLocation = null;
      if ((item as any).dropoffLocation) destinationLocation = (item as any).dropoffLocation;
      else if ((item as any).destinationAirport) destinationLocation = (item as any).destinationAirport;

      // Construct booking object matching schema for frontend
      const booking = {
        id: item.id,
        customerId: item.userId,
        customer: item.user,
        pickupLocation: item.pickupLocation,
        pickupLatitude: null,
        pickupLongitude: null,
        destinationLocation: destinationLocation,
        destinationLatitude: null,
        destinationLongitude: null,
        pickupTime: pickupTime,
        destinationTime: null,
        vehicleModel: (item as any).vehicleSelected || item.vehicle?.model,
        status: item.status,
        vehicleId: item.vehicleId,
        vehicle: item.vehicle,
        driverId: null,
        driver: null,
        otpCode: null,
        otpExpiresAt: null,
        createdAt: item.createdAt
      };

      return res.json(booking);

    } catch (e) {
      console.error(e);
      return res.status(500).json({ message: "Internal server error" });
    }
  }
);

customersRouter.post(
  "/bookings/:id/assign",
  requirePermissions(["customer:view", "dashboard:view"]),
  validateBody(bookingAssignSchema),
  async (req, res) => {
    const id = Number(req.params.id);
    const { vehicleId, driverId } = req.body;
    const booking = await prisma.booking.findUnique({ where: { id }, include: { customer: true } });
    if (!booking) return res.status(404).json({ message: "Not found" });

    if (!isBookingWithinAllowedAreas(booking)) {
      return res.status(400).json({
        message: "Booking pickup/destination are outside allowed service areas. Update locations first.",
      });
    }
    const otpCode = generateOtp();
    const otpExpiresAt = new Date(Date.now() + 15 * 60 * 1000);
    const updated = await prisma.booking.update({
      where: { id },
      data: { vehicleId, driverId, otpCode, otpExpiresAt, status: "assigned" },
      include: { customer: true },
    });

    await logAudit({
      actorId: req.user?.id,
      action: "booking:assign",
      entityType: "booking",
      entityId: String(id),
      before: booking,
      after: updated,
    });

    await queueNotification({
      actorId: req.user?.id,
      targetId: driverId,
      type: "booking.assigned",
      payload: { bookingId: id, otpCode, vehicleId, driverId },
    });
    await queueNotification({
      actorId: req.user?.id,
      targetId: booking.customerId,
      type: "booking.assigned.customer",
      payload: { bookingId: id, otpCode, vehicleId, driverId },
    });

    return res.json(updated);
  }
);

customersRouter.post(
  "/bookings/:id/validate-otp",
  validateBody(bookingOtpValidateSchema),
  async (req, res) => {
    const id = Number(req.params.id);
    const { otpCode } = req.body;
    const booking = await prisma.booking.findUnique({ where: { id } });
    if (!booking || !booking.otpCode || !booking.otpExpiresAt) {
      return res.status(400).json({ message: "No OTP set for this booking" });
    }
    if (booking.otpExpiresAt < new Date()) {
      return res.status(400).json({ message: "OTP expired" });
    }
    if (booking.otpCode !== otpCode) {
      return res.status(400).json({ message: "Invalid OTP" });
    }
    return res.json({ valid: true });
  }
);

const bookingStatusUpdateSchema = z.object({
  status: z.enum(["upcoming", "today", "assigned", "in_progress", "completed", "canceled"]),
  destinationTime: z.coerce.date().optional(),
  distanceKm: z.number().optional(),
});

const bookingLocationUpdateSchema = z.object({
  pickupLocation: z.string().min(1).optional(),
  destinationLocation: z.string().min(1).optional(),
  pickupLatitude: z.number().optional(),
  pickupLongitude: z.number().optional(),
  destinationLatitude: z.number().optional(),
  destinationLongitude: z.number().optional(),
});

// Basic point-in-polygon check (ray casting)
function isPointInPolygon(lat: number, lng: number, polygon: number[][]): boolean {
  let inside = false;
  for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    const xi = polygon[i][0], yi = polygon[i][1];
    const xj = polygon[j][0], yj = polygon[j][1];

    const intersect =
      yi > lng !== yj > lng &&
      lat < ((xj - xi) * (lng - yi)) / (yj - yi) + xi;
    if (intersect) inside = !inside;
  }
  return inside;
}

function isWithinAllowedAreas(lat?: number, lng?: number): boolean {
  if (lat === undefined || lng === undefined) return true; // No coords to validate
  if (!env.allowedServiceAreas.length) return true; // No restriction configured
  return env.allowedServiceAreas.some((poly) => isPointInPolygon(lat, lng, poly));
}

function isBookingWithinAllowedAreas(booking: any): boolean {
  const pickupOk = isWithinAllowedAreas(booking.pickupLatitude, booking.pickupLongitude);
  const destOk = isWithinAllowedAreas(booking.destinationLatitude, booking.destinationLongitude);
  return pickupOk && destOk;
}

customersRouter.patch(
  "/bookings/:id/status",
  requirePermissions(["customer:view", "dashboard:view"]),
  validateBody(bookingStatusUpdateSchema),
  async (req, res) => {
    const id = Number(req.params.id);
    const { status, destinationTime, distanceKm } = req.body;
    const booking = await prisma.booking.findUnique({ where: { id } });
    if (!booking) return res.status(404).json({ message: "Not found" });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const updateData: any = { status };
    if (destinationTime !== undefined) updateData.destinationTime = destinationTime;

    const updated = await prisma.booking.update({
      where: { id },
      data: updateData,
      include: { customer: true },
    });

    await logAudit({
      actorId: req.user?.id,
      action: "booking:update_status",
      entityType: "booking",
      entityId: String(id),
      before: booking,
      after: updated,
    });

    // If completed and has vehicle/driver, create ride summary
    if (status === "completed" && booking.vehicleId && booking.driverId && distanceKm !== undefined) {
      await prisma.rideSummary.create({
        data: {
          vehicleId: booking.vehicleId,
          driverId: booking.driverId,
          startedAt: booking.pickupTime,
          endedAt: destinationTime || new Date(),
          distanceKm,
          status: "completed",
        },
      });
    }

    await queueNotification({
      actorId: req.user?.id,
      targetId: booking.customerId,
      type: "booking.status_update",
      payload: { bookingId: id, status },
    });

    return res.json(updated);
  }
);

// Update booking pickup/drop locations and coordinates
customersRouter.patch(
  "/bookings/:id/locations",
  requirePermissions(["customer:view", "dashboard:view"]),
  validateBody(bookingLocationUpdateSchema),
  async (req, res) => {
    const id = Number(req.params.id);
    const booking = await prisma.booking.findUnique({ where: { id } });
    if (!booking) return res.status(404).json({ message: "Not found" });

    const {
      pickupLocation,
      destinationLocation,
      pickupLatitude,
      pickupLongitude,
      destinationLatitude,
      destinationLongitude,
    } = req.body;

    // Validate pickup coordinates within allowed polygons if provided
    if (
      pickupLatitude !== undefined &&
      pickupLongitude !== undefined &&
      !isWithinAllowedAreas(pickupLatitude, pickupLongitude)
    ) {
      return res.status(400).json({ message: "Pickup location is outside allowed service areas" });
    }

    // Validate destination coordinates within allowed polygons if provided
    if (
      destinationLatitude !== undefined &&
      destinationLongitude !== undefined &&
      !isWithinAllowedAreas(destinationLatitude, destinationLongitude)
    ) {
      return res
        .status(400)
        .json({ message: "Destination location is outside allowed service areas" });
    }

    // Use any to avoid Prisma type mismatch until client is regenerated
    const updateData: any = {
      pickupLocation: pickupLocation ?? booking.pickupLocation,
      destinationLocation: destinationLocation ?? booking.destinationLocation,
      pickupLatitude: pickupLatitude ?? (booking as any).pickupLatitude,
      pickupLongitude: pickupLongitude ?? (booking as any).pickupLongitude,
      destinationLatitude: destinationLatitude ?? (booking as any).destinationLatitude,
      destinationLongitude: destinationLongitude ?? (booking as any).destinationLongitude,
    };

    const updated = await prisma.booking.update({
      where: { id },
      data: updateData,
      include: { customer: true },
    });

    await logAudit({
      actorId: req.user?.id,
      action: "booking:update_locations",
      entityType: "booking",
      entityId: String(id),
      before: booking,
      after: updated,
    });

    return res.json(updated);
  }
);

customersRouter.post(
  "/bookings/:id/complete",
  requirePermissions(["customer:view", "dashboard:view"]),
  validateBody(z.object({ destinationTime: z.coerce.date().optional(), distanceKm: z.number().optional() })),
  async (req, res) => {
    const id = Number(req.params.id);
    const { destinationTime, distanceKm } = req.body;
    const booking = await prisma.booking.findUnique({ where: { id } });
    if (!booking) return res.status(404).json({ message: "Not found" });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const updateData: any = { status: "completed" };
    if (destinationTime !== undefined) updateData.destinationTime = destinationTime;

    const updated = await prisma.booking.update({
      where: { id },
      data: updateData,
      include: { customer: true },
    });

    if (booking.vehicleId && booking.driverId && distanceKm !== undefined) {
      await prisma.rideSummary.create({
        data: {
          vehicleId: booking.vehicleId,
          driverId: booking.driverId,
          startedAt: booking.pickupTime,
          endedAt: destinationTime || new Date(),
          distanceKm,
          status: "completed",
        },
      });
    }

    await logAudit({
      actorId: req.user?.id,
      action: "booking:complete",
      entityType: "booking",
      entityId: String(id),
      before: booking,
      after: updated,
    });

    await queueNotification({
      actorId: req.user?.id,
      targetId: booking.customerId,
      type: "booking.completed",
      payload: { bookingId: id },
    });

    return res.json(updated);
  }
);

customersRouter.post(
  "/bookings/:id/cancel",
  requirePermissions(["customer:view", "dashboard:view"]),
  validateBody(z.object({ reason: z.string().optional() })),
  async (req, res) => {
    const id = Number(req.params.id);
    const { reason } = req.body;
    const booking = await prisma.booking.findUnique({ where: { id } });
    if (!booking) return res.status(404).json({ message: "Not found" });

    const updated = await prisma.booking.update({
      where: { id },
      data: { status: "canceled" },
      include: { customer: true },
    });

    await logAudit({
      actorId: req.user?.id,
      action: "booking:cancel",
      entityType: "booking",
      entityId: String(id),
      before: booking,
      after: updated,
    });

    await queueNotification({
      actorId: req.user?.id,
      targetId: booking.customerId,
      type: "booking.canceled",
      payload: { bookingId: id, reason },
    });

    return res.json(updated);
  }
);



// Get customer dashboard statistics
customersRouter.get(
  "/customers/stats",
  requirePermissions(["customer:view"]),
  async (_req, res) => {
    try {
      const cacheKey = "customer:stats";
      let cachedData = null;
      try {
        cachedData = await redisClient.get(cacheKey);
      } catch (err) {
        console.warn("Redis cache get error:", err);
      }

      if (cachedData) {
        return res.json(JSON.parse(cachedData));
      }

      const totalCustomers = await prisma.customer.count();

      const totalBookings = await prisma.booking.count();

      const upcomingBookings = await prisma.booking.count({
        where: {
          status: "upcoming",
        },
      });

      const cancelledBookings = await prisma.booking.count({
        where: {
          status: "canceled",
        },
      });

      const result = {
        totalCustomers,
        totalBookings,
        upcomingBookings,
        cancelledBookings,
      };

      try {
        await redisClient.setEx(cacheKey, 60, JSON.stringify(result)); // Cache for 60 seconds
      } catch (err) {
        console.warn("Redis cache set error:", err);
      }

      return res.json(result);
    } catch (error) {
      console.error("Error fetching customer stats:", error);
      return res.status(500).json({ message: "Failed to fetch statistics" });
    }
  }
);

customersRouter.get(
  "/customers/:id",
  requirePermissions(["customer:view", "dashboard:view"]),
  async (req, res) => {
    const id = req.params.id; // UUID is string
    const customer = await prisma.customer.findUnique({ where: { id } });
    if (!customer) return res.status(404).json({ message: "Not found" });

    const completedCount = await prisma.booking.count({
      where: { customerId: id, status: "completed" },
    });

    const topDestinationsData = await prisma.booking.groupBy({
      by: ["destinationLocation"],
      where: { customerId: id },
      _count: true,
    });
    const topDestinations = topDestinationsData
      .sort((a, b) => (b._count as number) - (a._count as number))
      .slice(0, 3);

    const topVehicleModelsData = await prisma.booking.groupBy({
      by: ["vehicleModel"],
      where: { customerId: id },
      _count: true,
    });
    const topVehicleModels = topVehicleModelsData
      .sort((a, b) => (b._count as number) - (a._count as number))
      .slice(0, 3);

    const mostVisited = topDestinations[0]?.destinationLocation ?? null;

    const totalBookings = await prisma.booking.count({
      where: { customerId: id },
    });

    const upcomingBookings = await prisma.booking.count({
      where: { customerId: id, status: "upcoming" },
    });

    return res.json({
      ...customer,
      bookingsCount: totalBookings,
      upcomingBookingsCount: upcomingBookings,
      status: totalBookings > 0 ? "active" : "inactive",
      stats: {
        ridesCompleted: completedCount,
        mostVisitedLocation: mostVisited,
        topDestinations,
        topVehicleModels,
      },
    });
  }
);



// Create new customer
customersRouter.post(
  "/customers",
  requirePermissions(["customer:create"]),
  validateBody(z.object({
    name: z.string().min(1, "Name is required"),
    mobile: z.string().min(10, "Mobile number must be at least 10 digits"),
    email: z.string().email("Invalid email address").nullish().or(z.literal("")),
  })),
  async (req, res) => {
    try {
      const { name, mobile, email } = req.body;

      const existingCustomer = await prisma.customer.findFirst({
        where: { mobile },
      });

      if (existingCustomer) {
        return res.status(400).json({ message: "Customer with this mobile number already exists" });
      }

      const newCustomer = await prisma.customer.create({
        data: {
          name,
          mobile,
          email: email || null,
        },
      });

      return res.status(201).json(newCustomer);
    } catch (error) {
      console.error("Error creating customer:", error);
      return res.status(500).json({ message: "Failed to create customer" });
    }
  }
);

// Get all customers with pagination
customersRouter.get(
  "/customers",
  requirePermissions(["customer:view"]),
  async (req, res) => {
    try {
      const { skip, take, page, pageSize } = getPagination(req.query);
      const { search, status } = req.query;

      const cacheKey = `customers:list:${page}:${pageSize}:${search || ""}:${status || ""}`;
      let cachedData = null;
      try {
        cachedData = await redisClient.get(cacheKey);
      } catch (err) {
        console.warn("Redis cache get error:", err);
      }

      if (cachedData) {
        return res.json(JSON.parse(cachedData));
      }

      // Build where clause
      const where: any = {};

      if (search) {
        where.OR = [
          { name: { contains: String(search), mode: "insensitive" } },
          { mobile: { contains: String(search), mode: "insensitive" } },
          { email: { contains: String(search), mode: "insensitive" } },
        ];
      }

      if (status === "active") {
        where.bookings = { some: {} };
      } else if (status === "inactive") {
        where.bookings = { none: {} };
      }

      const customers = await prisma.customer.findMany({
        where,
        skip,
        take,
        orderBy: { id: "desc" },
        include: {
          _count: {
            select: { bookings: true },
          },
          bookings: {
            where: { status: "upcoming" },
            select: { id: true },
          },
        },
      });

      const total = await prisma.customer.count({ where });

      const transformedCustomers = customers.map((customer) => ({
        id: customer.id,
        name: customer.name,
        mobile: customer.mobile,
        email: customer.email,
        bookingsCount: customer._count.bookings,
        upcomingBookingsCount: customer.bookings.length,
        status: customer._count.bookings > 0 ? "active" : "inactive",
      }));


      const result = {
        data: transformedCustomers,
        page,
        pageSize,
        total,
      };

      try {
        await redisClient.setEx(cacheKey, 30, JSON.stringify(result));
      } catch (err) {
        console.warn("Redis cache set error:", err);
      }

      return res.json(result);
    } catch (error) {
      console.error("Error fetching customers:", error);
      return res.status(500).json({ message: "Failed to fetch customers" });
    }
  }
);

// Get customer's rides/bookings
customersRouter.get(
  "/customers/:id/rides",
  requirePermissions(["customer:view"]),
  async (req, res) => {
    try {
      const customerId = req.params.id; // UUID is string
      const limit = req.query.limit ? Number(req.query.limit) : 5;

      const bookings = await prisma.booking.findMany({
        where: { customerId },
        take: limit,
        orderBy: { pickupTime: "desc" },
        select: {
          id: true,
          pickupLocation: true,
          destinationLocation: true,
          pickupTime: true,
          destinationTime: true,
          status: true,
          vehicleModel: true,
          driverId: true,
          vehicleId: true,
        },
      });

      // Fetch driver and vehicle details for each booking
      const ridesWithDetails = await Promise.all(
        bookings.map(async (booking) => {
          let driverName = "Not Assigned";
          let vehicleInfo = booking.vehicleModel || "Not Assigned";

          if (booking.driverId) {
            const driver = await prisma.driver.findUnique({
              where: { id: booking.driverId },
              select: { name: true },
            });
            if (driver) driverName = driver.name;
          }

          if (booking.vehicleId) {
            const vehicle = await prisma.vehicle.findUnique({
              where: { id: booking.vehicleId },
              select: { numberPlate: true, make: true, model: true },
            });
            if (vehicle) {
              vehicleInfo = `${vehicle.make} ${vehicle.model} (${vehicle.numberPlate})`;
            }
          }

          return {
            id: booking.id,
            driverName,
            vehicleInfo,
            pickupTime: booking.pickupTime,
            dropTime: booking.destinationTime,
            pickupLocation: booking.pickupLocation,
            dropLocation: booking.destinationLocation,
            status: booking.status,
          };
        })
      );

      return res.json(ridesWithDetails);
    } catch (error) {
      console.error("Error fetching customer rides:", error);
      return res.status(500).json({ message: "Failed to fetch rides" });
    }
  }
);

// Get ride/booking details
customersRouter.get(
  "/rides/:id",
  requirePermissions(["customer:view"]),
  async (req, res) => {
    try {
      const id = Number(req.params.id);

      const booking = await prisma.booking.findUnique({
        where: { id },
        include: {
          customer: {
            select: { name: true, mobile: true },
          },
        },
      });

      if (!booking) {
        return res.status(404).json({ message: "Ride not found" });
      }

      // Fetch driver details
      let driverName = "Not Assigned";
      let driverMobile = "";
      if (booking.driverId) {
        const driver = await prisma.driver.findUnique({
          where: { id: booking.driverId },
          select: { name: true, mobile: true },
        });
        if (driver) {
          driverName = driver.name;
          driverMobile = driver.mobile;
        }
      }

      // Fetch vehicle details
      let vehicleInfo = booking.vehicleModel || "Not Assigned";
      let vehicleNumberPlate = "";
      if (booking.vehicleId) {
        const vehicle = await prisma.vehicle.findUnique({
          where: { id: booking.vehicleId },
          select: { numberPlate: true, make: true, model: true },
        });
        if (vehicle) {
          vehicleInfo = `${vehicle.make} ${vehicle.model}`;
          vehicleNumberPlate = vehicle.numberPlate;
        }
      }

      const rideDetails = {
        id: booking.id,
        customerName: booking.customer.name,
        customerMobile: booking.customer.mobile,
        driverName,
        driverMobile,
        vehicleInfo,
        vehicleNumberPlate,
        pickupTime: booking.pickupTime,
        dropTime: booking.destinationTime,
        pickupLocation: booking.pickupLocation,
        pickupLatitude: (booking as any).pickupLatitude,
        pickupLongitude: (booking as any).pickupLongitude,
        dropLocation: booking.destinationLocation,
        destinationLatitude: (booking as any).destinationLatitude,
        destinationLongitude: (booking as any).destinationLongitude,
        status: booking.status,
        otpCode: booking.otpCode,
        createdAt: booking.createdAt,
      };

      return res.json(rideDetails);
    } catch (error) {
      console.error("Error fetching ride details:", error);
      return res.status(500).json({ message: "Failed to fetch ride details" });
    }
  }
);

