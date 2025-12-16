const fcmTokenService = require('../services/fcmTokenService');
const saveFCMToken = async (req, res) => {
try {
const userId = req.user?.id;
const { fcm_token } = req.body;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized',
message: 'User authentication required'
});
}
if (!fcm_token || typeof fcm_token !== 'string') {
return res.status(400).json({
success: false,
error: 'Invalid FCM token',
message: 'fcm_token is required and must be a string'
});
}
const result = await fcmTokenService.saveFcmToken(userId, fcm_token);
if (!result) {
return res.status(404).json({
success: false,
error: 'User not found'
});
}
return res.status(200).json({
success: true,
message: 'FCM token saved successfully',
data: {
user_id: result.id,
fcm_token_saved: true
}
});
} catch (error) {
return res.status(500).json({
success: false,
error: 'Failed to save FCM token',
message: error.message
});
}
};
const removeFCMToken = async (req, res) => {
try {
const userId = req.user?.id;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized'
});
}
await fcmTokenService.removeFcmToken(userId);
return res.status(200).json({
success: true,
message: 'FCM token removed successfully'
});
} catch (error) {
return res.status(500).json({
success: false,
error: 'Failed to remove FCM token',
message: error.message
});
}
};
module.exports = {
saveFCMToken,
removeFCMToken
};
