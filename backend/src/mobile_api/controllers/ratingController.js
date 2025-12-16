const ratingService = require('../services/ratingService');
const getRatings = async (req, res) => {
try {
const userId = req.user?.id;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized',
message: 'User authentication required'
});
}
const { booking_id, booking_type, user_id, all } = req.query;

const ratings = await ratingService.getRatings({
userId,
booking_id,
booking_type,
user_id,
all
});
res.status(200).json({
success: true,
count: ratings.length,
data: ratings
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to fetch ratings',
message: error.message
});
}
};
const getRatingByBooking = async (req, res) => {
try {
const userId = req.user?.id;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized',
message: 'User authentication required'
});
}
const { booking_id } = req.params;
const { booking_type, user_id } = req.query;
if (!booking_type) {
return res.status(400).json({
success: false,
error: 'Missing booking_type query parameter'
});
}
const filterUserId = user_id || userId;

const rating = await ratingService.getRatingByBooking(filterUserId, booking_id, booking_type);
if (!rating) {
return res.status(404).json({
success: false,
error: 'Rating not found'
});
}
res.status(200).json({
success: true,
data: rating
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to fetch rating',
message: error.message
});
}
};
const getRatingById = async (req, res) => {
try {
const userId = req.user?.id;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized',
message: 'User authentication required'
});
}
const { id } = req.params;
const { user_id } = req.query;

const rating = await ratingService.getRatingById(id, user_id || null);
if (!rating) {
return res.status(404).json({
success: false,
error: 'Rating not found'
});
}
if (!user_id && rating.user_id !== userId) {
return res.status(403).json({
success: false,
error: 'Forbidden',
message: 'You do not have permission to view this rating'
});
}
res.status(200).json({
success: true,
data: rating
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to fetch rating',
message: error.message
});
}
};
const createRating = async (req, res) => {
try {
const userId = req.user?.id;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized',
message: 'User authentication required'
});
}
const {
booking_id,
booking_type,
rating,
title,
review,
driver_rating,
vehicle_rating,
service_rating
} = req.body;
if (!booking_id || !booking_type || !rating) {
return res.status(400).json({
success: false,
error: 'Missing required fields',
message: 'booking_id, booking_type, and rating are required'
});
}
if (rating < 1 || rating > 5) {
return res.status(400).json({
success: false,
error: 'Invalid rating',
message: 'Rating must be between 1 and 5'
});
}

const ratingRecord = await ratingService.createOrUpdateRating({
userId,
booking_id,
booking_type,
rating,
title,
review,
driver_rating,
vehicle_rating,
service_rating
});
res.status(201).json({
success: true,
message: 'Rating submitted successfully',
data: ratingRecord
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to create rating',
message: error.message
});
}
};
const updateRating = async (req, res) => {
try {
const userId = req.user?.id;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized',
message: 'User authentication required'
});
}
const { id } = req.params;
const { rating, title, review, driver_rating, vehicle_rating, service_rating, is_featured } = req.body;

const existing = await ratingService.getRatingById(id);
if (!existing) {
return res.status(404).json({
success: false,
error: 'Rating not found'
});
}
const isOwner = existing.user_id === userId;
const isAdminUpdate = is_featured !== undefined;
if (!isOwner && !isAdminUpdate) {
return res.status(403).json({
success: false,
error: 'Forbidden',
message: 'You can only update your own ratings'
});
}
if (rating !== undefined && (rating < 1 || rating > 5)) {
return res.status(400).json({
success: false,
error: 'Invalid rating',
message: 'Rating must be between 1 and 5'
});
}

try {
const updatedRating = await ratingService.updateRating(id, userId, {
rating,
title,
review,
driver_rating,
vehicle_rating,
service_rating,
is_featured
}, isAdminUpdate);
if (!updatedRating) {
return res.status(404).json({
success: false,
error: 'Rating not found or update failed'
});
}
res.status(200).json({
success: true,
message: 'Rating updated successfully',
data: updatedRating
});
} catch (error) {
if (error.message.includes('No fields to update')) {
return res.status(400).json({
success: false,
error: 'No fields to update',
message: error.message
});
}
throw error;
}
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to update rating',
message: error.message
});
}
};
const getRatingDescription = async (req, res) => {
try {
const { rating } = req.params;
const ratingValue = parseInt(rating, 10);
if (isNaN(ratingValue) || ratingValue < 1 || ratingValue > 5) {
return res.status(400).json({
success: false,
error: 'Invalid rating',
message: 'Rating must be between 1 and 5'
});
}
const ratingDescriptions = {
1: {
rating: 1,
description: 'Terrible Experience',
emoji: '😡',
question: 'What went wrong?',
options: [
'Demanded extra cash',
'Different vehicle',
'Unprofessional behaviour',
'Unsafe ride'
]
},
2: {
rating: 2,
description: 'Poor Experience',
emoji: '😟',
question: 'What went wrong?',
options: [
'Demanded extra cash',
'Different vehicle',
'Unprofessional behaviour',
'Unsafe ride'
]
},
3: {
rating: 3,
description: 'OK, but had an issue',
emoji: '😟',
question: 'What was the issue?',
options: [
'Demanded extra cash',
'Different vehicle',
'Unprofessional behaviour',
'Unsafe ride'
]
},
4: {
rating: 4,
description: 'Great, where can we improve?',
emoji: '🙂',
question: 'What can we improve?',
options: [
'Demanded extra cash',
'Unsafe ride',
'Unprofessional behaviour',
'Different vehicle'
]
},
5: {
rating: 5,
description: 'Great, what did you like the most?',
emoji: '😊',
question: 'What did you like?',
options: [
'Comfortable ride',
'Professional Captain',
'Affordable'
]
}
};
const description = ratingDescriptions[ratingValue];
res.status(200).json({
success: true,
data: description
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to fetch rating description',
message: error.message
});
}
};
module.exports = {
getRatings,
getRatingById,
getRatingByBooking,
createRating,
updateRating,
getRatingDescription
};
