const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const authMiddleware = require('../middleware/auth');
const { getProfile, updateProfile, getPromoCodes } = require('../controllers/profileController');
const { getUserSettings, updateUserSettings } = require('../controllers/userSettingsController');
const { getUserStatistics } = require('../controllers/userStatisticsController');
const { saveFCMToken, removeFCMToken } = require('../controllers/fcmTokenController');

// Configure multer for file uploads
const uploadsDir = path.join(__dirname, '../uploads/profile-pictures');
// Create uploads directory if it doesn't exist
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadsDir);
  },
  filename: function (req, file, cb) {
    // Generate unique filename: userId-timestamp.extension
    const userId = req.user?.id || 'unknown';
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    cb(null, `${userId}-${uniqueSuffix}${ext}`);
  }
});

const fileFilter = (req, file, cb) => {
  // Accept only image files
  if (file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    cb(new Error('Only image files are allowed'), false);
  }
};

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB limit
  },
  fileFilter: fileFilter
});
router.get('/profile', authMiddleware, getProfile);
router.put('/profile', authMiddleware, updateProfile);
router.post('/fcm-token', authMiddleware, saveFCMToken);
router.delete('/fcm-token', authMiddleware, removeFCMToken);
// Profile picture upload - supports both file upload and URL
router.post('/profile-picture', authMiddleware, upload.single('image'), async (req, res) => {
try {
const userId = req.user?.id;
if (!userId) {
// Clean up uploaded file if exists
if (req.file) {
  fs.unlinkSync(req.file.path);
}
return res.status(401).json({
success: false,
error: 'Unauthorized'
});
}

const db = require('../config/postgresClient');
let profileImageUrl = null;

// Check if file was uploaded
if (req.file) {
  // File was uploaded - use the saved file path
  // In production, you would upload to cloud storage (S3, Firebase, etc.) and get URL
  // For now, we'll use a relative path or full URL
  const baseUrl = process.env.BASE_URL || 'http://localhost:3000';
  profileImageUrl = `${baseUrl}/uploads/profile-pictures/${req.file.filename}`;
} else if (req.body.profile_image_url) {
  // URL was provided in body (for backward compatibility)
  profileImageUrl = req.body.profile_image_url;
} else {
return res.status(400).json({
success: false,
error: 'Missing image',
message: 'Please provide either an image file or profile_image_url'
});
}

const { rows } = await db.query(
`UPDATE users SET profile_image_url = $1 WHERE id = $2 RETURNING *`,
[profileImageUrl, userId]
);

res.status(200).json({
success: true,
message: 'Profile picture updated successfully',
data: {
profile_image_url: rows[0].profile_image_url,
image_url: rows[0].profile_image_url // Alias for compatibility
}
});
} catch (error) {
// Clean up uploaded file if exists and error occurred
if (req.file && fs.existsSync(req.file.path)) {
  fs.unlinkSync(req.file.path);
}
res.status(500).json({
success: false,
error: 'Failed to upload profile picture',
message: error.message
});
}
});
router.get('/settings', authMiddleware, getUserSettings);
router.put('/settings', authMiddleware, updateUserSettings);
router.get('/statistics', authMiddleware, getUserStatistics);
router.get('/promo-codes', authMiddleware, getPromoCodes);
module.exports = router;
