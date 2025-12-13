import { NextFunction, Request, Response } from "express";
import jwt from "jsonwebtoken";
import prisma from "../prisma/client";
import { env } from "../config/env";

export interface AuthCustomer {
    id: string;
    name: string | null;
    mobile: string;
    email: string | null;
}

declare global {
    // eslint-disable-next-line @typescript-eslint/no-namespace
    namespace Express {
        interface Request {
            customer?: AuthCustomer;
        }
    }
}

export async function mobileAuthMiddleware(req: Request, res: Response, next: NextFunction) {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith("Bearer ")) {
        return res.status(401).json({ message: "Missing token" });
    }

    const token = authHeader.replace("Bearer ", "");

    try {
        // Assuming mobile app uses the same JWT secret.
        // Ideally it should be verified against Firebase if using firebaseUid, 
        // but code implies custom JWT or synced JWT.
        // For now, using env.jwtSecret. 
        // If mobile backend used different auth, I need to know. 
        // Mobile backend analysis showed "authMiddleware" using `jwt.verify(token, process.env.JWT_SECRET)`.
        // So it matches main backend env structure if secrets are same.

        const decoded = jwt.verify(token, env.jwtSecret) as { id: string }; // UUID for customer

        const customer = await prisma.customer.findUnique({
            where: { id: decoded.id },
        });

        if (!customer) {
            return res.status(401).json({ message: "Customer not found" });
        }

        req.customer = {
            id: customer.id,
            name: customer.name,
            mobile: customer.mobile,
            email: customer.email
        };

        return next();
    } catch (err) {
        return res.status(401).json({ message: "Invalid token" });
    }
}
