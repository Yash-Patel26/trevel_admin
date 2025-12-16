import { Router } from "express";
import prisma from "../prisma/client";
import { authMiddleware } from "../middleware/auth";
import { requirePermissions } from "../middleware/permissions";
import { logAudit } from "../utils/audit";
import { logVehicleAction } from "../utils/logs";
import { queueNotification } from "../services/notifications";
import { validateBody } from "../validation/validate";
import { vehicleCreateSchema, vehicleReviewSchema } from "../validation/schemas";
import { getPagination } from "../utils/pagination";

export const vehiclesRouter = Router();

vehiclesRouter.use("/vehicles", authMiddleware);

// Get available vehicle makes and models
vehiclesRouter.get(
  "/vehicles/makes-models",
  // Allow access if user has any of these permissions (for vehicle allocation during onboarding)
  (req, res, next) => {
    const user = req.user;
    if (!user?.permissions) {
      return res.status(403).json({ message: "Forbidden" });
    }
    const hasPermission =
      user.permissions.includes("vehicle:view") ||
      user.permissions.includes("vehicle:create") ||
      user.permissions.includes("vehicle:assign");
    if (!hasPermission) {
      return res.status(403).json({
        message: "Missing permissions: vehicle:view or vehicle:create or vehicle:assign",
      });
    }
    return next();
  },
  async (_req, res) => {
    // Fixed makes and models configuration
    const makesAndModels = {
      MG: ["Windsor"],
      BYD: ["E-max"],
      KIA: ["Carrens"],
      BMW: ["i-1Max"],
    };
    return res.json(makesAndModels);
  }
);

vehiclesRouter.post(
  "/vehicles",
  requirePermissions(["vehicle:create"]),
  validateBody(vehicleCreateSchema),
  async (req, res) => {
    const { numberPlate, make, model, insurancePolicyNumber, insuranceExpiry, liveLocationKey, dashcamKey } =
      req.body;
    try {
      const vehicle = await prisma.vehicle.create({
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
      await logAudit({
        actorId: req.user?.id,
        action: "vehicle:create",
        entityType: "vehicle",
        entityId: String(vehicle.id),
        after: vehicle,
      });
      await logVehicleAction({
        vehicleId: vehicle.id,
        actorId: req.user?.id,
        action: "create",
        payload: vehicle,
      });
      return res.json(vehicle);
    } catch (_err) {
      return res.status(400).json({ message: "Unable to create vehicle" });
    }
  }
);

vehiclesRouter.get(
  "/vehicles",
  requirePermissions(["vehicle:view"]),
  async (req, res) => {
    const { skip, take, page, pageSize } = getPagination(req.query);
    const { status, search, make } = req.query;
    const vehicles = await prisma.vehicle.findMany({
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
              select: { id: true, name: true, status: true },
            },
          },
        },
      },
    });
    const total = await prisma.vehicle.count({
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
  }
);

