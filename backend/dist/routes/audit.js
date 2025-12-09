"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.auditRouter = void 0;
const express_1 = require("express");
const auth_1 = require("../middleware/auth");
const permissions_1 = require("../middleware/permissions");
const client_1 = __importDefault(require("../prisma/client"));
const pagination_1 = require("../utils/pagination");
exports.auditRouter = (0, express_1.Router)();
exports.auditRouter.use(auth_1.authMiddleware);
exports.auditRouter.get("/audit-logs", (0, permissions_1.requirePermissions)(["audit:view"]), async (req, res) => {
    const { skip, take, page, pageSize } = (0, pagination_1.getPagination)(req.query, { pageSize: 50 });
    const { entityType, actorId } = req.query;
    const where = {
        entityType: entityType ? String(entityType) : undefined,
        actorId: actorId ? Number(actorId) : undefined,
    };
    const [logs, total] = await Promise.all([
        client_1.default.auditLog.findMany({
            where,
            orderBy: { createdAt: "desc" },
            skip,
            take,
        }),
        client_1.default.auditLog.count({ where }),
    ]);
    return res.json({ data: logs, page, pageSize, total });
});
