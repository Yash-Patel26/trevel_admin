/*
  Warnings:

  - The primary key for the `Customer` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - The primary key for the `Driver` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `createdAt` on the `Driver` table. All the data in the column will be lost.
  - You are about to drop the column `mobile` on the `Driver` table. All the data in the column will be lost.
  - You are about to drop the column `name` on the `Driver` table. All the data in the column will be lost.
  - You are about to drop the column `updatedAt` on the `Driver` table. All the data in the column will be lost.
  - The primary key for the `Vehicle` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `createdAt` on the `Vehicle` table. All the data in the column will be lost.
  - You are about to drop the column `numberPlate` on the `Vehicle` table. All the data in the column will be lost.
  - You are about to drop the column `updatedAt` on the `Vehicle` table. All the data in the column will be lost.
  - A unique constraint covering the columns `[mobile]` on the table `Customer` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[email]` on the table `Customer` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[phone]` on the table `Driver` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[license_number]` on the table `Driver` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[number_plate]` on the table `Vehicle` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `full_name` to the `Driver` table without a default value. This is not possible if the table is not empty.
  - Added the required column `phone` to the `Driver` table without a default value. This is not possible if the table is not empty.
  - Added the required column `updated_at` to the `Driver` table without a default value. This is not possible if the table is not empty.
  - Added the required column `number_plate` to the `Vehicle` table without a default value. This is not possible if the table is not empty.
  - Added the required column `updated_at` to the `Vehicle` table without a default value. This is not possible if the table is not empty.

*/
-- DropForeignKey
ALTER TABLE "Booking" DROP CONSTRAINT "Booking_customerId_fkey";

-- DropForeignKey
ALTER TABLE "DriverBackgroundCheck" DROP CONSTRAINT "DriverBackgroundCheck_driverId_fkey";

-- DropForeignKey
ALTER TABLE "DriverDocument" DROP CONSTRAINT "DriverDocument_driverId_fkey";

-- DropForeignKey
ALTER TABLE "DriverLog" DROP CONSTRAINT "DriverLog_driverId_fkey";

-- DropForeignKey
ALTER TABLE "DriverTrainingAssignment" DROP CONSTRAINT "DriverTrainingAssignment_driverId_fkey";

-- DropForeignKey
ALTER TABLE "RideSummary" DROP CONSTRAINT "RideSummary_driverId_fkey";

-- DropForeignKey
ALTER TABLE "RideSummary" DROP CONSTRAINT "RideSummary_vehicleId_fkey";

-- DropForeignKey
ALTER TABLE "VehicleAssignment" DROP CONSTRAINT "VehicleAssignment_driverId_fkey";

-- DropForeignKey
ALTER TABLE "VehicleAssignment" DROP CONSTRAINT "VehicleAssignment_vehicleId_fkey";

-- DropForeignKey
ALTER TABLE "VehicleLog" DROP CONSTRAINT "VehicleLog_vehicleId_fkey";

-- DropForeignKey
ALTER TABLE "VehicleReview" DROP CONSTRAINT "VehicleReview_vehicleId_fkey";

-- DropIndex
DROP INDEX "Vehicle_numberPlate_key";

-- AlterTable
ALTER TABLE "Booking" ALTER COLUMN "customerId" SET DATA TYPE TEXT,
ALTER COLUMN "vehicleId" SET DATA TYPE TEXT,
ALTER COLUMN "driverId" SET DATA TYPE TEXT;

-- AlterTable
ALTER TABLE "Customer" DROP CONSTRAINT "Customer_pkey",
ADD COLUMN     "profile_image_url" TEXT,
ADD COLUMN     "status" TEXT NOT NULL DEFAULT 'active',
ALTER COLUMN "id" DROP DEFAULT,
ALTER COLUMN "id" SET DATA TYPE TEXT,
ALTER COLUMN "name" DROP NOT NULL,
ADD CONSTRAINT "Customer_pkey" PRIMARY KEY ("id");
DROP SEQUENCE "Customer_id_seq";

