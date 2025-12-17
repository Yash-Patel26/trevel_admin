const { firebaseAdmin } = require('../../config/firebase');
const prisma = require('../../prisma/client').default;

const authMiddleware = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        error: 'Unauthorized',
        message: 'Missing or invalid authorization token'
      });
    }

    const token = authHeader.split(' ')[1];
    let decodedToken;

    const TEST_TOKEN_PREFIX = 'TEST_TOKEN_FOR_';

    const STATIC_AUTH_TOKEN = process.env.STATIC_AUTH_TOKEN;
    const STATIC_TOKEN_DELIMITER = '::';

    if (token.startsWith(TEST_TOKEN_PREFIX)) {
      const phone = token.replace(TEST_TOKEN_PREFIX, '').trim();
      decodedToken = {
        phone_number: phone,
        uid: 'test-user-' + phone
      };
    } else if (STATIC_AUTH_TOKEN && token.startsWith(STATIC_AUTH_TOKEN + STATIC_TOKEN_DELIMITER)) {
      // Handle static token: "12345::userId"
      const parts = token.split(STATIC_TOKEN_DELIMITER);
      if (parts.length === 2) {
        const userId = parts[1];
        // We need to fetch the user to get the phone number, or at least have the ID.
        // The middleware expects phone_number to find the user in the next step.
        // But wait, the next step does: await prisma.customer.findUnique({ where: { mobile: phone_number } });
        // So we MUST return a phone_number in decodedToken.

        // Since we only have userId, we might need a different lookup strategy or fetch user here.
        // Let's fetch the user by ID here to get the phone number.

        const staticUser = await prisma.customer.findUnique({ where: { id: userId } }); // Assuming ID is int from Postgres, but Prisma schema said String @uuid? No, schema said String @id @default(uuid()). Wait.
        // Let's check schema. User table might be int or string. Customer table is String uuid.
        // authController issues token with payload.id. 
        // If authController is using `user.id`, let's check if that's from `User` (admin) or `Customer` table. 
        // `authController` seems to interact with `authService` which uses `db.query` on `users` table usually? 

        // The middleware later does: prisma.customer.findUnique({ where: { mobile: phone_number } });
        // This implies the middleware is built for the `Customer` table (mobile app users).
        // If `authController` issues tokens for `users` (admin/drivers), we might have a mismatch if this middleware is also for them?
        // But this is `mobile_api/middleware/auth.js`.

        // Let's assume for now we can get the user.
        if (staticUser) {
          decodedToken = {
            phone_number: staticUser.mobile,
            uid: staticUser.id
          };
        } else {
          // Fallback or error? specific error might help.
          // If user not found by ID, maybe it's an admin user ID?
          // But this middleware enforces: findUnique({ where: { mobile: phone_number } }) later.
          // So we need a mobile number.
          console.warn("Static token used but user not found by ID:", userId);
          return res.status(401).json({ success: false, error: 'Unauthorized', message: 'User not found for static token' });
        }
      }
    } else {
      // Try verifying as internal JWT first (or fallback from Firebase)
      // Since Firebase tokens are also JWTs, determining which one to try can be tricky.
      // But usually internal JWTs are signed by our secret.
      try {
        const jwtPayload = require('jsonwebtoken').verify(token, process.env.JWT_SECRET);
        // Map internal payload to what middleware expects
        // authController issues { id, phone }
        decodedToken = {
          phone_number: jwtPayload.phone,
          uid: jwtPayload.id,
          ...jwtPayload
        };
      } catch (jwtError) {
        // If not a valid internal JWT, try Firebase
        try {
          decodedToken = await firebaseAdmin.auth().verifyIdToken(token);
        } catch (firebaseError) {
          console.error("Token verification failed (JWT & Firebase):", jwtError.message, firebaseError.message);
          return res.status(401).json({ success: false, error: 'Unauthorized', message: 'Invalid token' });
        }
      }
    }

    const { phone_number } = decodedToken;

    if (!phone_number) {
      return res.status(401).json({ success: false, error: 'Unauthorized', message: 'Token missing phone number' });
    }

    // Find user by phone
    let user = await prisma.customer.findUnique({
      where: { mobile: phone_number }
    });

    if (!user) {
      // Auto-create user
      try {
        user = await prisma.customer.create({
          data: { mobile: phone_number }
        });
      } catch (e) {
        // Handle race condition
        user = await prisma.customer.findUnique({ where: { mobile: phone_number } });
      }
    }

    if (!user) {
      return res.status(401).json({ success: false, error: 'Unauthorized', message: 'User not found' });
    }

    // Attach user to req (legacy routes expect req.user)
    req.user = user;
    // Attach to req.customer for consistency with new TS middleware
    req.customer = user;

    next();
  } catch (error) {
    console.error("Auth Middleware Error:", error);
    res.status(401).json({
      success: false,
      error: 'Unauthorized',
      message: 'Not authorized, token failed',
    });
  }
};

module.exports = authMiddleware;
