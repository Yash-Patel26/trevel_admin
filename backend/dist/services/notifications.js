"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.queueNotification = queueNotification;
const client_1 = __importDefault(require("../prisma/client"));
async function queueNotification(params) {
    await client_1.default.notification.create({
        data: {
            actorId: params.actorId,
            targetId: params.targetId ? String(params.targetId) : undefined,
            type: params.type,
            channel: params.channel ?? "in-app",
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            payload: params.payload,
            status: "queued",
        },
    });
}
