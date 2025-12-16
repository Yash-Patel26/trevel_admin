
import { Router } from 'express';
import express from 'express';
import path from 'path';

// Import Legacy Controllers/Middleware using require
const { getMake } = require('./controllers/vehicleController');
const authMiddleware = require('./middleware/auth');

// Import Legacy Routes
const userRoutes = require('./routes/userRoutes');
const authRoutes = require('./routes/authRoutes');
const airportRoutes = require('./routes/airportRoutes');
const profileRoutes = require('./routes/profileRoutes');
const hourlyRentalRoutes = require('./routes/hourlyRentalRoutes');
const miniTripRoutes = require('./routes/miniTripRoutes');
const myBookingsRoutes = require('./routes/myBookingsRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const locationRoutes = require('./routes/locationRoutes');
const complaintRoutes = require('./routes/complaintRoutes');
const ratingRoutes = require('./routes/ratingRoutes');
const pricingRoutes = require('./routes/pricingRoutes');
const bookingAdjustmentRoutes = require('./routes/bookingAdjustmentRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const faqRoutes = require('./routes/faqRoutes');
const emergencyRoutes = require('./routes/emergencyRoutes');
const serviceZonesRoutes = require('./routes/serviceZonesRoutes');
const promoCodeRoutes = require('./routes/promoCodeRoutes');
const otpRoutes = require('./routes/otpRoutes');
const hubRoutes = require('./routes/hubRoutes');
const referralRoutes = require('./routes/referralRoutes');

export const mobileApiRouter = Router();

// Middleware needed for legacy routes (if any specific ones like body parser limits were different)
// Admin server.ts already has json() and urlencoded().

// Helper to mount to both /api and /api/v1
const mountRoute = (pathStr: string, router: any) => {
    mobileApiRouter.use(`/api/v1${pathStr}`, router);
    mobileApiRouter.use(`/api${pathStr}`, router);
};

// Mount Routes
mountRoute('/users', userRoutes);
mountRoute('/user', profileRoutes);
mountRoute('/profile', profileRoutes);
mountRoute('/auth', authRoutes);
mountRoute('/airports', airportRoutes);
mountRoute('/hourly-rentals', hourlyRentalRoutes);
mountRoute('/mini-trips', miniTripRoutes);
mountRoute('/my-bookings', myBookingsRoutes);
mountRoute('/payments', paymentRoutes);
mountRoute('/locations', locationRoutes);
mountRoute('/addresses', locationRoutes);
mountRoute('/complaints', complaintRoutes);
mountRoute('/ratings', ratingRoutes);
mountRoute('/pricing', pricingRoutes);
mountRoute('/bookings', bookingAdjustmentRoutes);
mountRoute('/notifications', notificationRoutes);
mountRoute('/support/faq', faqRoutes);
mountRoute('/support/contact', complaintRoutes);
mountRoute('/support/report-issue', complaintRoutes);
mountRoute('/emergency', emergencyRoutes);
mountRoute('/referral', referralRoutes);
mountRoute('/service-zones', serviceZonesRoutes);
mountRoute('/promo-codes', promoCodeRoutes);
mountRoute('/otp', otpRoutes);
mountRoute('/hubs', hubRoutes);

// Specific Routes
mobileApiRouter.get('/api/v1/make', authMiddleware, getMake);
mobileApiRouter.get('/api/make', authMiddleware, getMake);

// Static files (uploads)
// backend/server.js: app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
// We should replicate this. Note that __dirname in the built TS file might be different.
// We'll assume the 'uploads' folder was copied or is shared.
// Admin server already serves /uploads. We might need to ensure the legacy uploads are reachable.
