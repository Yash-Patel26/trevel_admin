"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.logAudit = logAudit;
const client_1 = __importDefault(require("../prisma/client"));
async function logAudit(params) {
    await client_1.default.auditLog.create({
        data: {
            actorId: params.actorId,
            action: params.action,
            entityType: params.entityType,
            entityId: params.entityId,
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            before: params.before,
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            after: params.after,
        },
    });
}
