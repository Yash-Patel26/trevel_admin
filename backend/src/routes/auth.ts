import { Router } from "express";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import crypto from "crypto";
import prisma from "../prisma/client";
import { env } from "../config/env";
import { authMiddleware } from "../middleware/auth";
import { validateBody } from "../validation/validate";
import { loginSchema } from "../validation/schemas";
import { z } from "zod";

export const authRouter = Router();

const refreshTokenSchema = z.object({
  refreshToken: z.string(),
});

function generateRefreshToken(): string {
  return crypto.randomBytes(32).toString("hex");
}

authRouter.post("/auth/login", validateBody(loginSchema), async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ message: "Email and password required" });
  }
  const user = await prisma.user.findUnique({
    where: { email },
    include: {
      role: { include: { permissions: { include: { permission: true } } } },
    },
  });
  if (!user || !user.isActive) {
    return res.status(401).json({ message: "Invalid credentials" });
  }
  const ok = await bcrypt.compare(password, user.passwordHash);
  if (!ok) {
    return res.status(401).json({ message: "Invalid credentials" });
  }
  const permissions = user.role.permissions.map((rp) => rp.permission.name);
  const accessToken = jwt.sign({ id: user.id, role: user.role.name, permissions }, env.jwtSecret, {
    expiresIn: "60m",
  });
  
  // Generate refresh token
  const refreshToken = generateRefreshToken();
  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + 7); // 7 days

  await prisma.refreshToken.create({
    data: {
      token: refreshToken,
      userId: user.id,
      expiresAt,
    },
  });

  return res.json({
    accessToken,
    refreshToken,
    tokenType: "bearer",
    user: { id: user.id, email: user.email, fullName: user.fullName, role: user.role.name, permissions },
  });
});

authRouter.post("/auth/refresh", validateBody(refreshTokenSchema), async (req, res) => {
  const { refreshToken } = req.body;
  const tokenRecord = await prisma.refreshToken.findUnique({
    where: { token: refreshToken },
    include: {
      user: {
        include: {
          role: { include: { permissions: { include: { permission: true } } } },
        },
      },
    },
  });

  if (!tokenRecord || tokenRecord.revokedAt || tokenRecord.expiresAt < new Date()) {
    return res.status(401).json({ message: "Invalid or expired refresh token" });
  }

  if (!tokenRecord.user.isActive) {
    await prisma.refreshToken.update({
      where: { id: tokenRecord.id },
      data: { revokedAt: new Date() },
    });
    return res.status(401).json({ message: "User is inactive" });
  }

  const permissions = tokenRecord.user.role.permissions.map((rp) => rp.permission.name);
  const accessToken = jwt.sign(
    { id: tokenRecord.user.id, role: tokenRecord.user.role.name, permissions },
    env.jwtSecret,
    { expiresIn: "60m" }
  );

  return res.json({
    accessToken,
    tokenType: "bearer",
  });
});

authRouter.post("/auth/logout", authMiddleware, async (req, res) => {
  const authHeader = req.headers.authorization;
  if (authHeader?.startsWith("Bearer ")) {
    // Note: Access tokens are stateless, but we can revoke refresh tokens
    // For a full logout, you'd need to track access tokens or just rely on refresh token revocation
  }
  return res.json({ message: "Logged out" });
});

authRouter.post("/auth/logout-all", authMiddleware, async (req, res) => {
  await prisma.refreshToken.updateMany({
    where: { userId: req.user?.id, revokedAt: null },
    data: { revokedAt: new Date() },
  });
  return res.json({ message: "Logged out from all devices" });
});

authRouter.get("/auth/me", authMiddleware, async (req, res) => {
  return res.json({ user: req.user });
});

