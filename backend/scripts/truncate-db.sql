-- SQL Script to Truncate All Tables in RDS
-- WARNING: This will DELETE ALL DATA!

-- Disable foreign key checks temporarily
SET session_replication_role = 'replica';

-- Truncate all tables (add your table names here)
TRUNCATE TABLE "User" CASCADE;
TRUNCATE TABLE "Driver" CASCADE;
TRUNCATE TABLE "Vehicle" CASCADE;
TRUNCATE TABLE "Booking" CASCADE;
TRUNCATE TABLE "AuditLog" CASCADE;
TRUNCATE TABLE "Notification" CASCADE;

-- Add any other tables you have...

-- Re-enable foreign key checks
SET session_replication_role = 'origin';

-- Reset sequences (auto-increment counters)
-- Replace table_name_id_seq with your actual sequence names
ALTER SEQUENCE "User_id_seq" RESTART WITH 1;
ALTER SEQUENCE "Driver_id_seq" RESTART WITH 1;
ALTER SEQUENCE "Vehicle_id_seq" RESTART WITH 1;
ALTER SEQUENCE "Booking_id_seq" RESTART WITH 1;
ALTER SEQUENCE "AuditLog_id_seq" RESTART WITH 1;
ALTER SEQUENCE "Notification_id_seq" RESTART WITH 1;

-- Add any other sequences...

SELECT 'Database truncated successfully!' as status;
