import { Router } from "express";
import prisma from "../prisma/client";
import { authMiddleware } from "../middleware/auth";
import { requirePermissions } from "../middleware/permissions";
import { logAudit } from "../utils/audit";
import { validateBody } from "../validation/validate";
import { z } from "zod";
import { getPagination } from "../utils/pagination";

export const ridesRouter = Router();

ridesRouter.use("/rides", authMiddleware);

const rideCreateSchema = z.object({
  vehicleId: z.number(),
  driverId: z.number().optional(),
  startedAt: z.coerce.date(),
  endedAt: z.coerce.date().optional(),
  distanceKm: z.number().optional(),
  status: z.enum(["in_progress", "completed", "canceled"]).default("completed"),
});

const rideUpdateSchema = z.object({
  endedAt: z.coerce.date().optional(),
  distanceKm: z.number().optional(),
  status: z.enum(["in_progress", "completed", "canceled"]).optional(),
});

ridesRouter.post(
  "/rides",
  requirePermissions(["ride:create"]),
  validateBody(rideCreateSchema),
  async (req, res) => {
    const { vehicleId, driverId, startedAt, endedAt, distanceKm, status } = req.body;
    const vehicle = await prisma.vehicle.findUnique({ where: { id: vehicleId } });
    if (!vehicle) return res.status(404).json({ message: "Vehicle not found" });

    if (driverId) {
      const driver = await prisma.driver.findUnique({ where: { id: driverId } });
      if (!driver) return res.status(404).json({ message: "Driver not found" });
    }

    const ride = await prisma.rideSummary.create({
      data: {
        vehicleId,
        driverId,
        startedAt,
        endedAt,
        distanceKm,
        status: status || "completed",
      },
    });

    await logAudit({
      actorId: req.user?.id,
      action: "ride:create",
      entityType: "ride",
      entityId: String(ride.id),
      after: ride,
    });

    return res.json(ride);
  }
);

ridesRouter.get(
  "/rides",
  requirePermissions(["ride:view"]),
  async (req, res) => {
    const { skip, take, page, pageSize } = getPagination(req.query);
    const { vehicleId, driverId, status, startDate, endDate } = req.query;

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const where: any = {};
    if (vehicleId) where.vehicleId = Number(vehicleId);
    if (driverId) where.driverId = Number(driverId);
    if (status) where.status = String(status);
    if (startDate || endDate) {
      where.startedAt = {};
      if (startDate) where.startedAt.gte = new Date(String(startDate));
      if (endDate) where.startedAt.lte = new Date(String(endDate));
    }

    const [rides, total] = await Promise.all([
      prisma.rideSummary.findMany({
        where,
        include: {
          vehicle: true,
          driver: true,
        },
        skip,
        take,
        orderBy: { startedAt: "desc" },
      }),
      prisma.rideSummary.count({ where }),
    ]);

    return res.json({ data: rides, page, pageSize, total });
  }
);

ridesRouter.get(
  "/rides/:id",
  requirePermissions(["ride:view"]),
  async (req, res) => {
    const id = Number(req.params.id);
    const ride = await prisma.rideSummary.findUnique({
      where: { id },
      include: {
        vehicle: true,
        driver: true,
      },
    });
    if (!ride) return res.status(404).json({ message: "Not found" });
    return res.json(ride);
  }
);

ridesRouter.patch(
  "/rides/:id",
  requirePermissions(["ride:update"]),
  validateBody(rideUpdateSchema),
  async (req, res) => {
    const id = Number(req.params.id);
    const { endedAt, distanceKm, status } = req.body;
    const existing = await prisma.rideSummary.findUnique({ where: { id } });
    if (!existing) return res.status(404).json({ message: "Not found" });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const updateData: any = {};
    if (endedAt !== undefined) updateData.endedAt = endedAt;
    if (distanceKm !== undefined) updateData.distanceKm = distanceKm;
    if (status !== undefined) updateData.status = status;

    const updated = await prisma.rideSummary.update({
      where: { id },
      data: updateData,
    });

    await logAudit({
      actorId: req.user?.id,
      action: "ride:update",
      entityType: "ride",
      entityId: String(id),
      before: existing,
      after: updated,
    });

    return res.json(updated);
  }
);

