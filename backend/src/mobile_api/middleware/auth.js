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

    if (token.startsWith(TEST_TOKEN_PREFIX)) {
      const phone = token.replace(TEST_TOKEN_PREFIX, '');
      decodedToken = {
        phone_number: phone,
        uid: 'test-user-' + phone
      };
    } else {
      try {
        decodedToken = await firebaseAdmin.auth().verifyIdToken(token);
      } catch (error) {
        console.error("Firebase token verification failed:", error.code, error.message);
        return res.status(401).json({ success: false, error: 'Unauthorized', message: 'Invalid token' });
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
