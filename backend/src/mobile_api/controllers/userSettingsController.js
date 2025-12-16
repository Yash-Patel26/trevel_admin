const userSettingsService = require('../services/userSettingsService');
const getUserSettings = async (req, res) => {
try {
const userId = req.user?.id;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized'
});
}
const settings = await userSettingsService.getUserSettings(userId);
res.status(200).json({
success: true,
data: settings
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to fetch user settings',
message: error.message
});
}
};
const updateUserSettings = async (req, res) => {
try {
const userId = req.user?.id;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized'
});
}
const {
notifications_enabled,
notifications_push_enabled,
notifications_email_enabled,
notifications_sms_enabled,
theme,
language,
currency,
preferred_payment_method,
auto_apply_promos,
share_ride_data,
emergency_contacts_enabled,
location_sharing_enabled
} = req.body;
try {
const result = await userSettingsService.updateUserSettings(userId, {
notifications_enabled,
notifications_push_enabled,
notifications_email_enabled,
notifications_sms_enabled,
theme,
language,
currency,
preferred_payment_method,
auto_apply_promos,
share_ride_data,
emergency_contacts_enabled,
location_sharing_enabled
});
res.status(200).json({
success: true,
data: result
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
error: 'Failed to update user settings',
message: error.message
});
}
};
module.exports = {
getUserSettings,
updateUserSettings
};
