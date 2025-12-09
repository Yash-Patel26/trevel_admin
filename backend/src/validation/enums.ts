export const VehicleStatus = {
  PENDING: "pending",
  APPROVED: "approved",
  REJECTED: "rejected",
  ACTIVE: "active",
  INACTIVE: "inactive",
} as const;

export const DriverStatus = {
  PENDING: "pending",
  VERIFIED: "verified",
  APPROVED: "approved",
  REJECTED: "rejected",
  ACTIVE: "active",
  INACTIVE: "inactive",
} as const;

export const TicketStatus = {
  OPEN: "open",
  IN_PROGRESS: "in_progress",
  RESOLVED: "resolved",
  CLOSED: "closed",
} as const;

export const TicketPriority = {
  LOW: "low",
  MEDIUM: "medium",
  HIGH: "high",
  URGENT: "urgent",
} as const;

export const BookingStatus = {
  UPCOMING: "upcoming",
  TODAY: "today",
  ASSIGNED: "assigned",
  IN_PROGRESS: "in_progress",
  COMPLETED: "completed",
  CANCELED: "canceled",
} as const;

export const RideStatus = {
  IN_PROGRESS: "in_progress",
  COMPLETED: "completed",
  CANCELED: "canceled",
} as const;

export const BackgroundCheckStatus = {
  PENDING: "pending",
  CLEAR: "clear",
  FLAGGED: "flagged",
} as const;

export const TrainingStatus = {
  ASSIGNED: "assigned",
  IN_PROGRESS: "in_progress",
  COMPLETED: "completed",
} as const;

export const DocumentStatus = {
  UPLOADED: "uploaded",
  VERIFIED: "verified",
  REJECTED: "rejected",
} as const;

export const NotificationStatus = {
  QUEUED: "queued",
  SENT: "sent",
  FAILED: "failed",
} as const;

export const NotificationChannel = {
  EMAIL: "email",
  SMS: "sms",
  IN_APP: "in-app",
} as const;

