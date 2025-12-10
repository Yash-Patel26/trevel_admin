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

    const [totalBookings, todaysBookings, upcomingBookings] = await Promise.all([
      prisma.booking.count(),
      prisma.booking.count({ where: { pickupTime: { gte: startOfToday, lte: endOfToday } } }),
      prisma.booking.count({ where: { pickupTime: { gt: now } } }),
    ]);

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
    const { status, startDate, endDate, search } = req.query;

    const dateFilter = startDate || endDate ? {
      gte: startDate ? new Date(String(startDate)) : undefined,
      lte: endDate ? new Date(String(endDate)) : undefined,
    } : undefined;

    const where = {
      status: status ? String(status) : undefined,
      pickupTime: dateFilter,
      OR: search
        ? [
          { customer: { name: { contains: String(search), mode: Prisma.QueryMode.insensitive } } },
          { customer: { mobile: { contains: String(search), mode: Prisma.QueryMode.insensitive } } },
          { customer: { email: { contains: String(search), mode: Prisma.QueryMode.insensitive } } },
        ]
        : undefined,
    };

    const [bookings, total] = await Promise.all([
      prisma.booking.findMany({
        where,
        include: { customer: true },
        orderBy: { pickupTime: "desc" },
        skip,
        take,
      }),
      prisma.booking.count({ where }),
    ]);

    return res.json({ data: bookings, page, pageSize, total });
  }
);

customersRouter.get(
  "/bookings/:id",
  requirePermissions(["customer:view", "dashboard:view"]),
  async (req, res) => {
    const id = Number(req.params.id);
    const booking = await prisma.booking.findUnique({
      where: { id },
      include: { customer: true },
    });
    if (!booking) return res.status(404).json({ message: "Not found" });
    return res.json(booking);
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

customersRouter.get(
  "/customers/:id",
  requirePermissions(["customer:view", "dashboard:view"]),
  async (req, res) => {
    const id = Number(req.params.id);
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

    return res.json({
      customer,
      stats: {
        ridesCompleted: completedCount,
        mostVisitedLocation: mostVisited,
        topDestinations,
        topVehicleModels,
      },
    });
  }
);

