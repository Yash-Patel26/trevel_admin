import { Router } from "express";
import { z } from "zod";
import crypto from "crypto";
import jwt from "jsonwebtoken";
import prisma from "../../prisma/client";
import { validateBody } from "../../validation/validate";
import { smsService } from "../../services/sms";
import redisClient from "../../config/redis";
import { env } from "../../config/env";

export const authRouter = Router();

// OTP Utils
const OTP_TTL = 300; // 5 minutes

async function setOtp(phone: string, otp: string) {
    if (redisClient && redisClient.isOpen) {
        await redisClient.setEx(`otp:${phone}`, OTP_TTL, otp);
    } else {
        // Fallback or error? Using memory map for now if redis fails?
        // Ideally we want redis.
        console.warn("Redis client not open, OTP might fail or use map");
        // For production, ensure redis.
    }
}

async function getOtp(phone: string): Promise<string | null> {
    if (redisClient && redisClient.isOpen) {
        return redisClient.get(`otp:${phone}`);
    }
    return null;
}

async function deleteOtp(phone: string) {
    if (redisClient && redisClient.isOpen) {
        await redisClient.del(`otp:${phone}`);
    }
}

const sendOtpSchema = z.object({
    phone: z.string().min(10),
    name: z.string().optional()
});

authRouter.post("/send-otp", validateBody(sendOtpSchema), async (req, res) => {
    try {
        const { phone, name } = req.body;
        // Generate 4 digit OTP
        const otp = crypto.randomInt(1000, 10000).toString();

        await setOtp(phone, otp);
        await smsService.sendOtpMessage({ phone, name, otp });

        res.json({ success: true, message: "OTP sent successfully" });
    } catch (error) {
        res.status(500).json({ success: false, message: "Failed to send OTP", error: String(error) });
    }
});

const verifyOtpSchema = z.object({
    phone: z.string().min(10),
    otp: z.string().length(4)
});

authRouter.post("/verify-otp", validateBody(verifyOtpSchema), async (req, res) => {
    try {
        const { phone, otp } = req.body;

        const storedOtp = await getOtp(phone);
        if (!storedOtp || storedOtp !== otp) {
            return res.status(401).json({ success: false, message: "Invalid or expired OTP" });
        }

        await deleteOtp(phone);

        // Find or Create Customer
        // Normalize phone?
        let customer = await prisma.customer.findFirst({ where: { mobile: phone } });

        if (!customer) {
            customer = await prisma.customer.create({
                data: {
                    mobile: phone,
                    name: "User", // Default name
                    status: "active"
                }
            });
        }

        const token = jwt.sign({ id: customer.id }, env.jwtSecret, { expiresIn: '30d' });

        res.json({
            success: true,
            message: "Verified",
            data: {
                token,
                user: customer
            }
        });

    } catch (error) {
        res.status(500).json({ success: false, message: "Failed to verify OTP", error: String(error) });
    }
});

authRouter.post("/resend-otp", validateBody(sendOtpSchema), async (req, res) => {
    // Same as send-otp essentially
    try {
        const { phone, name } = req.body;
        const otp = crypto.randomInt(1000, 10000).toString();
        await setOtp(phone, otp);
        await smsService.sendOtpMessage({ phone, name, otp });
        res.json({ success: true, message: "OTP resent successfully" });
    } catch (error) {
        res.status(500).json({ success: false, message: "Failed to resend OTP", error: String(error) });
    }
});
