"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ridesRouter = void 0;
const express_1 = require("express");
const client_1 = __importDefault(require("../prisma/client"));
const auth_1 = require("../middleware/auth");
const permissions_1 = require("../middleware/permissions");
const audit_1 = require("../utils/audit");
const validate_1 = require("../validation/validate");
const zod_1 = require("zod");
const pagination_1 = require("../utils/pagination");
exports.ridesRouter = (0, express_1.Router)();
exports.ridesRouter.use(auth_1.authMiddleware);
const rideCreateSchema = zod_1.z.object({
    vehicleId: zod_1.z.number(),
    driverId: zod_1.z.number().optional(),
    startedAt: zod_1.z.coerce.date(),
    endedAt: zod_1.z.coerce.date().optional(),
    distanceKm: zod_1.z.number().optional(),
    status: zod_1.z.enum(["in_progress", "completed", "canceled"]).default("completed"),
});
const rideUpdateSchema = zod_1.z.object({
    endedAt: zod_1.z.coerce.date().optional(),
    distanceKm: zod_1.z.number().optional(),
    status: zod_1.z.enum(["in_progress", "completed", "canceled"]).optional(),
});
exports.ridesRouter.post("/rides", (0, permissions_1.requirePermissions)(["ride:create"]), (0, validate_1.validateBody)(rideCreateSchema), async (req, res) => {
    const { vehicleId, driverId, startedAt, endedAt, distanceKm, status } = req.body;
    const vehicle = await client_1.default.vehicle.findUnique({ where: { id: vehicleId } });
    if (!vehicle)
        return res.status(404).json({ message: "Vehicle not found" });
    if (driverId) {
        const driver = await client_1.default.driver.findUnique({ where: { id: driverId } });
        if (!driver)
            return res.status(404).json({ message: "Driver not found" });
    }
    const ride = await client_1.default.rideSummary.create({
        data: {
            vehicleId,
            driverId,
            startedAt,
            endedAt,
            distanceKm,
            status: status || "completed",
        },
    });
    await (0, audit_1.logAudit)({
        actorId: req.user?.id,
        action: "ride:create",
        entityType: "ride",
        entityId: String(ride.id),
        after: ride,
    });
    return res.json(ride);
});
exports.ridesRouter.get("/rides", (0, permissions_1.requirePermissions)(["ride:view"]), async (req, res) => {
    const { skip, take, page, pageSize } = (0, pagination_1.getPagination)(req.query);
    const { vehicleId, driverId, status, startDate, endDate } = req.query;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const where = {};
    if (vehicleId)
        where.vehicleId = Number(vehicleId);
    if (driverId)
        where.driverId = Number(driverId);
    if (status)
        where.status = String(status);
    if (startDate || endDate) {
        where.startedAt = {};
        if (startDate)
            where.startedAt.gte = new Date(String(startDate));
        if (endDate)
            where.startedAt.lte = new Date(String(endDate));
    }
    const [rides, total] = await Promise.all([
        client_1.default.rideSummary.findMany({
            where,
            include: {
                vehicle: true,
                driver: true,
            },
            skip,
            take,
            orderBy: { startedAt: "desc" },
        }),
        client_1.default.rideSummary.count({ where }),
    ]);
    return res.json({ data: rides, page, pageSize, total });
});
exports.ridesRouter.get("/rides/:id", (0, permissions_1.requirePermissions)(["ride:view"]), async (req, res) => {
    const id = Number(req.params.id);
    const ride = await client_1.default.rideSummary.findUnique({
        where: { id },
        include: {
            vehicle: true,
            driver: true,
        },
    });
    if (!ride)
        return res.status(404).json({ message: "Not found" });
    return res.json(ride);
});
exports.ridesRouter.patch("/rides/:id", (0, permissions_1.requirePermissions)(["ride:update"]), (0, validate_1.validateBody)(rideUpdateSchema), async (req, res) => {
    const id = Number(req.params.id);
    const { endedAt, distanceKm, status } = req.body;
    const existing = await client_1.default.rideSummary.findUnique({ where: { id } });
    if (!existing)
        return res.status(404).json({ message: "Not found" });
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const updateData = {};
    if (endedAt !== undefined)
        updateData.endedAt = endedAt;
    if (distanceKm !== undefined)
        updateData.distanceKm = distanceKm;
    if (status !== undefined)
        updateData.status = status;
    const updated = await client_1.default.rideSummary.update({
        where: { id },
        data: updateData,
    });
    await (0, audit_1.logAudit)({
        actorId: req.user?.id,
        action: "ride:update",
        entityType: "ride",
        entityId: String(id),
        before: existing,
        after: updated,
    });
    return res.json(updated);
});
