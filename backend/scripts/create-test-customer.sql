-- Create a test customer for mobile app testing
-- Run this with: psql -U your_user -d your_database -f scripts/create-test-customer.sql

-- Check if customer already exists
DO $$
DECLARE
    customer_exists BOOLEAN;
    customer_id TEXT;
BEGIN
    -- Check if mobile number already exists
    SELECT EXISTS(SELECT 1 FROM "Customer" WHERE mobile = '+919876543210') INTO customer_exists;
    
    IF customer_exists THEN
        -- Get existing customer ID
        SELECT id INTO customer_id FROM "Customer" WHERE mobile = '+919876543210';
        RAISE NOTICE 'Test customer already exists with ID: %', customer_id;
    ELSE
        -- Insert new test customer
        INSERT INTO "Customer" (id, name, mobile, email, status, "firebase_uid", "profile_image_url")
        VALUES (
            gen_random_uuid(),
            'Test User',
            '+919876543210',
            'testuser@trevel.com',
            'active',
            NULL,
            NULL
        )
        RETURNING id INTO customer_id;
        
        RAISE NOTICE 'Test customer created successfully with ID: %', customer_id;
    END IF;
    
    -- Display customer info
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Test Customer Details:';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Mobile: +919876543210';
    RAISE NOTICE 'Email: testuser@trevel.com';
    RAISE NOTICE 'Name: Test User';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Use this mobile number in the app to test';
    RAISE NOTICE 'OTP will be sent to Redis (check backend logs)';
    RAISE NOTICE '========================================';
END $$;

-- Verify the customer was created
SELECT id, name, mobile, email, status 
FROM "Customer" 
WHERE mobile = '+919876543210';
