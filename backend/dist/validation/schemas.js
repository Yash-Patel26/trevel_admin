"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.bookingListSchema = exports.bookingDetailParamSchema = exports.bookingsListSchema = exports.bookingOtpValidateSchema = exports.bookingAssignSchema = exports.ticketUpdateSchema = exports.ticketCreateSchema = exports.assignVehicleSchema = exports.driverApproveSchema = exports.driverTrainingSchema = exports.driverBackgroundSchema = exports.driverCreateSchema = exports.vehicleReviewSchema = exports.vehicleCreateSchema = exports.loginSchema = void 0;
const zod_1 = require("zod");
const enums_1 = require("./enums");
exports.loginSchema = zod_1.z.object({
    email: zod_1.z.string().email(),
    password: zod_1.z.string().min(6),
});
exports.vehicleCreateSchema = zod_1.z.object({
    numberPlate: zod_1.z.string().min(1),
    make: zod_1.z.string().optional(),
    model: zod_1.z.string().optional(),
    insurancePolicyNumber: zod_1.z.string().optional(),
    insuranceExpiry: zod_1.z.coerce.date().optional(),
    liveLocationKey: zod_1.z.string().optional(),
    dashcamKey: zod_1.z.string().optional(),
});
exports.vehicleReviewSchema = zod_1.z.object({
    status: zod_1.z.enum([
        enums_1.VehicleStatus.PENDING,
        enums_1.VehicleStatus.APPROVED,
        enums_1.VehicleStatus.REJECTED,
        enums_1.VehicleStatus.ACTIVE,
        enums_1.VehicleStatus.INACTIVE,
    ]),
    comments: zod_1.z.string().optional(),
});
exports.driverCreateSchema = zod_1.z.object({
    name: zod_1.z.string().min(1),
    mobile: zod_1.z.string().min(3),
    email: zod_1.z.string().email(),
    onboardingData: zod_1.z.record(zod_1.z.string(), zod_1.z.any()).optional(),
    contactPreferences: zod_1.z.record(zod_1.z.string(), zod_1.z.any()).optional(),
});
exports.driverBackgroundSchema = zod_1.z.object({
    status: zod_1.z.enum([
        enums_1.BackgroundCheckStatus.PENDING,
        enums_1.BackgroundCheckStatus.CLEAR,
        enums_1.BackgroundCheckStatus.FLAGGED,
    ]),
    notes: zod_1.z.string().optional(),
});
exports.driverTrainingSchema = zod_1.z.object({
    module: zod_1.z.string(),
    status: zod_1.z.enum([
        enums_1.TrainingStatus.ASSIGNED,
        enums_1.TrainingStatus.IN_PROGRESS,
        enums_1.TrainingStatus.COMPLETED,
    ]),
});
exports.driverApproveSchema = zod_1.z.object({
    decision: zod_1.z.enum([
        enums_1.DriverStatus.APPROVED,
        enums_1.DriverStatus.REJECTED,
        enums_1.DriverStatus.ACTIVE,
        enums_1.DriverStatus.INACTIVE,
    ]),
});
exports.assignVehicleSchema = zod_1.z.object({
    vehicleId: zod_1.z.number(),
});
exports.ticketCreateSchema = zod_1.z.object({
    vehicleNumber: zod_1.z.string().optional(),
    driverName: zod_1.z.string().optional(),
    driverMobile: zod_1.z.string().optional(),
    category: zod_1.z.string().optional(),
    priority: zod_1.z.enum([
        enums_1.TicketPriority.LOW,
        enums_1.TicketPriority.MEDIUM,
        enums_1.TicketPriority.HIGH,
        enums_1.TicketPriority.URGENT,
    ]).optional(),
    description: zod_1.z.string().optional(),
});
exports.ticketUpdateSchema = zod_1.z.object({
    status: zod_1.z.enum([
        enums_1.TicketStatus.OPEN,
        enums_1.TicketStatus.IN_PROGRESS,
        enums_1.TicketStatus.RESOLVED,
        enums_1.TicketStatus.CLOSED,
    ]).optional(),
    assignedTo: zod_1.z.number().optional(),
    resolutionNotes: zod_1.z.string().optional(),
});
exports.bookingAssignSchema = zod_1.z.object({
    vehicleId: zod_1.z.number(),
    driverId: zod_1.z.number().optional(),
});
exports.bookingOtpValidateSchema = zod_1.z.object({
    otpCode: zod_1.z.string().length(4),
});
exports.bookingsListSchema = zod_1.z.object({
    status: zod_1.z.string().optional(),
    startDate: zod_1.z.coerce.date().optional(),
    endDate: zod_1.z.coerce.date().optional(),
    search: zod_1.z.string().optional(),
    page: zod_1.z.coerce.number().optional(),
    pageSize: zod_1.z.coerce.number().optional(),
});
exports.bookingDetailParamSchema = zod_1.z.object({
    id: zod_1.z.coerce.number(),
});
exports.bookingListSchema = zod_1.z.object({
    status: zod_1.z.string().optional(),
    from: zod_1.z.string().datetime().optional(),
    to: zod_1.z.string().datetime().optional(),
    search: zod_1.z.string().optional(),
});