// Get available vehicles by make (for allocation)
vehiclesRouter.get(
  "/vehicles/available",
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
  },
  async (req, res) => {
    const { make, shiftTiming } = req.query;

    // Get all approved/active vehicles
    const allVehicles = await prisma.vehicle.findMany({
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
  }
);

vehiclesRouter.post(
  "/vehicles/:id/review",
  // Allow either vehicle:review or vehicle:approve permission
  (req, res, next) => {
    const user = req.user;
    if (!user?.permissions) {
      return res.status(403).json({ message: "Forbidden" });
    }
    const hasPermission =
      user.permissions.includes("vehicle:review") ||
      user.permissions.includes("vehicle:approve");
    if (!hasPermission) {
      return res.status(403).json({
        message: "Missing permissions: vehicle:review or vehicle:approve",
      });
    }
    return next();
  },
  validateBody(vehicleReviewSchema),
  async (req, res) => {
    const id = req.params.id;
    const { status, comments } = req.body;

    const vehicle = await prisma.vehicle.findUnique({ where: { id } });
    if (!vehicle) return res.status(404).json({ message: "Not found" });

    const review = await prisma.vehicleReview.create({
      data: { vehicleId: id, reviewerId: req.user?.id, status, comments },
    });
    await prisma.vehicle.update({ where: { id }, data: { status } });
    await logAudit({
      actorId: req.user?.id,
      action: "vehicle:review",
      entityType: "vehicle",
      entityId: String(id),
      after: review,
    });
    await logVehicleAction({
      vehicleId: id,
      actorId: req.user?.id,
      action: "review",
      payload: { status, comments },
    });
    await queueNotification({
      actorId: req.user?.id,
      type: "vehicle.review",
      payload: { vehicleId: id, status, comments },
    });
    return res.json(review);
  }
);

vehiclesRouter.post(
  "/vehicles/:id/assign-driver",
  requirePermissions(["vehicle:assign"]),
  async (req, res) => {
    const id = req.params.id;
    const { driverId } = req.body;
    const vehicle = await prisma.vehicle.findUnique({ where: { id } });
    if (!vehicle) return res.status(404).json({ message: "Not found" });
    const assignment = await prisma.vehicleAssignment.create({
      data: { vehicleId: id, driverId, assignedBy: req.user?.id },
    });
    await logAudit({
      actorId: req.user?.id,
      action: "vehicle:assign",
      entityType: "vehicle",
      entityId: String(id),
      after: assignment,
    });
    await logVehicleAction({
      vehicleId: id,
      actorId: req.user?.id,
      action: "assign_driver",
      payload: { driverId },
    });
    await queueNotification({
      actorId: req.user?.id,
      type: "vehicle.assign_driver",
      payload: { vehicleId: id, driverId },
    });
    return res.json(assignment);
  }
);

vehiclesRouter.get(
  "/vehicles/:id/logs",
  requirePermissions(["vehicle:logs"]),
  async (req, res) => {
    const id = req.params.id;
    const logs = await prisma.vehicleLog.findMany({ where: { vehicleId: id }, orderBy: { createdAt: "desc" } });
    return res.json(logs);
  }
);

vehiclesRouter.get(
  "/vehicles/:id/metrics",
  requirePermissions(["vehicle:view"]),
  async (req, res) => {
    const id = req.params.id;
    const rides = await prisma.rideSummary.aggregate({
      where: { vehicleId: id },
      _count: { id: true },
      _sum: { distanceKm: true },
    });
    return res.json({
      totalRides: rides._count.id || 0,
      totalDistanceKm: rides._sum.distanceKm || 0,
    });
  }
);

// Reassign vehicle to a new driver
vehiclesRouter.post(
  "/vehicles/:id/reassign",
  requirePermissions(["vehicle:assign"]),
  async (req, res) => {
    const id = req.params.id;
    const { driverId } = req.body;

    if (!driverId) {
      return res.status(400).json({ message: "driverId is required" });
    }

    try {
      const vehicle = await prisma.vehicle.findUnique({
        where: { id },
        include: {
          assignments: {
            where: { unassignedAt: null },
            include: { driver: true }
          }
        }
      });

      if (!vehicle) {
        return res.status(404).json({ message: "Vehicle not found" });
      }

      // Check if new driver exists and is active
      const newDriver = await prisma.driver.findUnique({ where: { id: driverId } });
      if (!newDriver) {
        return res.status(404).json({ message: "Driver not found" });
      }
      if (newDriver.status !== "active" && newDriver.status !== "approved") {
        return res.status(400).json({ message: "Driver must be active or approved" });
      }

      // Unassign current driver(s)
      const currentAssignments = vehicle.assignments;
      for (const assignment of currentAssignments) {
        await prisma.vehicleAssignment.update({
          where: { id: assignment.id },
          data: { unassignedAt: new Date() },
        });

        // Log the unassignment
        await logVehicleAction({
          vehicleId: id,
          actorId: req.user?.id,
          action: "unassign_driver",
          payload: {
            driverId: assignment.driverId,
            driverName: assignment.driver.name,
            reason: "reassignment"
          },
        });
      }

      // Create new assignment
      const newAssignment = await prisma.vehicleAssignment.create({
        data: {
          vehicleId: id,
          driverId,
          assignedBy: req.user?.id
        },
        include: { driver: true }
      });

      // Log the reassignment
      await logAudit({
        actorId: req.user?.id,
        action: "vehicle:reassign",
        entityType: "vehicle",
        entityId: String(id),
        before: currentAssignments.length > 0 ? {
          driverId: currentAssignments[0].driverId,
          driverName: currentAssignments[0].driver.name
        } : null,
        after: {
          driverId: newAssignment.driverId,
          driverName: newAssignment.driver.name
        },
      });

      await logVehicleAction({
        vehicleId: id,
        actorId: req.user?.id,
        action: "reassign_driver",
        payload: {
          newDriverId: driverId,
          newDriverName: newDriver.name,
          previousDriverId: currentAssignments.length > 0 ? currentAssignments[0].driverId : null,
          previousDriverName: currentAssignments.length > 0 ? currentAssignments[0].driver.name : null
        },
      });

      await queueNotification({
        actorId: req.user?.id,
        type: "vehicle.reassign",
        payload: { vehicleId: id, driverId, driverName: newDriver.name },
      });

      return res.json({
        message: "Vehicle reassigned successfully",
        assignment: newAssignment
      });
    } catch (error) {
      console.error("Error reassigning vehicle:", error);
      return res.status(500).json({ message: "Failed to reassign vehicle" });
    }
  }
);

// Get vehicle assignment logs/history
vehiclesRouter.get(
  "/vehicles/:id/assignment-logs",
  requirePermissions(["vehicle:view"]),
  async (req, res) => {
    const id = req.params.id;

    try {
      // Get all assignment-related logs from VehicleLog
      const logs = await prisma.vehicleLog.findMany({
        where: {
          vehicleId: id,
          action: {
            in: ["assign_driver", "unassign_driver", "reassign_driver"]
          }
        },
        orderBy: { createdAt: "desc" },
      });

      // Transform logs to include driver name from payload
      const formattedLogs = logs.map(log => ({
        id: log.id,
        action: log.action,
        driverName: (log.payload as any)?.driverName ||
          (log.payload as any)?.newDriverName ||
          "Unknown",
        createdAt: log.createdAt,
        actorId: log.actorId,
        payload: log.payload
      }));

      return res.json(formattedLogs);
    } catch (error) {
      console.error("Error fetching assignment logs:", error);
      return res.status(500).json({ message: "Failed to fetch assignment logs" });
    }
  }
);

