import { NextFunction, Request, Response } from "express";
import jwt from "jsonwebtoken";
import prisma from "../prisma/client";
import { env } from "../config/env";

export interface AuthUser {
  id: number;
  role: string;
  permissions: string[];
}

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      user?: AuthUser;
    }
  }
}

export async function authMiddleware(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith("Bearer ")) {
    return res.status(401).json({ message: "Missing token" });
  }
  const token = authHeader.replace("Bearer ", "");
  try {
    const decoded = jwt.verify(token, env.jwtSecret) as { id: number };
    const user = await prisma.user.findUnique({
      where: { id: decoded.id },
      include: {
        role: {
          include: {
            permissions: { include: { permission: true } },
          },
        },
      },
    });
    if (!user || !user.isActive) {
      return res.status(401).json({ message: "User not found" });
    }
    const permissions = user.role.permissions.map((rp) => rp.permission.name);
    req.user = { id: user.id, role: user.role.name, permissions };
    return next();
  } catch (_err) {
    return res.status(401).json({ message: "Invalid token" });
  }
}