-- AlterTable
ALTER TABLE "Driver" DROP CONSTRAINT "Driver_pkey",
DROP COLUMN "createdAt",
DROP COLUMN "mobile",
DROP COLUMN "name",
DROP COLUMN "updatedAt",
ADD COLUMN     "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "full_name" TEXT NOT NULL,
ADD COLUMN     "license_number" TEXT,
ADD COLUMN     "phone" TEXT NOT NULL,
ADD COLUMN     "profile_image_url" TEXT,
ADD COLUMN     "rating" DOUBLE PRECISION DEFAULT 0,
ADD COLUMN     "total_trips" INTEGER DEFAULT 0,
ADD COLUMN     "updated_at" TIMESTAMP(3) NOT NULL,
ALTER COLUMN "id" DROP DEFAULT,
ALTER COLUMN "id" SET DATA TYPE TEXT,
ADD CONSTRAINT "Driver_pkey" PRIMARY KEY ("id");
DROP SEQUENCE "Driver_id_seq";

-- AlterTable
ALTER TABLE "DriverBackgroundCheck" ALTER COLUMN "driverId" SET DATA TYPE TEXT;

-- AlterTable
ALTER TABLE "DriverDocument" ALTER COLUMN "driverId" SET DATA TYPE TEXT;

-- AlterTable
ALTER TABLE "DriverLog" ALTER COLUMN "driverId" SET DATA TYPE TEXT;

-- AlterTable
ALTER TABLE "DriverTrainingAssignment" ALTER COLUMN "driverId" SET DATA TYPE TEXT;

-- AlterTable
ALTER TABLE "Notification" ALTER COLUMN "targetId" SET DATA TYPE TEXT;

-- AlterTable
ALTER TABLE "RideSummary" ALTER COLUMN "vehicleId" SET DATA TYPE TEXT,
ALTER COLUMN "driverId" SET DATA TYPE TEXT;

-- AlterTable
ALTER TABLE "Vehicle" DROP CONSTRAINT "Vehicle_pkey",
DROP COLUMN "createdAt",
DROP COLUMN "numberPlate",
DROP COLUMN "updatedAt",
ADD COLUMN     "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "number_plate" TEXT NOT NULL,
ADD COLUMN     "updated_at" TIMESTAMP(3) NOT NULL,
ALTER COLUMN "id" DROP DEFAULT,
ALTER COLUMN "id" SET DATA TYPE TEXT,
ADD CONSTRAINT "Vehicle_pkey" PRIMARY KEY ("id");
DROP SEQUENCE "Vehicle_id_seq";

-- AlterTable
ALTER TABLE "VehicleAssignment" ALTER COLUMN "vehicleId" SET DATA TYPE TEXT,
ALTER COLUMN "driverId" SET DATA TYPE TEXT;

-- AlterTable
ALTER TABLE "VehicleLog" ALTER COLUMN "vehicleId" SET DATA TYPE TEXT;

-- AlterTable
ALTER TABLE "VehicleReview" ALTER COLUMN "vehicleId" SET DATA TYPE TEXT;

