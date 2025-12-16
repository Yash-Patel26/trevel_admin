const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth');
const {
getPickupZones,
getDropZones,
checkLocationInZone
} = require('../controllers/serviceZonesController');
router.get('/pickups', getPickupZones);
router.get('/drops', getDropZones);
router.post('/check', authMiddleware, checkLocationInZone);
module.exports = router;
