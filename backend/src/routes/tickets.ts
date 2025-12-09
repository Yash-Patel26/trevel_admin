import { Router } from "express";
import prisma from "../prisma/client";
import { authMiddleware } from "../middleware/auth";
import { requirePermissions } from "../middleware/permissions";
import { logAudit } from "../utils/audit";
import { queueNotification } from "../services/notifications";
import { validateBody } from "../validation/validate";
import { ticketCreateSchema, ticketUpdateSchema } from "../validation/schemas";
import { getPagination } from "../utils/pagination";

export const ticketsRouter = Router();

ticketsRouter.use(authMiddleware);

ticketsRouter.post(
  "/tickets",
  requirePermissions(["ticket:create"]),
  validateBody(ticketCreateSchema),
  async (req, res) => {
    const { vehicleNumber, driverName, driverMobile, category, priority, description } = req.body;
    const ticket = await prisma.ticket.create({
      data: { vehicleNumber, driverName, driverMobile, category, priority, description, status: "open" },
    });
    await logAudit({
      actorId: req.user?.id,
      action: "ticket:create",
      entityType: "ticket",
      entityId: String(ticket.id),
      after: ticket,
    });
    await queueNotification({
      actorId: req.user?.id,
      type: "ticket.create",
      payload: { ticketId: ticket.id, status: ticket.status },
    });
    return res.json(ticket);
  }
);

ticketsRouter.get(
  "/tickets",
  requirePermissions(["ticket:view"]),
  async (req, res) => {
    const { skip, take, page, pageSize } = getPagination(req.query);
    const { status, category, assignedTo } = req.query;
    const where = {
      status: status ? String(status) : undefined,
      category: category ? String(category) : undefined,
      assignedTo: assignedTo ? Number(assignedTo) : undefined,
    };
    const [tickets, total] = await Promise.all([
      prisma.ticket.findMany({ where, skip, take, orderBy: { createdAt: "desc" } }),
      prisma.ticket.count({ where }),
    ]);
    return res.json({ data: tickets, page, pageSize, total });
  }
);

ticketsRouter.patch(
  "/tickets/:id",
  requirePermissions(["ticket:update"]),
  validateBody(ticketUpdateSchema),
  async (req, res) => {
    const id = Number(req.params.id);
    const { status, assignedTo, resolutionNotes } = req.body;
    const ticket = await prisma.ticket.findUnique({ where: { id } });
    if (!ticket) return res.status(404).json({ message: "Not found" });

    const updated = await prisma.ticket.update({
      where: { id },
      data: {
        status: status ?? ticket.status,
        assignedTo: assignedTo ?? ticket.assignedTo,
      },
    });
    await prisma.ticketUpdate.create({
      data: { ticketId: id, actorId: req.user?.id, status, notes: resolutionNotes },
    });
    await logAudit({
      actorId: req.user?.id,
      action: "ticket:update",
      entityType: "ticket",
      entityId: String(id),
      after: updated,
    });
    await queueNotification({
      actorId: req.user?.id,
      type: "ticket.update",
      payload: { ticketId: id, status, assignedTo },
    });
    return res.json(updated);
  }
);

