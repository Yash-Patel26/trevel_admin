-- AlterTable
ALTER TABLE "from_airport_transfer_bookings" ALTER COLUMN "estimated_time_min" SET DEFAULT '00:00:00'::time;

-- AlterTable
ALTER TABLE "mini_trip_bookings" ALTER COLUMN "estimated_time_min" SET DEFAULT '00:00:00'::time;

-- AlterTable
ALTER TABLE "to_airport_transfer_bookings" ALTER COLUMN "estimated_time_min" SET DEFAULT '00:00:00'::time;

-- CreateTable
CREATE TABLE "makes" (
    "id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "type" TEXT NOT NULL DEFAULT 'sedan',
    "capacity" INTEGER NOT NULL DEFAULT 4,
    "luggage" INTEGER NOT NULL DEFAULT 0,
    "base_price" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "image_url" TEXT,
    "description" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "model" TEXT,
    "number_plate" TEXT,
    "color" TEXT,
    "driver_id" UUID,
    "current_latitude" DECIMAL(10,8),
    "current_longitude" DECIMAL(11,8),
    "last_tracked_at" TIMESTAMP(3),
    "device_imei" TEXT,
    "device_name" TEXT,
    "seats" INTEGER DEFAULT 4,
    "service_types" TEXT[],
    "oem_range_kms" DECIMAL(10,2),
    "price_amount" DECIMAL(10,2),
    "price_unit" TEXT DEFAULT 'per ride',
    "eta_text" TEXT,
    "distance_text" TEXT,
    "seat_label" TEXT,
    "category" TEXT,

    CONSTRAINT "makes_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "makes_is_active_idx" ON "makes"("is_active");

-- CreateIndex
CREATE INDEX "makes_type_idx" ON "makes"("type");

-- CreateIndex
CREATE INDEX "makes_driver_id_idx" ON "makes"("driver_id");

-- CreateIndex
CREATE INDEX "makes_number_plate_idx" ON "makes"("number_plate");

-- CreateIndex
CREATE INDEX "makes_device_imei_idx" ON "makes"("device_imei");
