"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.dashboardsRouter = void 0;
const express_1 = require("express");
const auth_1 = require("../middleware/auth");
const permissions_1 = require("../middleware/permissions");
const client_1 = __importDefault(require("../prisma/client"));
exports.dashboardsRouter = (0, express_1.Router)();
exports.dashboardsRouter.use(auth_1.authMiddleware);
exports.dashboardsRouter.get("/dashboards/fleet", (0, permissions_1.requirePermissions)(["dashboard:view"]), async (_req, res) => {
    const totalVehicles = await client_1.default.vehicle.count();
    const activeVehicles = await client_1.default.vehicle.count({ where: { status: "active" } });
    const totalRides = await client_1.default.rideSummary.count();
    const perVehicleDistance = await client_1.default.rideSummary.groupBy({
        by: ["vehicleId"],
        _sum: { distanceKm: true },
    });
    return res.json({
        totalVehicles,
        activeVehicles,
        totalRides,
        perVehicleDistance,
    });
});
exports.dashboardsRouter.get("/dashboards/vehicle/:id", (0, permissions_1.requirePermissions)(["dashboard:view"]), async (req, res) => {
    const id = Number(req.params.id);
    const vehicle = await client_1.default.vehicle.findUnique({ where: { id } });
    if (!vehicle)
        return res.status(404).json({ message: "Not found" });
    const rides = await client_1.default.rideSummary.findMany({ where: { vehicleId: id } });
    return res.json({ vehicle, rides });
});
exports.dashboardsRouter.get("/dashboards/drivers", (0, permissions_1.requirePermissions)(["dashboard:view"]), async (_req, res) => {
    const drivers = await client_1.default.driver.findMany();
    return res.json({ drivers });
});
exports.dashboardsRouter.get("/dashboards/driver/:id", (0, permissions_1.requirePermissions)(["dashboard:view"]), async (req, res) => {
    const id = Number(req.params.id);
    const driver = await client_1.default.driver.findUnique({ where: { id } });
    if (!driver)
        return res.status(404).json({ message: "Not found" });
    const logs = await client_1.default.driverLog.findMany({ where: { driverId: id }, orderBy: { createdAt: "desc" } });
    return res.json({ driver, logs });
});
