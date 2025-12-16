import { Router } from "express";
import { authMiddleware } from "../middleware/auth";
import { requirePermissions } from "../middleware/permissions";
import prisma from "../prisma/client";
import { getPagination } from "../utils/pagination";

export const auditRouter = Router();

auditRouter.use("/audit-logs", authMiddleware);

auditRouter.get(
  "/audit-logs",
  requirePermissions(["audit:view"]),
  async (req, res) => {
    const { skip, take, page, pageSize } = getPagination(req.query, { pageSize: 50 });
    const { entityType, actorId } = req.query;
    const where = {
      entityType: entityType ? String(entityType) : undefined,
      actorId: actorId ? Number(actorId) : undefined,
    };
    const [logs, total] = await Promise.all([
      prisma.auditLog.findMany({
        where,
        orderBy: { createdAt: "desc" },
        skip,
        take,
      }),
      prisma.auditLog.count({ where }),
    ]);
    return res.json({ data: logs, page, pageSize, total });
  }
);