-- CreateTable
CREATE TABLE "mini_trip_bookings" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "pickup_location" TEXT NOT NULL,
    "pickup_city" TEXT,
    "pickup_state" TEXT,
    "dropoff_location" TEXT NOT NULL,
    "dropoff_city" TEXT,
    "dropoff_state" TEXT,
    "pickup_date" DATE NOT NULL,
    "pickup_time" TIME NOT NULL,
    "vehicle_id" TEXT,
    "vehicle_selected" TEXT NOT NULL,
    "vehicle_image_url" TEXT,
    "passenger_name" TEXT NOT NULL,
    "passenger_email" TEXT,
    "passenger_phone" TEXT NOT NULL,
    "estimated_distance_km" DOUBLE PRECISION NOT NULL,
    "estimated_time_min" TIME NOT NULL DEFAULT '00:00:00'::time,
    "base_price" DOUBLE PRECISION NOT NULL,
    "gst_amount" DOUBLE PRECISION DEFAULT 0,
    "final_price" DOUBLE PRECISION NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "status" TEXT NOT NULL DEFAULT 'pending',
    "notes" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "mini_trip_bookings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "hourly_rental_bookings" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "pickup_location" TEXT NOT NULL,
    "pickup_city" TEXT,
    "pickup_state" TEXT,
    "pickup_date" DATE NOT NULL,
    "pickup_time" TIME NOT NULL,
    "vehicle_id" TEXT,
    "vehicle_selected" TEXT NOT NULL,
    "vehicle_image_url" TEXT,
    "passenger_name" TEXT NOT NULL,
    "passenger_email" TEXT,
    "passenger_phone" TEXT NOT NULL,
    "rental_hours" DOUBLE PRECISION NOT NULL,
    "covered_distance_km" DOUBLE PRECISION NOT NULL,
    "base_price" DOUBLE PRECISION NOT NULL,
    "gst_amount" DOUBLE PRECISION DEFAULT 0,
    "final_price" DOUBLE PRECISION NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "notes" TEXT,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "hourly_rental_bookings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "to_airport_transfer_bookings" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "pickup_location" TEXT NOT NULL,
    "pickup_date" DATE NOT NULL,
    "pickup_time" TIME NOT NULL,
    "destination_airport" TEXT NOT NULL,
    "vehicle_id" TEXT,
    "vehicle_selected" TEXT,
    "vehicle_image_url" TEXT,
    "passenger_name" TEXT NOT NULL,
    "passenger_email" TEXT,
    "passenger_phone" TEXT,
    "estimated_distance_km" DOUBLE PRECISION,
    "estimated_time_min" TIME NOT NULL DEFAULT '00:00:00'::time,
    "base_price" DOUBLE PRECISION NOT NULL,
    "gst_amount" DOUBLE PRECISION DEFAULT 0,
    "final_price" DOUBLE PRECISION NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "status" TEXT NOT NULL DEFAULT 'pending',
    "notes" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "to_airport_transfer_bookings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "from_airport_transfer_bookings" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "pickup_location" TEXT NOT NULL,
    "pickup_date" DATE NOT NULL,
    "pickup_time" TIME NOT NULL,
    "destination_airport" TEXT NOT NULL,
    "vehicle_id" TEXT,
    "vehicle_selected" TEXT,
    "vehicle_image_url" TEXT,
    "passenger_name" TEXT NOT NULL,
    "passenger_email" TEXT,
    "passenger_phone" TEXT,
    "estimated_distance_km" DOUBLE PRECISION,
    "estimated_time_min" TIME NOT NULL DEFAULT '00:00:00'::time,
    "base_price" DOUBLE PRECISION NOT NULL,
    "gst_amount" DOUBLE PRECISION DEFAULT 0,
    "final_price" DOUBLE PRECISION NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "status" TEXT NOT NULL DEFAULT 'pending',
    "notes" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "from_airport_transfer_bookings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "airports" (
    "id" TEXT NOT NULL,
    "airport_code" TEXT NOT NULL,
    "airport_name" TEXT NOT NULL,
    "city" TEXT NOT NULL,
    "country" TEXT NOT NULL DEFAULT 'India',
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "terminal" TEXT,
    "full_location" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "airports_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "saved_locations" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "address" TEXT NOT NULL,
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,
    "city" TEXT,
    "state" TEXT,
    "country" TEXT DEFAULT 'India',
    "postal_code" TEXT,
    "is_default" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "saved_locations_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "mini_trip_bookings_user_id_idx" ON "mini_trip_bookings"("user_id");

-- CreateIndex
CREATE INDEX "mini_trip_bookings_status_idx" ON "mini_trip_bookings"("status");

-- CreateIndex
CREATE INDEX "mini_trip_bookings_pickup_date_idx" ON "mini_trip_bookings"("pickup_date");

-- CreateIndex
CREATE INDEX "hourly_rental_bookings_user_id_idx" ON "hourly_rental_bookings"("user_id");

-- CreateIndex
CREATE INDEX "hourly_rental_bookings_status_idx" ON "hourly_rental_bookings"("status");

-- CreateIndex
CREATE INDEX "hourly_rental_bookings_pickup_date_idx" ON "hourly_rental_bookings"("pickup_date");

