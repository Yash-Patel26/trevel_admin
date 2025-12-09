"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.logVehicleAction = logVehicleAction;
exports.logDriverAction = logDriverAction;
const client_1 = __importDefault(require("../prisma/client"));
async function logVehicleAction(params) {
    await client_1.default.vehicleLog.create({
        data: {
            vehicleId: params.vehicleId,
            actorId: params.actorId,
            action: params.action,
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            payload: params.payload,
        },
    });
}
async function logDriverAction(params) {
    await client_1.default.driverLog.create({
        data: {
            driverId: params.driverId,
            actorId: params.actorId,
            action: params.action,
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            payload: params.payload,
        },
    });
}
