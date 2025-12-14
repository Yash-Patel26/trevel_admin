-- AlterTable
ALTER TABLE "from_airport_transfer_bookings" ALTER COLUMN "estimated_time_min" SET DEFAULT '00:00:00'::time;

-- AlterTable
ALTER TABLE "mini_trip_bookings" ALTER COLUMN "estimated_time_min" SET DEFAULT '00:00:00'::time;

-- AlterTable
ALTER TABLE "to_airport_transfer_bookings" ALTER COLUMN "estimated_time_min" SET DEFAULT '00:00:00'::time;

-- CreateTable
CREATE TABLE "pricing_configs" (
    "id" TEXT NOT NULL,
    "service_type" TEXT NOT NULL,
    "config" JSONB NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "updated_by" INTEGER,

    CONSTRAINT "pricing_configs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "pricing_configs_service_type_key" ON "pricing_configs"("service_type");
