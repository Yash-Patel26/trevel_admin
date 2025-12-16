import { Router } from "express";
import { Prisma } from "@prisma/client";
import { authMiddleware } from "../middleware/auth";
import { requirePermissions } from "../middleware/permissions";
import prisma from "../prisma/client";
import { validateBody } from "../validation/validate";
import { z } from "zod";
import redisClient from "../config/redis";
import { logAudit } from "../utils/audit";

export const revenueRouter = Router();

revenueRouter.use("/revenue", authMiddleware);

// Get all pricing configurations
revenueRouter.get(
    "/revenue/pricing",
    requirePermissions(["dashboard:view"]),
    async (_req, res) => {
        try {
            const configs = await prisma.pricingConfig.findMany();
            return res.json(configs);
        } catch (error) {
            console.error("Error fetching pricing configs:", error);
            return res.status(500).json({ message: "Failed to fetch pricing configurations" });
        }
    }
);

// Update a specific pricing configuration
const updatePricingSchema = z.object({
    config: z.record(z.string(), z.any()) // Flexible JSON validation
});

revenueRouter.put(
    "/revenue/pricing/:serviceType",
    requirePermissions(["dashboard:view"]), // Should ideally be stricter like 'revenue:manage'
    validateBody(updatePricingSchema),
    async (req, res) => {
        try {
            const { serviceType } = req.params;
            const { config } = req.body;

            const existing = await prisma.pricingConfig.findUnique({
                where: { serviceType }
            });

            if (!existing) {
                return res.status(404).json({ message: "Service type not found" });
            }

            const updated = await prisma.pricingConfig.update({
                where: { serviceType },
                data: {
                    config: config as Prisma.InputJsonValue,
                    updatedBy: req.user?.id
                }
            });

            // Invalidate Cache
            try {
                await redisClient.del(`pricing:${serviceType}`);
                await redisClient.del('all_pricing_configs'); // if we cache listy
            } catch (err) {
                console.warn("Redis delete error:", err);
            }

            await logAudit({
                actorId: req.user?.id,
                action: "pricing:update",
                entityType: "pricing_config",
                entityId: serviceType,
                before: existing.config,
                after: updated.config
            });

            return res.json(updated);
        } catch (error) {
            console.error("Error updating pricing config:", error);
            return res.status(500).json({ message: "Failed to update pricing configuration" });
        }
    }
);
