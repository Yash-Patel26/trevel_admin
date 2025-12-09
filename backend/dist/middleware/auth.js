"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.authMiddleware = authMiddleware;
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const client_1 = __importDefault(require("../prisma/client"));
const env_1 = require("../config/env");
async function authMiddleware(req, res, next) {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith("Bearer ")) {
        return res.status(401).json({ message: "Missing token" });
    }
    const token = authHeader.replace("Bearer ", "");
    try {
        const decoded = jsonwebtoken_1.default.verify(token, env_1.env.jwtSecret);
        const user = await client_1.default.user.findUnique({
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
    }
    catch (_err) {
        return res.status(401).json({ message: "Invalid token" });
    }
}
