const express = require('express');
const router = express.Router();
const { getNearbyHubs, getAllHubs } = require('../controllers/hubController');

// Get nearby hubs based on location and radius
// Query params: latitude, longitude, radius_km (optional), active_only (optional)
router.get('/', getNearbyHubs);

// Get all hubs (for admin/management - can be protected with auth if needed)
// Query params: active_only (optional)
router.get('/all', getAllHubs);

module.exports = router;

