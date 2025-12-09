"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.NotificationChannel = exports.NotificationStatus = exports.DocumentStatus = exports.TrainingStatus = exports.BackgroundCheckStatus = exports.RideStatus = exports.BookingStatus = exports.TicketPriority = exports.TicketStatus = exports.DriverStatus = exports.VehicleStatus = void 0;
exports.VehicleStatus = {
    PENDING: "pending",
    APPROVED: "approved",
    REJECTED: "rejected",
    ACTIVE: "active",
    INACTIVE: "inactive",
};
exports.DriverStatus = {
    PENDING: "pending",
    VERIFIED: "verified",
    APPROVED: "approved",
    REJECTED: "rejected",
    ACTIVE: "active",
    INACTIVE: "inactive",
};
exports.TicketStatus = {
    OPEN: "open",
    IN_PROGRESS: "in_progress",
    RESOLVED: "resolved",
    CLOSED: "closed",
};
exports.TicketPriority = {
    LOW: "low",
    MEDIUM: "medium",
    HIGH: "high",
    URGENT: "urgent",
};
exports.BookingStatus = {
    UPCOMING: "upcoming",
    TODAY: "today",
    ASSIGNED: "assigned",
    IN_PROGRESS: "in_progress",
    COMPLETED: "completed",
    CANCELED: "canceled",
};
exports.RideStatus = {
    IN_PROGRESS: "in_progress",
    COMPLETED: "completed",
    CANCELED: "canceled",
};
exports.BackgroundCheckStatus = {
    PENDING: "pending",
    CLEAR: "clear",
    FLAGGED: "flagged",
};
exports.TrainingStatus = {
    ASSIGNED: "assigned",
    IN_PROGRESS: "in_progress",
    COMPLETED: "completed",
};
exports.DocumentStatus = {
    UPLOADED: "uploaded",
    VERIFIED: "verified",
    REJECTED: "rejected",
};
exports.NotificationStatus = {
    QUEUED: "queued",
    SENT: "sent",
    FAILED: "failed",
};
exports.NotificationChannel = {
    EMAIL: "email",
    SMS: "sms",
    IN_APP: "in-app",
};
