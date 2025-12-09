import { z } from "zod";
import {
  VehicleStatus,
  DriverStatus,
  TicketStatus,
  TicketPriority,
  BackgroundCheckStatus,
  TrainingStatus,
} from "./enums";

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
});

export const vehicleCreateSchema = z.object({
  numberPlate: z.string().min(1),
  make: z.string().optional(),
  model: z.string().optional(),
  insurancePolicyNumber: z.string().optional(),
  insuranceExpiry: z.coerce.date().optional(),
  liveLocationKey: z.string().optional(),
  dashcamKey: z.string().optional(),
});

export const vehicleReviewSchema = z.object({
  status: z.enum([
    VehicleStatus.PENDING,
    VehicleStatus.APPROVED,
    VehicleStatus.REJECTED,
    VehicleStatus.ACTIVE,
    VehicleStatus.INACTIVE,
  ]),
  comments: z.string().optional(),
});

export const driverCreateSchema = z.object({
  name: z.string().min(1),
  mobile: z.string().min(3),
  email: z.string().email(),
  onboardingData: z.record(z.string(), z.any()).optional(),
  contactPreferences: z.record(z.string(), z.any()).optional(),
});

export const driverBackgroundSchema = z.object({
  status: z.enum([
    BackgroundCheckStatus.PENDING,
    BackgroundCheckStatus.CLEAR,
    BackgroundCheckStatus.FLAGGED,
  ]),
  notes: z.string().optional(),
});

export const driverTrainingSchema = z.object({
  module: z.string(),
  status: z.enum([
    TrainingStatus.ASSIGNED,
    TrainingStatus.IN_PROGRESS,
    TrainingStatus.COMPLETED,
  ]),
});

export const driverApproveSchema = z.object({
  decision: z.enum([
    DriverStatus.APPROVED,
    DriverStatus.REJECTED,
    DriverStatus.ACTIVE,
    DriverStatus.INACTIVE,
  ]),
});

export const assignVehicleSchema = z.object({
  vehicleId: z.number(),
});

export const ticketCreateSchema = z.object({
  vehicleNumber: z.string().optional(),
  driverName: z.string().optional(),
  driverMobile: z.string().optional(),
  category: z.string().optional(),
  priority: z.enum([
    TicketPriority.LOW,
    TicketPriority.MEDIUM,
    TicketPriority.HIGH,
    TicketPriority.URGENT,
  ]).optional(),
  description: z.string().optional(),
});

export const ticketUpdateSchema = z.object({
  status: z.enum([
    TicketStatus.OPEN,
    TicketStatus.IN_PROGRESS,
    TicketStatus.RESOLVED,
    TicketStatus.CLOSED,
  ]).optional(),
  assignedTo: z.number().optional(),
  resolutionNotes: z.string().optional(),
});

export const bookingAssignSchema = z.object({
  vehicleId: z.number(),
  driverId: z.number().optional(),
});

export const bookingOtpValidateSchema = z.object({
  otpCode: z.string().length(4),
});

export const bookingsListSchema = z.object({
  status: z.string().optional(),
  startDate: z.coerce.date().optional(),
  endDate: z.coerce.date().optional(),
  search: z.string().optional(),
  page: z.coerce.number().optional(),
  pageSize: z.coerce.number().optional(),
});

export const bookingDetailParamSchema = z.object({
  id: z.coerce.number(),
});

export const bookingListSchema = z.object({
  status: z.string().optional(),
  from: z.string().datetime().optional(),
  to: z.string().datetime().optional(),
  search: z.string().optional(),
});

