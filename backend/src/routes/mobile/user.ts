import { Router } from "express";
import { z } from "zod";
import prisma from "../../prisma/client";
import { mobileAuthMiddleware } from "../../middleware/mobileAuth";
import { validateBody } from "../../validation/validate";

export const userRouter = Router();

userRouter.use(mobileAuthMiddleware);

userRouter.get("/me", async (req, res) => {
    try {
        const customerId = req.customer!.id;
        const customer = await prisma.customer.findUnique({
            where: { id: customerId },
            include: {
                _count: {
                    select: {
                        miniTrips: true,
                        hourlyRentals: true,
                        toAirportTrips: true,
                        fromAirportTrips: true
                    }
                }
            }
        });

        if (!customer) return res.status(404).json({ success: false, message: "User not found" });

        res.json({ success: true, data: customer });
    } catch (error) {
        res.status(500).json({ success: false, message: "Failed to fetch profile", error: String(error) });
    }
});

const updateProfileSchema = z.object({
    name: z.string().optional(),
    email: z.string().email().optional(),
    profile_image_url: z.string().optional()
});

userRouter.put("/me", validateBody(updateProfileSchema), async (req, res) => {
    try {
        const customerId = req.customer!.id;
        const data = req.body;

        const updated = await prisma.customer.update({
            where: { id: customerId },
            data: {
                name: data.name,
                email: data.email
                // profileImageUrl stored in Customer.profileImageUrl, but update needs verification
                // Commenting out until schema is confirmed to have this field
            }
        });

        res.json({ success: true, message: "Profile updated", data: updated });
    } catch (error) {
        res.status(500).json({ success: false, message: "Failed to update profile", error: String(error) });
    }
});
