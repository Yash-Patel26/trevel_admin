"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ticketsRouter = void 0;
const express_1 = require("express");
const client_1 = __importDefault(require("../prisma/client"));
const auth_1 = require("../middleware/auth");
const permissions_1 = require("../middleware/permissions");
const audit_1 = require("../utils/audit");
const notifications_1 = require("../services/notifications");
const validate_1 = require("../validation/validate");
const schemas_1 = require("../validation/schemas");
const pagination_1 = require("../utils/pagination");
exports.ticketsRouter = (0, express_1.Router)();
exports.ticketsRouter.use(auth_1.authMiddleware);
exports.ticketsRouter.post("/tickets", (0, permissions_1.requirePermissions)(["ticket:create"]), (0, validate_1.validateBody)(schemas_1.ticketCreateSchema), async (req, res) => {
    const { vehicleNumber, driverName, driverMobile, category, priority, description } = req.body;
    const ticket = await client_1.default.ticket.create({
        data: { vehicleNumber, driverName, driverMobile, category, priority, description, status: "open" },
    });
    await (0, audit_1.logAudit)({
        actorId: req.user?.id,
        action: "ticket:create",
        entityType: "ticket",
        entityId: String(ticket.id),
        after: ticket,
    });
    await (0, notifications_1.queueNotification)({
        actorId: req.user?.id,
        type: "ticket.create",
        payload: { ticketId: ticket.id, status: ticket.status },
    });
    return res.json(ticket);
});
exports.ticketsRouter.get("/tickets", (0, permissions_1.requirePermissions)(["ticket:view"]), async (req, res) => {
    const { skip, take, page, pageSize } = (0, pagination_1.getPagination)(req.query);
    const { status, category, assignedTo } = req.query;
    const where = {
        status: status ? String(status) : undefined,
        category: category ? String(category) : undefined,
        assignedTo: assignedTo ? Number(assignedTo) : undefined,
    };
    const [tickets, total] = await Promise.all([
        client_1.default.ticket.findMany({ where, skip, take, orderBy: { createdAt: "desc" } }),
        client_1.default.ticket.count({ where }),
    ]);
    return res.json({ data: tickets, page, pageSize, total });
});
exports.ticketsRouter.patch("/tickets/:id", (0, permissions_1.requirePermissions)(["ticket:update"]), (0, validate_1.validateBody)(schemas_1.ticketUpdateSchema), async (req, res) => {
    const id = Number(req.params.id);
    const { status, assignedTo, resolutionNotes } = req.body;
    const ticket = await client_1.default.ticket.findUnique({ where: { id } });
    if (!ticket)
        return res.status(404).json({ message: "Not found" });
    const updated = await client_1.default.ticket.update({
        where: { id },
        data: {
            status: status ?? ticket.status,
            assignedTo: assignedTo ?? ticket.assignedTo,
        },
    });
    await client_1.default.ticketUpdate.create({
        data: { ticketId: id, actorId: req.user?.id, status, notes: resolutionNotes },
    });
    await (0, audit_1.logAudit)({
        actorId: req.user?.id,
        action: "ticket:update",
        entityType: "ticket",
        entityId: String(id),
        after: updated,
    });
    await (0, notifications_1.queueNotification)({
        actorId: req.user?.id,
        type: "ticket.update",
        payload: { ticketId: id, status, assignedTo },
    });
    return res.json(updated);
});
