"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.vehiclesRouter = void 0;
const express_1 = require("express");
const client_1 = __importDefault(require("../prisma/client"));
const auth_1 = require("../middleware/auth");
const permissions_1 = require("../middleware/permissions");
const audit_1 = require("../utils/audit");
const logs_1 = require("../utils/logs");
const notifications_1 = require("../services/notifications");
const validate_1 = require("../validation/validate");
const schemas_1 = require("../validation/schemas");
const pagination_1 = require("../utils/pagination");
exports.vehiclesRouter = (0, express_1.Router)();
exports.vehiclesRouter.use(auth_1.authMiddleware);
// Get available vehicle makes and models
exports.vehiclesRouter.get("/vehicles/makes-models", 
// Allow access if user has any of these permissions (for vehicle allocation during onboarding)
(req, res, next) => {
    const user = req.user;
    if (!user?.permissions) {
        return res.status(403).json({ message: "Forbidden" });
    }
    const hasPermission = user.permissions.includes("vehicle:view") ||
        user.permissions.includes("vehicle:create") ||
        user.permissions.includes("vehicle:assign");
    if (!hasPermission) {
        return res.status(403).json({
            message: "Missing permissions: vehicle:view or vehicle:create or vehicle:assign",
        });
    }
    return next();
}, async (_req, res) => {
    // Fixed makes and models configuration
    const makesAndModels = {
        MG: ["Windsor"],
        BYD: ["E-max"],
        KIA: ["Carrens"],
        BMW: ["i-1Max"],
    };
    return res.json(makesAndModels);
});
exports.vehiclesRouter.post("/vehicles", (0, permissions_1.requirePermissions)(["vehicle:create"]), (0, validate_1.validateBody)(schemas_1.vehicleCreateSchema), async (req, res) => {
    const { numberPlate, make, model, insurancePolicyNumber, insuranceExpiry, liveLocationKey, dashcamKey } = req.body;
    try {
        const vehicle = await client_1.default.vehicle.create({
            data: {
                numberPlate,
                make,
                model,
                insurancePolicyNumber,
                insuranceExpiry: insuranceExpiry ? new Date(insuranceExpiry) : undefined,
                liveLocationKey,
                dashcamKey,
                status: "pending",
                createdBy: req.user?.id,
            },
        });
        await (0, audit_1.logAudit)({
            actorId: req.user?.id,
            action: "vehicle:create",
            entityType: "vehicle",
            entityId: String(vehicle.id),
            after: vehicle,
        });
        await (0, logs_1.logVehicleAction)({
            vehicleId: vehicle.id,
            actorId: req.user?.id,
            action: "create",
            payload: vehicle,
        });
        return res.json(vehicle);
    }
    catch (_err) {
        return res.status(400).json({ message: "Unable to create vehicle" });
    }
});
exports.vehiclesRouter.get("/vehicles", (0, permissions_1.requirePermissions)(["vehicle:view"]), async (req, res) => {
    const { skip, take, page, pageSize } = (0, pagination_1.getPagination)(req.query);
    const { status, search, make } = req.query;
    const vehicles = await client_1.default.vehicle.findMany({
        where: {
            status: status ? String(status) : undefined,
            make: make ? String(make) : undefined,
            OR: search
                ? [
                    { numberPlate: { contains: String(search), mode: "insensitive" } },
                    { make: { contains: String(search), mode: "insensitive" } },
                    { model: { contains: String(search), mode: "insensitive" } },
                ]
                : undefined,
        },
        skip,
        take,
        orderBy: { createdAt: "desc" },
        include: {
            assignments: {
                where: { unassignedAt: null },
                include: {
                    driver: {
                        select: { name: true },
                    },
                },
            },
        },
    });
    const total = await client_1.default.vehicle.count({
        where: {
            status: status ? String(status) : undefined,
            make: make ? String(make) : undefined,
            OR: search
                ? [
                    { numberPlate: { contains: String(search), mode: "insensitive" } },
                    { make: { contains: String(search), mode: "insensitive" } },
                    { model: { contains: String(search), mode: "insensitive" } },
                ]
                : undefined,
        },
    });
    return res.json({ data: vehicles, page, pageSize, total });
});
// Get available vehicles by make (for allocation)
exports.vehiclesRouter.get("/vehicles/available", 
// Allow access if user has vehicle:view and vehicle:assign
(req, res, next) => {
    const user = req.user;
    if (!user?.permissions) {
        return res.status(403).json({ message: "Forbidden" });
    }
    const hasView = user.permissions.includes("vehicle:view");
    const hasAssign = user.permissions.includes("vehicle:assign");
    if (!hasView || !hasAssign) {
        return res.status(403).json({
            message: "Missing permissions: vehicle:view and vehicle:assign",
        });
    }
    return next();
}, async (req, res) => {
    const { make, shiftTiming } = req.query;
    // Get all approved/active vehicles
    const allVehicles = await client_1.default.vehicle.findMany({
        where: {
            status: { in: ["approved", "active"] },
            make: make ? String(make) : undefined,
        },
        include: {
            assignments: {
                where: {
                    unassignedAt: null, // Only active assignments
                },
            },
        },
    });
    // Filter vehicles that have less than 2 active assignments
    // Each vehicle can have 2 drivers (one per shift)
    const availableVehicles = allVehicles.filter((vehicle) => {
        const activeAssignments = vehicle.assignments.length;
        // If shiftTiming is provided, check if there's already a driver for that shift
        if (shiftTiming) {
            // For now, we'll allow assignment if less than 2 drivers
            // You can enhance this to check specific shift timing later
            return activeAssignments < 2;
        }
        return activeAssignments < 2;
    });
    return res.json(availableVehicles);
});
exports.vehiclesRouter.post("/vehicles/:id/review", 
// Allow either vehicle:review or vehicle:approve permission
(req, res, next) => {
    const user = req.user;
    if (!user?.permissions) {
        return res.status(403).json({ message: "Forbidden" });
    }
    const hasPermission = user.permissions.includes("vehicle:review") ||
        user.permissions.includes("vehicle:approve");
    if (!hasPermission) {
        return res.status(403).json({
            message: "Missing permissions: vehicle:review or vehicle:approve",
        });
    }
    return next();
}, (0, validate_1.validateBody)(schemas_1.vehicleReviewSchema), async (req, res) => {
    const id = Number(req.params.id);
    const { status, comments } = req.body;
    const vehicle = await client_1.default.vehicle.findUnique({ where: { id } });
    if (!vehicle)
        return res.status(404).json({ message: "Not found" });
    const review = await client_1.default.vehicleReview.create({
        data: { vehicleId: id, reviewerId: req.user?.id, status, comments },
    });
    await client_1.default.vehicle.update({ where: { id }, data: { status } });
    await (0, audit_1.logAudit)({
        actorId: req.user?.id,
        action: "vehicle:review",
        entityType: "vehicle",
        entityId: String(id),
        after: review,
    });
    await (0, logs_1.logVehicleAction)({
        vehicleId: id,
        actorId: req.user?.id,
        action: "review",
        payload: { status, comments },
    });
    await (0, notifications_1.queueNotification)({
        actorId: req.user?.id,
        type: "vehicle.review",
        payload: { vehicleId: id, status, comments },
    });
    return res.json(review);
});
exports.vehiclesRouter.post("/vehicles/:id/assign-driver", (0, permissions_1.requirePermissions)(["vehicle:assign"]), async (req, res) => {
    const id = Number(req.params.id);
    const { driverId } = req.body;
    const vehicle = await client_1.default.vehicle.findUnique({ where: { id } });
    if (!vehicle)
        return res.status(404).json({ message: "Not found" });
    const assignment = await client_1.default.vehicleAssignment.create({
        data: { vehicleId: id, driverId, assignedBy: req.user?.id },
    });
    await (0, audit_1.logAudit)({
        actorId: req.user?.id,
        action: "vehicle:assign",
        entityType: "vehicle",
        entityId: String(id),
        after: assignment,
    });
    await (0, logs_1.logVehicleAction)({
        vehicleId: id,
        actorId: req.user?.id,
        action: "assign_driver",
        payload: { driverId },
    });
    await (0, notifications_1.queueNotification)({
        actorId: req.user?.id,
        type: "vehicle.assign_driver",
        payload: { vehicleId: id, driverId },
    });
    return res.json(assignment);
});
exports.vehiclesRouter.get("/vehicles/:id/logs", (0, permissions_1.requirePermissions)(["vehicle:logs"]), async (req, res) => {
    const id = Number(req.params.id);
    const logs = await client_1.default.vehicleLog.findMany({ where: { vehicleId: id }, orderBy: { createdAt: "desc" } });
    return res.json(logs);
});
exports.vehiclesRouter.get("/vehicles/:id/metrics", (0, permissions_1.requirePermissions)(["vehicle:view"]), async (req, res) => {
    const id = Number(req.params.id);
    const rides = await client_1.default.rideSummary.aggregate({
        where: { vehicleId: id },
        _count: { id: true },
        _sum: { distanceKm: true },
    });
    return res.json({
        totalRides: rides._count.id || 0,
        totalDistanceKm: rides._sum.distanceKm || 0,
    });
});
