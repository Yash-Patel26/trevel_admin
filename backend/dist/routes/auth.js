"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.authRouter = void 0;
const express_1 = require("express");
const bcrypt_1 = __importDefault(require("bcrypt"));
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const crypto_1 = __importDefault(require("crypto"));
const client_1 = __importDefault(require("../prisma/client"));
const env_1 = require("../config/env");
const auth_1 = require("../middleware/auth");
const validate_1 = require("../validation/validate");
const schemas_1 = require("../validation/schemas");
const zod_1 = require("zod");
exports.authRouter = (0, express_1.Router)();
const refreshTokenSchema = zod_1.z.object({
    refreshToken: zod_1.z.string(),
});
function generateRefreshToken() {
    return crypto_1.default.randomBytes(32).toString("hex");
}
exports.authRouter.post("/auth/login", (0, validate_1.validateBody)(schemas_1.loginSchema), async (req, res) => {
    const { email, password } = req.body;
    if (!email || !password) {
        return res.status(400).json({ message: "Email and password required" });
    }
    const user = await client_1.default.user.findUnique({
        where: { email },
        include: {
            role: { include: { permissions: { include: { permission: true } } } },
        },
    });
    if (!user || !user.isActive) {
        return res.status(401).json({ message: "Invalid credentials" });
    }
    const ok = await bcrypt_1.default.compare(password, user.passwordHash);
    if (!ok) {
        return res.status(401).json({ message: "Invalid credentials" });
    }
    const permissions = user.role.permissions.map((rp) => rp.permission.name);
    const accessToken = jsonwebtoken_1.default.sign({ id: user.id, role: user.role.name, permissions }, env_1.env.jwtSecret, {
        expiresIn: "60m",
    });
    // Generate refresh token
    const refreshToken = generateRefreshToken();
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7); // 7 days
    await client_1.default.refreshToken.create({
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
exports.authRouter.post("/auth/refresh", (0, validate_1.validateBody)(refreshTokenSchema), async (req, res) => {
    const { refreshToken } = req.body;
    const tokenRecord = await client_1.default.refreshToken.findUnique({
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
        await client_1.default.refreshToken.update({
            where: { id: tokenRecord.id },
            data: { revokedAt: new Date() },
        });
        return res.status(401).json({ message: "User is inactive" });
    }
    const permissions = tokenRecord.user.role.permissions.map((rp) => rp.permission.name);
    const accessToken = jsonwebtoken_1.default.sign({ id: tokenRecord.user.id, role: tokenRecord.user.role.name, permissions }, env_1.env.jwtSecret, { expiresIn: "60m" });
    return res.json({
        accessToken,
        tokenType: "bearer",
    });
});
exports.authRouter.post("/auth/logout", auth_1.authMiddleware, async (req, res) => {
    const authHeader = req.headers.authorization;
    if (authHeader?.startsWith("Bearer ")) {
        // Note: Access tokens are stateless, but we can revoke refresh tokens
        // For a full logout, you'd need to track access tokens or just rely on refresh token revocation
    }
    return res.json({ message: "Logged out" });
});
exports.authRouter.post("/auth/logout-all", auth_1.authMiddleware, async (req, res) => {
    await client_1.default.refreshToken.updateMany({
        where: { userId: req.user?.id, revokedAt: null },
        data: { revokedAt: new Date() },
    });
    return res.json({ message: "Logged out from all devices" });
});
exports.authRouter.get("/auth/me", auth_1.authMiddleware, async (req, res) => {
    return res.json({ user: req.user });
});
