"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.driversRouter = void 0;
const express_1 = require("express");
const client_1 = require("@prisma/client");
const bcrypt_1 = __importDefault(require("bcrypt"));
const client_2 = __importDefault(require("../prisma/client"));
const auth_1 = require("../middleware/auth");
const permissions_1 = require("../middleware/permissions");
const audit_1 = require("../utils/audit");
const logs_1 = require("../utils/logs");
const notifications_1 = require("../services/notifications");
const upload_1 = require("../middleware/upload");
const schemas_1 = require("../validation/schemas");
const validate_1 = require("../validation/validate");
const pagination_1 = require("../utils/pagination");
exports.driversRouter = (0, express_1.Router)();
exports.driversRouter.use(auth_1.authMiddleware);
exports.driversRouter.post("/drivers", (0, permissions_1.requirePermissions)(["driver:create"]), (0, validate_1.validateBody)(schemas_1.driverCreateSchema), async (req, res) => {
    const { name, mobile, email, onboardingData, contactPreferences } = req.body;
    // If Driver Admin or Operational Admin creates a driver, auto-approve it
    const isDriverAdmin = req.user?.role === "Driver Admin";
    const isOperationalAdmin = req.user?.role === "Operational Admin";
    const initialStatus = (isDriverAdmin || isOperationalAdmin) ? "approved" : "pending";
    // 1. Create User account for the driver so they can login
    // Default password: "Trevel@123"
    let userId;
    try {
        // Check if user already exists
        const existingUser = await client_2.default.user.findUnique({ where: { email } });
        if (existingUser) {
            // If user exists, we link the driver to this user (though your schema doesn't strictly link Driver -> User for login, 
            // the Auth system uses User table. So existence is enough).
            // However, we might want to ensure they have the "Driver Individual" role or permissions.
            // For now, we assume if email exists, that user will be the one logging in.
            userId = existingUser.id;
        }
        else {
            // Find Driver Individual role
            const driverRole = await client_2.default.role.findUnique({ where: { name: "Driver Individual" } });
            if (!driverRole) {
                return res.status(500).json({ message: "Driver role configuration error" });
            }
            const hashedPassword = await bcrypt_1.default.hash("Trevel@123", 10);
            const newUser = await client_2.default.user.create({
                data: {
                    email,
                    fullName: name,
                    passwordHash: hashedPassword,
                    roleId: driverRole.id,
                    isActive: true, // Allow login immediately or perhaps match driver status? 
                    // Usually they need to login to complete onboarding, so true is better.
                },
            });
            userId = newUser.id;
        }
    }
    catch (error) {
        console.error("Error creating user for driver:", error);
        return res.status(500).json({ message: "Failed to create user account for driver" });
    }
    const driver = await client_2.default.driver.create({
        data: {
            name,
            mobile,
            email,
            onboardingData,
            contactPreferences,
            status: initialStatus,
            createdBy: req.user?.id,
        },
    });
    await (0, audit_1.logAudit)({
        actorId: req.user?.id,
        action: "driver:create",
        entityType: "driver",
        entityId: String(driver.id),
        after: driver,
    });
    await (0, logs_1.logDriverAction)({
        driverId: driver.id,
        actorId: req.user?.id,
        action: "create",
        payload: driver,
    });
    return res.json(driver);
});
exports.driversRouter.get("/drivers", (0, permissions_1.requirePermissions)(["driver:view"]), async (req, res) => {
    const { skip, take, page, pageSize } = (0, pagination_1.getPagination)(req.query);
    const { status, search } = req.query;
    // For Driver Individual role, only show drivers they created
    const isDriverIndividual = req.user?.role === "Driver Individual";
    // For Team role, only show drivers created by Driver Individual users
    const isTeam = req.user?.role === "Team";
    let where = {
        status: status ? String(status) : undefined,
        OR: search
            ? [
                { name: { contains: String(search), mode: client_1.Prisma.QueryMode.insensitive } },
                { mobile: { contains: String(search), mode: client_1.Prisma.QueryMode.insensitive } },
                { email: { contains: String(search), mode: client_1.Prisma.QueryMode.insensitive } },
            ]
            : undefined,
    };
    if (isDriverIndividual) {
        // Filter by createdBy for Driver Individual
        where.createdBy = req.user?.id;
    }
    else if (isTeam) {
        // For Team, only show drivers created by users with "Driver Individual" role
        const driverIndividualRole = await client_2.default.role.findUnique({
            where: { name: "Driver Individual" },
        });
        if (driverIndividualRole) {
            const driverIndividualUsers = await client_2.default.user.findMany({
                where: { roleId: driverIndividualRole.id },
                select: { id: true },
            });
            const driverIndividualUserIds = driverIndividualUsers.map((u) => u.id);
            where.createdBy = { in: driverIndividualUserIds };
        }
        else {
            // If role doesn't exist, return empty results
            where.createdBy = { in: [] };
        }
    }
    const [drivers, total] = await Promise.all([
        client_2.default.driver.findMany({
            where,
            skip,
            take,
            orderBy: { createdAt: "desc" },
            include: {
                assignments: {
                    where: { unassignedAt: null },
                    include: {
                        vehicle: {
                            select: { numberPlate: true },
                        },
                    },
                },
            },
        }),
        client_2.default.driver.count({ where }),
    ]);
    return res.json({ data: drivers, page, pageSize, total });
});
// Check if mobile number already exists
exports.driversRouter.get("/drivers/check-mobile", (0, permissions_1.requirePermissions)(["driver:create", "driver:view"]), async (req, res) => {
    const { mobile } = req.query;
    if (!mobile || typeof mobile !== "string") {
        return res.status(400).json({ message: "Mobile number is required" });
    }
    const existingDriver = await client_2.default.driver.findFirst({
        where: { mobile: mobile.trim() },
        select: { id: true, name: true, mobile: true },
    });
    return res.json({ exists: !!existingDriver, driver: existingDriver });
});
exports.driversRouter.post("/drivers/:id/background", (0, permissions_1.requirePermissions)(["driver:verify"]), (0, validate_1.validateBody)(schemas_1.driverBackgroundSchema), async (req, res) => {
    const id = Number(req.params.id);
    const { status, notes } = req.body;
    const driver = await client_2.default.driver.findUnique({ where: { id } });
    if (!driver)
        return res.status(404).json({ message: "Not found" });
    const bg = await client_2.default.driverBackgroundCheck.create({
        data: { driverId: id, status, notes, verifiedBy: req.user?.id },
    });
    await client_2.default.driver.update({
        where: { id },
        data: { status: status === "clear" ? "verified" : driver.status },
    });
    await (0, audit_1.logAudit)({
        actorId: req.user?.id,
        action: "driver:verify",
        entityType: "driver",
        entityId: String(id),
        after: bg,
    });
    await (0, logs_1.logDriverAction)({
        driverId: id,
        actorId: req.user?.id,
        action: "background",
        payload: { status, notes },
    });
    await (0, notifications_1.queueNotification)({
        actorId: req.user?.id,
        type: "driver.background",
        payload: { driverId: id, status },
    });
    return res.json(bg);
});
exports.driversRouter.post("/drivers/:id/training", (0, permissions_1.requirePermissions)(["driver:train"]), (0, validate_1.validateBody)(schemas_1.driverTrainingSchema), async (req, res) => {
    const id = Number(req.params.id);
    const { module, status } = req.body;
    const driver = await client_2.default.driver.findUnique({ where: { id } });
    if (!driver)
        return res.status(404).json({ message: "Not found" });
    // Check if training assignment already exists for this module
    const existingTraining = await client_2.default.driverTrainingAssignment.findFirst({
        where: { driverId: id, module },
    });
    let training;
    if (existingTraining) {
        // Update existing training
        training = await client_2.default.driverTrainingAssignment.update({
            where: { id: existingTraining.id },
            data: { status, completedAt: status === "completed" ? new Date() : null },
        });
    }
    else {
        // Create new training assignment
        training = await client_2.default.driverTrainingAssignment.create({
            data: {
                driverId: id,
                module,
                status,
                assignedBy: req.user?.id,
                completedAt: status === "completed" ? new Date() : null,
            },
        });
    }
    // Check if all required training modules are completed
    // Required modules: "safety", "customer_service", "navigation", "vehicle_handling"
    const requiredModules = ["safety", "customer_service", "navigation", "vehicle_handling"];
    const allTrainings = await client_2.default.driverTrainingAssignment.findMany({
        where: { driverId: id },
    });
    const completedModules = allTrainings
        .filter((t) => t.status === "completed" && requiredModules.includes(t.module))
        .map((t) => t.module);
    const allCompleted = requiredModules.every((module) => completedModules.includes(module));
    // Update driver status to "training_completed" if all modules are done
    let updatedDriver = driver;
    if (allCompleted && driver.status === "vehicle_assigned") {
        updatedDriver = await client_2.default.driver.update({
            where: { id },
            data: { status: "training_completed" },
        });
    }
    await (0, audit_1.logAudit)({
        actorId: req.user?.id,
        action: "driver:train",
        entityType: "driver",
        entityId: String(id),
        after: { ...training, driverStatus: updatedDriver.status, allCompleted },
    });
    await (0, logs_1.logDriverAction)({
        driverId: id,
        actorId: req.user?.id,
        action: "training",
        payload: { module, status, allCompleted, driverStatus: updatedDriver.status },
    });
    await (0, notifications_1.queueNotification)({
        actorId: req.user?.id,
        type: "driver.training",
        payload: { driverId: id, module, status, allCompleted },
    });
    return res.json({ ...training, driver: updatedDriver, allCompleted });
});
exports.driversRouter.post("/drivers/:id/approve", (0, permissions_1.requirePermissions)(["driver:approve"]), (0, validate_1.validateBody)(schemas_1.driverApproveSchema), async (req, res) => {
    const id = Number(req.params.id);
    const { decision } = req.body;
    const driver = await client_2.default.driver.findUnique({ where: { id } });
    if (!driver)
        return res.status(404).json({ message: "Not found" });
    // Determine status based on role and decision
    let newStatus = decision;
    const isTeam = req.user?.role === "Team";
    const isDriverAdmin = req.user?.role === "Driver Admin";
    const isOperationalAdmin = req.user?.role === "Operational Admin";
    if (isTeam && decision === "approved") {
        // Team approval sets status to "verified"
        newStatus = "verified";
    }
    else if ((isDriverAdmin || isOperationalAdmin) && decision === "approved") {
        // Driver Admin and Operational Admin approval sets status to "approved"
        newStatus = "approved";
    }
    const updated = await client_2.default.driver.update({ where: { id }, data: { status: newStatus } });
    await (0, audit_1.logAudit)({
        actorId: req.user?.id,
        action: "driver:approve",
        entityType: "driver",
        entityId: String(id),
        after: updated,
    });
    await (0, logs_1.logDriverAction)({
        driverId: id,
        actorId: req.user?.id,
        action: isTeam ? "verify" : "approve",
        payload: { decision, newStatus, role: req.user?.role, approvedBy: req.user?.role },
    });
    await (0, notifications_1.queueNotification)({
        actorId: req.user?.id,
        type: "driver.approve",
        payload: { driverId: id, decision, newStatus },
    });
    return res.json(updated);
});
// Get comprehensive audit trail for a driver
exports.driversRouter.get("/drivers/:id/audit-trail", (0, permissions_1.requirePermissions)(["driver:view"]), async (req, res) => {
    const id = Number(req.params.id);
    const driver = await client_2.default.driver.findUnique({ where: { id } });
    if (!driver)
        return res.status(404).json({ message: "Not found" });
    // Get audit logs
    const auditLogs = await client_2.default.auditLog.findMany({
        where: {
            entityType: "driver",
            entityId: String(id),
        },
        include: {
            actor: {
                select: {
                    id: true,
                    fullName: true,
                    email: true,
                },
            },
        },
        orderBy: { createdAt: "asc" },
    });
    // Get driver logs
    const driverLogs = await client_2.default.driverLog.findMany({
        where: { driverId: id },
        orderBy: { createdAt: "asc" },
    });
    // Get vehicle assignments
    const vehicleAssignments = await client_2.default.vehicleAssignment.findMany({
        where: { driverId: id },
        include: {
            vehicle: {
                select: {
                    id: true,
                    numberPlate: true,
                    make: true,
                    model: true,
                },
            },
        },
        orderBy: { assignedAt: "asc" },
    });
    // Get background checks
    const backgroundChecks = await client_2.default.driverBackgroundCheck.findMany({
        where: { driverId: id },
        orderBy: { verifiedAt: "asc" },
    });
    // Get training assignments
    const trainingAssignments = await client_2.default.driverTrainingAssignment.findMany({
        where: { driverId: id },
        orderBy: { completedAt: "asc" },
    });
    // Fetch user info for assignedBy, verifiedBy, and actorId fields
    const userIds = new Set();
    vehicleAssignments.forEach((a) => {
        if (a.assignedBy)
            userIds.add(a.assignedBy);
    });
    backgroundChecks.forEach((b) => {
        if (b.verifiedBy)
            userIds.add(b.verifiedBy);
    });
    trainingAssignments.forEach((t) => {
        if (t.assignedBy)
            userIds.add(t.assignedBy);
    });
    driverLogs.forEach((log) => {
        if (log.actorId)
            userIds.add(log.actorId);
    });
    auditLogs.forEach((log) => {
        if (log.actorId)
            userIds.add(log.actorId);
    });
    const users = await client_2.default.user.findMany({
        where: { id: { in: Array.from(userIds) } },
        select: {
            id: true,
            fullName: true,
            email: true,
        },
    });
    const userMap = new Map(users.map((u) => [u.id, u]));
    // Get creator info
    const creator = driver.createdBy
        ? await client_2.default.user.findUnique({
            where: { id: driver.createdBy },
            select: {
                id: true,
                fullName: true,
                email: true,
            },
        })
        : null;
    // Combine all events into a chronological timeline
    const timeline = [];
    // Add creation event
    if (creator) {
        timeline.push({
            type: "creation",
            action: "Driver Created",
            actor: creator,
            timestamp: driver.createdAt,
            details: { driverId: id, driverName: driver.name },
        });
    }
    // Add audit log events
    auditLogs.forEach((log) => {
        const actor = log.actorId ? userMap.get(log.actorId) : undefined;
        timeline.push({
            type: "audit",
            action: log.action,
            actor: actor
                ? {
                    id: actor.id,
                    fullName: actor.fullName,
                    email: actor.email,
                }
                : undefined,
            timestamp: log.createdAt,
            details: log.after || log.before,
        });
    });
    // Add driver log events
    driverLogs.forEach((log) => {
        const actor = log.actorId ? userMap.get(log.actorId) : undefined;
        timeline.push({
            type: "driver_log",
            action: log.action,
            actor: actor
                ? {
                    id: actor.id,
                    fullName: actor.fullName,
                    email: actor.email,
                }
                : undefined,
            timestamp: log.createdAt,
            details: log.payload,
        });
    });
    // Add vehicle assignment events
    vehicleAssignments.forEach((assignment) => {
        const actor = assignment.assignedBy
            ? userMap.get(assignment.assignedBy)
            : undefined;
        timeline.push({
            type: "vehicle_assignment",
            action: "Vehicle Assigned",
            actor: actor
                ? {
                    id: actor.id,
                    fullName: actor.fullName,
                    email: actor.email,
                }
                : undefined,
            timestamp: assignment.assignedAt,
            details: {
                vehicleId: assignment.vehicleId,
                vehicle: assignment.vehicle
                    ? {
                        numberPlate: assignment.vehicle.numberPlate,
                        make: assignment.vehicle.make,
                        model: assignment.vehicle.model,
                    }
                    : null,
                unassignedAt: assignment.unassignedAt,
            },
        });
    });
    // Add background check events
    backgroundChecks.forEach((check) => {
        if (check.verifiedAt) {
            const actor = check.verifiedBy ? userMap.get(check.verifiedBy) : undefined;
            timeline.push({
                type: "background_check",
                action: "Background Check Verified",
                actor: actor
                    ? {
                        id: actor.id,
                        fullName: actor.fullName,
                        email: actor.email,
                    }
                    : undefined,
                timestamp: check.verifiedAt,
                details: {
                    status: check.status,
                    notes: check.notes,
                },
            });
        }
    });
    // Add training completion events
    trainingAssignments
        .filter((t) => t.completedAt != null)
        .forEach((training) => {
        const actor = training.assignedBy
            ? userMap.get(training.assignedBy)
            : undefined;
        timeline.push({
            type: "training",
            action: `Training Module Completed: ${training.module}`,
            actor: actor
                ? {
                    id: actor.id,
                    fullName: actor.fullName,
                    email: actor.email,
                }
                : undefined,
            timestamp: training.completedAt,
            details: {
                module: training.module,
                status: training.status,
            },
        });
    });
    // Sort by timestamp
    timeline.sort((a, b) => a.timestamp.getTime() - b.timestamp.getTime());
    return res.json({
        driverId: id,
        timeline,
        summary: {
            createdBy: creator,
            createdAt: driver.createdAt,
            currentStatus: driver.status,
            vehicleAssignments: vehicleAssignments.length,
            backgroundChecks: backgroundChecks.length,
            trainingModules: trainingAssignments.length,
            completedTrainingModules: trainingAssignments.filter((t) => t.completedAt != null).length,
        },
    });
});
exports.driversRouter.post("/drivers/:id/assign-vehicle", (0, permissions_1.requirePermissions)(["driver:assign", "vehicle:assign"]), (0, validate_1.validateBody)(schemas_1.assignVehicleSchema), async (req, res) => {
    const id = Number(req.params.id);
    const { vehicleId } = req.body;
    const driver = await client_2.default.driver.findUnique({ where: { id } });
    if (!driver)
        return res.status(404).json({ message: "Not found" });
    const assignment = await client_2.default.vehicleAssignment.create({
        data: { driverId: id, vehicleId, assignedBy: req.user?.id },
    });
    // Update driver status to "vehicle_assigned"
    const updatedDriver = await client_2.default.driver.update({
        where: { id },
        data: { status: "vehicle_assigned" },
    });
    await (0, audit_1.logAudit)({
        actorId: req.user?.id,
        action: "driver:assign_vehicle",
        entityType: "driver",
        entityId: String(id),
        after: { ...assignment, driverStatus: updatedDriver.status },
    });
    await (0, logs_1.logDriverAction)({
        driverId: id,
        actorId: req.user?.id,
        action: "assign_vehicle",
        payload: { vehicleId, status: "vehicle_assigned" },
    });
    await (0, notifications_1.queueNotification)({
        actorId: req.user?.id,
        type: "driver.assign_vehicle",
        payload: { driverId: id, vehicleId },
    });
    return res.json({ ...assignment, driver: updatedDriver });
});
exports.driversRouter.get("/drivers/:id/logs", (0, permissions_1.requirePermissions)(["driver:logs"]), async (req, res) => {
    const id = Number(req.params.id);
    const logs = await client_2.default.driverLog.findMany({ where: { driverId: id }, orderBy: { createdAt: "desc" } });
    return res.json(logs);
});
// Get driver documents
exports.driversRouter.get("/drivers/:id/documents", (0, permissions_1.requirePermissions)(["driver:view"]), async (req, res) => {
    const id = Number(req.params.id);
    const driver = await client_2.default.driver.findUnique({ where: { id } });
    if (!driver)
        return res.status(404).json({ message: "Driver not found" });
    const documents = await client_2.default.driverDocument.findMany({
        where: { driverId: id },
        orderBy: { id: "desc" },
    });
    return res.json(documents);
});
// Upload driver document
exports.driversRouter.post("/drivers/:id/documents", (0, permissions_1.requirePermissions)(["driver:create", "driver:edit"]), (req, res) => {
    (0, upload_1.uploadSingle)(req, res, async (err) => {
        if (err) {
            return res.status(400).json({ message: err.message || "File upload failed" });
        }
        if (!req.file) {
            return res.status(400).json({ message: "No file uploaded" });
        }
        const id = Number(req.params.id);
        const { type } = req.body;
        if (!type) {
            return res.status(400).json({ message: "Document type is required" });
        }
        try {
            const driver = await client_2.default.driver.findUnique({ where: { id } });
            if (!driver) {
                return res.status(404).json({ message: "Driver not found" });
            }
            // Check ownership for Driver Individual
            if (req.user?.role === "Driver Individual" && driver.createdBy !== req.user.id) {
                return res.status(403).json({ message: "Forbidden: You can only upload documents for your own profile" });
            }
            // Generate URL for the uploaded file
            const fileUrl = `/uploads/${req.file.filename}`;
            const fullUrl = `${req.protocol}://${req.get("host")}${fileUrl}`;
            const document = await client_2.default.driverDocument.create({
                data: {
                    driverId: id,
                    type: String(type),
                    url: fullUrl,
                    status: "uploaded",
                },
            });
            await (0, audit_1.logAudit)({
                actorId: req.user?.id,
                action: "driver:document:upload",
                entityType: "driver_document",
                entityId: String(document.id),
                after: document,
            });
            await (0, logs_1.logDriverAction)({
                driverId: id,
                actorId: req.user?.id,
                action: "document_upload",
                payload: { documentId: document.id, type, url: fullUrl },
            });
            return res.json(document);
        }
        catch (error) {
            return res.status(500).json({ message: "Failed to save document", error: String(error) });
        }
    });
});
// Delete driver document
exports.driversRouter.delete("/drivers/:id/documents/:documentId", (0, permissions_1.requirePermissions)(["driver:edit", "driver:delete"]), async (req, res) => {
    const id = Number(req.params.id);
    const documentId = Number(req.params.documentId);
    try {
        const document = await client_2.default.driverDocument.findFirst({
            where: { id: documentId, driverId: id },
        });
        if (!document) {
            return res.status(404).json({ message: "Document not found" });
        }
        // Check ownership for Driver Individual
        if (req.user?.role === "Driver Individual") {
            const driver = await client_2.default.driver.findUnique({ where: { id } });
            if (driver && driver.createdBy !== req.user.id) {
                return res.status(403).json({ message: "Forbidden: You can only delete documents from your own profile" });
            }
        }
        await client_2.default.driverDocument.delete({
            where: { id: documentId },
        });
        await (0, audit_1.logAudit)({
            actorId: req.user?.id,
            action: "driver:document:delete",
            entityType: "driver_document",
            entityId: String(documentId),
            before: document,
        });
        await (0, logs_1.logDriverAction)({
            driverId: id,
            actorId: req.user?.id,
            action: "document_delete",
            payload: { documentId },
        });
        return res.json({ message: "Document deleted successfully" });
    }
    catch (error) {
        return res.status(500).json({ message: "Failed to delete document", error: String(error) });
    }
});
// Verify driver document
exports.driversRouter.post("/drivers/:id/documents/:documentId/verify", (0, permissions_1.requirePermissions)(["driver:verify"]), async (req, res) => {
    const id = Number(req.params.id);
    const documentId = Number(req.params.documentId);
    const { status } = req.body;
    try {
        const document = await client_2.default.driverDocument.findFirst({
            where: { id: documentId, driverId: id },
        });
        if (!document) {
            return res.status(404).json({ message: "Document not found" });
        }
        const updated = await client_2.default.driverDocument.update({
            where: { id: documentId },
            data: {
                status: status || "verified",
                verifiedBy: req.user?.id,
                verifiedAt: new Date(),
            },
        });
        await (0, audit_1.logAudit)({
            actorId: req.user?.id,
            action: "driver:document:verify",
            entityType: "driver_document",
            entityId: String(documentId),
            before: document,
            after: updated,
        });
        await (0, logs_1.logDriverAction)({
            driverId: id,
            actorId: req.user?.id,
            action: "document_verify",
            payload: { documentId, status: updated.status },
        });
        return res.json(updated);
    }
    catch (error) {
        return res.status(500).json({ message: "Failed to verify document", error: String(error) });
    }
});
