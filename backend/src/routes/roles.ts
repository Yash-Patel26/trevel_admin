import { Router } from "express";
import prisma from "../prisma/client";
import { authMiddleware } from "../middleware/auth";
import { requirePermissions } from "../middleware/permissions";

export const rolesRouter = Router();

rolesRouter.use("/roles", authMiddleware);

// Get all roles
rolesRouter.get(
    "/roles",
    requirePermissions(["user:view"]),
    async (_req, res) => {
        try {
            const roles = await prisma.role.findMany({
                orderBy: { name: "asc" },
            });
            return res.json(roles);
        } catch (error) {
            return res.status(500).json({ message: "Failed to fetch roles" });
        }
    }
);
