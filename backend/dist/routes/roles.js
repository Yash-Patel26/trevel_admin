"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.rolesRouter = void 0;
const express_1 = require("express");
const client_1 = __importDefault(require("../prisma/client"));
const auth_1 = require("../middleware/auth");
const permissions_1 = require("../middleware/permissions");
exports.rolesRouter = (0, express_1.Router)();
exports.rolesRouter.use(auth_1.authMiddleware);
// Get all roles
exports.rolesRouter.get("/roles", (0, permissions_1.requirePermissions)(["user:view"]), async (_req, res) => {
    try {
        const roles = await client_1.default.role.findMany({
            orderBy: { name: "asc" },
        });
        return res.json(roles);
    }
    catch (error) {
        return res.status(500).json({ message: "Failed to fetch roles" });
    }
});