-- CreateIndex
CREATE INDEX "to_airport_transfer_bookings_user_id_idx" ON "to_airport_transfer_bookings"("user_id");

-- CreateIndex
CREATE INDEX "to_airport_transfer_bookings_status_idx" ON "to_airport_transfer_bookings"("status");

-- CreateIndex
CREATE INDEX "to_airport_transfer_bookings_pickup_date_idx" ON "to_airport_transfer_bookings"("pickup_date");

-- CreateIndex
CREATE INDEX "from_airport_transfer_bookings_user_id_idx" ON "from_airport_transfer_bookings"("user_id");

-- CreateIndex
CREATE INDEX "from_airport_transfer_bookings_status_idx" ON "from_airport_transfer_bookings"("status");

-- CreateIndex
CREATE INDEX "from_airport_transfer_bookings_pickup_date_idx" ON "from_airport_transfer_bookings"("pickup_date");

-- CreateIndex
CREATE UNIQUE INDEX "airports_airport_code_key" ON "airports"("airport_code");

-- CreateIndex
CREATE UNIQUE INDEX "Customer_mobile_key" ON "Customer"("mobile");

-- CreateIndex
CREATE UNIQUE INDEX "Customer_email_key" ON "Customer"("email");

-- CreateIndex
CREATE UNIQUE INDEX "Driver_phone_key" ON "Driver"("phone");

-- CreateIndex
CREATE UNIQUE INDEX "Driver_license_number_key" ON "Driver"("license_number");

-- CreateIndex
CREATE UNIQUE INDEX "Vehicle_number_plate_key" ON "Vehicle"("number_plate");

-- AddForeignKey
ALTER TABLE "VehicleReview" ADD CONSTRAINT "VehicleReview_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES "Vehicle"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "VehicleLog" ADD CONSTRAINT "VehicleLog_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES "Vehicle"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "VehicleAssignment" ADD CONSTRAINT "VehicleAssignment_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES "Vehicle"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "VehicleAssignment" ADD CONSTRAINT "VehicleAssignment_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "Driver"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DriverDocument" ADD CONSTRAINT "DriverDocument_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "Driver"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DriverBackgroundCheck" ADD CONSTRAINT "DriverBackgroundCheck_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "Driver"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DriverTrainingAssignment" ADD CONSTRAINT "DriverTrainingAssignment_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "Driver"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DriverLog" ADD CONSTRAINT "DriverLog_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "Driver"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RideSummary" ADD CONSTRAINT "RideSummary_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES "Vehicle"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RideSummary" ADD CONSTRAINT "RideSummary_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "Driver"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Booking" ADD CONSTRAINT "Booking_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "Customer"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Booking" ADD CONSTRAINT "Booking_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES "Vehicle"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Booking" ADD CONSTRAINT "Booking_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "Driver"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mini_trip_bookings" ADD CONSTRAINT "mini_trip_bookings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "Customer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mini_trip_bookings" ADD CONSTRAINT "mini_trip_bookings_vehicle_id_fkey" FOREIGN KEY ("vehicle_id") REFERENCES "Vehicle"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "hourly_rental_bookings" ADD CONSTRAINT "hourly_rental_bookings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "Customer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "hourly_rental_bookings" ADD CONSTRAINT "hourly_rental_bookings_vehicle_id_fkey" FOREIGN KEY ("vehicle_id") REFERENCES "Vehicle"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "to_airport_transfer_bookings" ADD CONSTRAINT "to_airport_transfer_bookings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "Customer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "to_airport_transfer_bookings" ADD CONSTRAINT "to_airport_transfer_bookings_vehicle_id_fkey" FOREIGN KEY ("vehicle_id") REFERENCES "Vehicle"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "from_airport_transfer_bookings" ADD CONSTRAINT "from_airport_transfer_bookings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "Customer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "from_airport_transfer_bookings" ADD CONSTRAINT "from_airport_transfer_bookings_vehicle_id_fkey" FOREIGN KEY ("vehicle_id") REFERENCES "Vehicle"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "saved_locations" ADD CONSTRAINT "saved_locations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "Customer"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
