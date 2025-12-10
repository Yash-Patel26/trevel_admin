-- Add missing latitude/longitude columns to bookings
ALTER TABLE "Booking"
  ADD COLUMN IF NOT EXISTS "pickupLatitude" DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS "pickupLongitude" DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS "destinationLatitude" DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS "destinationLongitude" DOUBLE PRECISION;

