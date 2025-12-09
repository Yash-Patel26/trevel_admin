"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.customersRouter = void 0;
const express_1 = require("express");
const client_1 = require("@prisma/client");
const auth_1 = require("../middleware/auth");
const permissions_1 = require("../middleware/permissions");
const client_2 = __importDefault(require("../prisma/client"));
const pagination_1 = require("../utils/pagination");
const validate_1 = require("../validation/validate");
const schemas_1 = require("../validation/schemas");
const otp_1 = require("../utils/otp");
const notifications_1 = require("../services/notifications");
const audit_1 = require("../utils/audit");
const zod_1 = require("zod");
exports.customersRouter = (0, express_1.Router)();
exports.customersRouter.use(auth_1.authMiddleware);
exports.customersRouter.get("/customers/dashboard/summary", (0, permissions_1.requirePermissions)(["customer:view", "dashboard:view"]), async (_req, res) => {
    const now = new Date();
    const startOfToday = new Date(now);
    startOfToday.setHours(0, 0, 0, 0);
    const endOfToday = new Date(now);
    endOfToday.setHours(23, 59, 59, 999);
    const [totalBookings, todaysBookings, upcomingBookings] = await Promise.all([
        client_2.default.booking.count(),
        client_2.default.booking.count({ where: { pickupTime: { gte: startOfToday, lte: endOfToday } } }),
        client_2.default.booking.count({ where: { pickupTime: { gt: now } } }),
    ]);
    return res.json({
        totalBookings,
        todaysBookings,
        upcomingBookings,
    });
});
exports.customersRouter.get("/customers/bookings", (0, permissions_1.requirePermissions)(["customer:view", "dashboard:view"]), async (req, res) => {
    const { skip, take, page, pageSize } = (0, pagination_1.getPagination)(req.query);
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
                { customer: { name: { contains: String(search), mode: client_1.Prisma.QueryMode.insensitive } } },
                { customer: { mobile: { contains: String(search), mode: client_1.Prisma.QueryMode.insensitive } } },
                { customer: { email: { contains: String(search), mode: client_1.Prisma.QueryMode.insensitive } } },
            ]
            : undefined,
    };
    const [bookings, total] = await Promise.all([
        client_2.default.booking.findMany({
            where,
            include: { customer: true },
            orderBy: { pickupTime: "desc" },
            skip,
            take,
        }),
        client_2.default.booking.count({ where }),
    ]);
    return res.json({ data: bookings, page, pageSize, total });
});
exports.customersRouter.get("/bookings/:id", (0, permissions_1.requirePermissions)(["customer:view", "dashboard:view"]), async (req, res) => {
    const id = Number(req.params.id);
    const booking = await client_2.default.booking.findUnique({
        where: { id },
        include: { customer: true },
    });
    if (!booking)
        return res.status(404).json({ message: "Not found" });
    return res.json(booking);
});
exports.customersRouter.post("/bookings/:id/assign", (0, permissions_1.requirePermissions)(["customer:view", "dashboard:view"]), (0, validate_1.validateBody)(schemas_1.bookingAssignSchema), async (req, res) => {
    const id = Number(req.params.id);
    const { vehicleId, driverId } = req.body;
    const booking = await client_2.default.booking.findUnique({ where: { id }, include: { customer: true } });
    if (!booking)
        return res.status(404).json({ message: "Not found" });
    const otpCode = (0, otp_1.generateOtp)();
    const otpExpiresAt = new Date(Date.now() + 15 * 60 * 1000);
    const updated = await client_2.default.booking.update({
        where: { id },
        data: { vehicleId, driverId, otpCode, otpExpiresAt, status: "assigned" },
        include: { customer: true },
    });
    await (0, audit_1.logAudit)({
        actorId: req.user?.id,
        action: "booking:assign",
        entityType: "booking",
        entityId: String(id),
        before: booking,
        after: updated,
    });
    await (0, notifications_1.queueNotification)({
        actorId: req.user?.id,
        targetId: driverId,
        type: "booking.assigned",
        payload: { bookingId: id, otpCode, vehicleId, driverId },
    });
    await (0, notifications_1.queueNotification)({
        actorId: req.user?.id,
        targetId: booking.customerId,
        type: "booking.assigned.customer",
        payload: { bookingId: id, otpCode, vehicleId, driverId },
    });
    return res.json(updated);
});
exports.customersRouter.post("/bookings/:id/validate-otp", (0, validate_1.validateBody)(schemas_1.bookingOtpValidateSchema), async (req, res) => {
    const id = Number(req.params.id);
    const { otpCode } = req.body;
    const booking = await client_2.default.booking.findUnique({ where: { id } });
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
});
const bookingStatusUpdateSchema = zod_1.z.object({
    status: zod_1.z.enum(["upcoming", "today", "assigned", "in_progress", "completed", "canceled"]),
    destinationTime: zod_1.z.coerce.date().optional(),
    distanceKm: zod_1.z.number().optional(),
});
exports.customersRouter.patch("/bookings/:id/status", (0, permissions_1.requirePermissions)(["customer:view", "dashboard:view"]), (0, validate_1.validateBody)(bookingStatusUpdateSchema), async (req, res) => {
    const id = Number(req.params.id);
    const { status, destinationTime, distanceKm } = req.body;
    const booking = await client_2.default.booking.findUnique({ where: { id } });
    if (!booking)
        return res.status(404).json({ message: "Not found" });
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const updateData = { status };
    if (destinationTime !== undefined)
        updateData.destinationTime = destinationTime;
    const updated = await client_2.default.booking.update({
        where: { id },
        data: updateData,
        include: { customer: true },
    });
    await (0, audit_1.logAudit)({
        actorId: req.user?.id,
        action: "booking:update_status",
        entityType: "booking",
        entityId: String(id),
        before: booking,
        after: updated,
    });
    // If completed and has vehicle/driver, create ride summary
    if (status === "completed" && booking.vehicleId && booking.driverId && distanceKm !== undefined) {
        await client_2.default.rideSummary.create({
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
    await (0, notifications_1.queueNotification)({
        actorId: req.user?.id,
        targetId: booking.customerId,
        type: "booking.status_update",
        payload: { bookingId: id, status },
    });
    return res.json(updated);
});
exports.customersRouter.post("/bookings/:id/complete", (0, permissions_1.requirePermissions)(["customer:view", "dashboard:view"]), (0, validate_1.validateBody)(zod_1.z.object({ destinationTime: zod_1.z.coerce.date().optional(), distanceKm: zod_1.z.number().optional() })), async (req, res) => {
    const id = Number(req.params.id);
    const { destinationTime, distanceKm } = req.body;
    const booking = await client_2.default.booking.findUnique({ where: { id } });
    if (!booking)
        return res.status(404).json({ message: "Not found" });
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const updateData = { status: "completed" };
    if (destinationTime !== undefined)
        updateData.destinationTime = destinationTime;
    const updated = await client_2.default.booking.update({
        where: { id },
        data: updateData,
        include: { customer: true },
    });
    if (booking.vehicleId && booking.driverId && distanceKm !== undefined) {
        await client_2.default.rideSummary.create({
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
    await (0, audit_1.logAudit)({
        actorId: req.user?.id,
        action: "booking:complete",
        entityType: "booking",
        entityId: String(id),
        before: booking,
        after: updated,
    });
    await (0, notifications_1.queueNotification)({
        actorId: req.user?.id,
        targetId: booking.customerId,
        type: "booking.completed",
        payload: { bookingId: id },
    });
    return res.json(updated);
});
exports.customersRouter.post("/bookings/:id/cancel", (0, permissions_1.requirePermissions)(["customer:view", "dashboard:view"]), (0, validate_1.validateBody)(zod_1.z.object({ reason: zod_1.z.string().optional() })), async (req, res) => {
    const id = Number(req.params.id);
    const { reason } = req.body;
    const booking = await client_2.default.booking.findUnique({ where: { id } });
    if (!booking)
        return res.status(404).json({ message: "Not found" });
    const updated = await client_2.default.booking.update({
        where: { id },
        data: { status: "canceled" },
        include: { customer: true },
    });
    await (0, audit_1.logAudit)({
        actorId: req.user?.id,
        action: "booking:cancel",
        entityType: "booking",
        entityId: String(id),
        before: booking,
        after: updated,
    });
    await (0, notifications_1.queueNotification)({
        actorId: req.user?.id,
        targetId: booking.customerId,
        type: "booking.canceled",
        payload: { bookingId: id, reason },
    });
    return res.json(updated);
});
exports.customersRouter.get("/customers/:id", (0, permissions_1.requirePermissions)(["customer:view", "dashboard:view"]), async (req, res) => {
    const id = Number(req.params.id);
    const customer = await client_2.default.customer.findUnique({ where: { id } });
    if (!customer)
        return res.status(404).json({ message: "Not found" });
    const completedCount = await client_2.default.booking.count({
        where: { customerId: id, status: "completed" },
    });
    const topDestinationsData = await client_2.default.booking.groupBy({
        by: ["destinationLocation"],
        where: { customerId: id },
        _count: true,
    });
    const topDestinations = topDestinationsData
        .sort((a, b) => b._count - a._count)
        .slice(0, 3);
    const topVehicleModelsData = await client_2.default.booking.groupBy({
        by: ["vehicleModel"],
        where: { customerId: id },
        _count: true,
    });
    const topVehicleModels = topVehicleModelsData
        .sort((a, b) => b._count - a._count)
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
});
