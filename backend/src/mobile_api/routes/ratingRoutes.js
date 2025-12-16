const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth');
const {
getRatings,
getRatingById,
getRatingByBooking,
createRating,
updateRating,
getRatingDescription
} = require('../controllers/ratingController');
router.get('/', authMiddleware, getRatings);
router.get('/description/:rating', getRatingDescription);
router.get('/booking/:booking_id', authMiddleware, getRatingByBooking);
router.get('/:id', authMiddleware, getRatingById);
router.post('/', authMiddleware, createRating);
router.put('/:id', authMiddleware, updateRating);
module.exports = router;
