import { Router } from "express";
import { authMiddleware } from "../middleware/auth";
import { requirePermissions } from "../middleware/permissions";
import prisma from "../prisma/client";

export const dashboardsRouter = Router();

dashboardsRouter.use(authMiddleware);

dashboardsRouter.get(
  "/dashboards/fleet",
  requirePermissions(["dashboard:view"]),
  async (_req, res) => {
    const totalVehicles = await prisma.vehicle.count();
    const activeVehicles = await prisma.vehicle.count({ where: { status: "active" } });
    const totalRides = await prisma.rideSummary.count();
    const perVehicleDistance = await prisma.rideSummary.groupBy({
      by: ["vehicleId"],
      _sum: { distanceKm: true },
    });
    return res.json({
      totalVehicles,
      activeVehicles,
      totalRides,
      perVehicleDistance,
    });
  }
);

dashboardsRouter.get(
  "/dashboards/vehicle/:id",
  requirePermissions(["dashboard:view"]),
  async (req, res) => {
    const id = req.params.id;
    const vehicle = await prisma.vehicle.findUnique({ where: { id } });
    if (!vehicle) return res.status(404).json({ message: "Not found" });
    const rides = await prisma.rideSummary.findMany({ where: { vehicleId: id } });
    return res.json({ vehicle, rides });
  }
);

dashboardsRouter.get(
  "/dashboards/drivers",
  requirePermissions(["dashboard:view"]),
  async (_req, res) => {
    const drivers = await prisma.driver.findMany();
    return res.json({ drivers });
  }
);

dashboardsRouter.get(
  "/dashboards/driver/:id",
  requirePermissions(["dashboard:view"]),
  async (req, res) => {
    const id = req.params.id;
    const driver = await prisma.driver.findUnique({ where: { id } });
    if (!driver) return res.status(404).json({ message: "Not found" });
    const logs = await prisma.driverLog.findMany({ where: { driverId: id }, orderBy: { createdAt: "desc" } });
    return res.json({ driver, logs });
  }
);

