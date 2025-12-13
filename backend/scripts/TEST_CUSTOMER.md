# Test Customer for Mobile App

## Credentials
- **Mobile**: `+919876543210`
- **Email**: `testuser@trevel.com`
- **Name**: Test User

## How to Create the Test Customer

### Option 1: Using Prisma Studio (Recommended)
```bash
cd backend
npx prisma studio
```
Then manually create a customer with the above details.

### Option 2: Using SQL Script
```bash
# Connect to your PostgreSQL database
psql -U your_username -d your_database_name -f scripts/create-test-customer.sql
```

### Option 3: Using the API (if backend is running)
```bash
# Start the backend
cd backend
npm run dev

# In another terminal, create customer via API
curl -X POST http://localhost:3000/api/customers \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -d '{
    "name": "Test User",
    "mobile": "+919876543210",
    "email": "testuser@trevel.com"
  }'
```

## Testing the Mobile App

1. **Launch the Flutter app**
2. **Enter mobile number**: `+919876543210`
3. **Request OTP**: The backend will generate a 4-digit OTP
4. **Check backend logs** for the OTP (it's stored in Redis)
5. **Enter the OTP** to complete login

## OTP Verification
- OTPs are stored in Redis with key: `otp:+919876543210`
- OTPs expire after 5 minutes
- Check backend console logs to see the generated OTP

## Notes
- This is a test account for development only
- The customer has `active` status
- No bookings are associated initially
- You can create test bookings through the mobile app
