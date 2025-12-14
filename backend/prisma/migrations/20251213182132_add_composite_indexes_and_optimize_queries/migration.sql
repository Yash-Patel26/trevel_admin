-- AlterTable
ALTER TABLE "from_airport_transfer_bookings" ALTER COLUMN "estimated_time_min" SET DEFAULT '00:00:00'::time;

-- AlterTable
ALTER TABLE "mini_trip_bookings" ALTER COLUMN "estimated_time_min" SET DEFAULT '00:00:00'::time;

-- AlterTable
ALTER TABLE "to_airport_transfer_bookings" ALTER COLUMN "estimated_time_min" SET DEFAULT '00:00:00'::time;

-- CreateIndex
CREATE INDEX "AuditLog_actorId_createdAt_idx" ON "AuditLog"("actorId", "createdAt");

-- CreateIndex
CREATE INDEX "AuditLog_entityType_entityId_idx" ON "AuditLog"("entityType", "entityId");

-- CreateIndex
CREATE INDEX "AuditLog_createdAt_idx" ON "AuditLog"("createdAt");

-- CreateIndex
CREATE INDEX "Booking_customerId_status_idx" ON "Booking"("customerId", "status");

-- CreateIndex
CREATE INDEX "Booking_status_pickupTime_idx" ON "Booking"("status", "pickupTime");

-- CreateIndex
CREATE INDEX "Booking_customerId_pickupTime_idx" ON "Booking"("customerId", "pickupTime");

-- CreateIndex
CREATE INDEX "Driver_status_idx" ON "Driver"("status");

-- CreateIndex
CREATE INDEX "Driver_status_rating_idx" ON "Driver"("status", "rating");

-- CreateIndex
CREATE INDEX "Ticket_status_priority_idx" ON "Ticket"("status", "priority");

-- CreateIndex
CREATE INDEX "Ticket_assignedTo_status_idx" ON "Ticket"("assignedTo", "status");

-- CreateIndex
CREATE INDEX "Ticket_createdAt_idx" ON "Ticket"("createdAt");

-- CreateIndex
CREATE INDEX "Vehicle_status_idx" ON "Vehicle"("status");

-- CreateIndex
CREATE INDEX "Vehicle_status_created_at_idx" ON "Vehicle"("status", "created_at");

-- CreateIndex
CREATE INDEX "mini_trip_bookings_user_id_status_pickup_date_idx" ON "mini_trip_bookings"("user_id", "status", "pickup_date");

-- CreateIndex
CREATE INDEX "mini_trip_bookings_status_pickup_date_idx" ON "mini_trip_bookings"("status", "pickup_date");

-- CreateIndex
CREATE INDEX "mini_trip_bookings_created_at_idx" ON "mini_trip_bookings"("created_at");
