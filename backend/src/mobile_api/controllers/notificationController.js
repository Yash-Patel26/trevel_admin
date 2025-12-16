const db = require('../config/postgresClient');
const notificationService = require('../services/notificationService');
const getNotifications = async (req, res) => {
try {
const userId = req.user?.id;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized',
message: 'User authentication required'
});
}
const { is_read, type } = req.query;
const notifications = await notificationService.getNotifications(db, {
userId,
is_read,
type
});
res.status(200).json({
success: true,
count: notifications.length,
data: notifications
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to fetch notifications',
message: error.message
});
}
};
const markAsRead = async (req, res) => {
try {
const userId = req.user?.id;
const { id } = req.params;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized'
});
}
const notification = await notificationService.markAsRead(db, id, userId);
if (!notification) {
return res.status(404).json({
success: false,
error: 'Notification not found'
});
}
res.status(200).json({
success: true,
data: notification
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to mark notification as read',
message: error.message
});
}
};
const createNotification = async (userId, title, message, type = 'info', relatedBookingId = null, metadata = null) => {
return await notificationService.createNotification(db, {
userId,
title,
message,
type,
relatedBookingId,
metadata
});
};
module.exports = {
getNotifications,
markAsRead,
createNotification
};
