const { sendPushNotificationToUser } = require('../services/pushNotificationService');
const { ensureNotificationsTable } = require('../utils/ensureNotificationsTable');

const getNotifications = async (db, filters = {}) => {
  try {
    // Ensure table exists
    const tableReady = await ensureNotificationsTable(db);
    if (!tableReady) {
      console.warn('Notifications table not ready, returning empty array');
      return [];
    }

    const { userId, is_read, type } = filters;
    let query = 'SELECT * FROM notifications WHERE user_id = $1';
    const params = [userId];
    let paramIndex = 2;

    if (is_read !== undefined) {
      query += ` AND is_read = $${paramIndex++}`;
      params.push(is_read === 'true');
    }
    if (type) {
      query += ` AND type = $${paramIndex++}`;
      params.push(type);
    }
    query += ' ORDER BY created_at DESC';

    const { rows } = await db.query(query, params);
    return rows;
  } catch (error) {
    console.error('Error fetching notifications:', error);
    // Return empty array instead of throwing to prevent 500 errors
    return [];
  }
};

const getNotificationById = async (db, notificationId, userId) => {
  try {
    const tableReady = await ensureNotificationsTable(db);
    if (!tableReady) {
      return null;
    }
    const { rows } = await db.query(
      'SELECT * FROM notifications WHERE id = $1 AND user_id = $2',
      [notificationId, userId]
    );
    return rows.length > 0 ? rows[0] : null;
  } catch (error) {
    console.error('Error fetching notification by ID:', error);
    return null;
  }
};

const markAsRead = async (db, notificationId, userId) => {
  try {
    const tableReady = await ensureNotificationsTable(db);
    if (!tableReady) {
      return null;
    }
    const { rows } = await db.query(
      `UPDATE notifications
       SET is_read = TRUE, read_at = NOW()
       WHERE id = $1 AND user_id = $2
       RETURNING *`,
      [notificationId, userId]
    );
    return rows.length > 0 ? rows[0] : null;
  } catch (error) {
    console.error('Error marking notification as read:', error);
    return null;
  }
};

const createNotification = async (db, notificationData) => {
  try {
    const tableReady = await ensureNotificationsTable(db);
    if (!tableReady) {
      console.warn('Notifications table not ready, cannot create notification');
      return null;
    }

    const { userId, title, message, type = 'info', relatedBookingId = null, metadata = null } = notificationData;

    const { rows } = await db.query(
      `INSERT INTO notifications (user_id, title, message, type, related_booking_id, metadata)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [userId, title, message, type, relatedBookingId, metadata ? JSON.stringify(metadata) : null]
    );

    const notification = rows[0];
    const importantTypes = ['driver_arriving', 'driver_arrived', 'booking', 'payment'];

    if (importantTypes.includes(type.toLowerCase())) {
      try {
        await sendPushNotificationToUser(
          db,
          userId,
          title,
          message,
          {
            type: type,
            booking_id: relatedBookingId || '',
            notification_id: notification.id,
            ...(metadata || {})
          }
        );
      } catch (pushError) {
        console.error('Error sending push notification:', pushError);
      }
    }

    return notification;
  } catch (error) {
    console.error('Error creating notification:', error);
    return null;
  }
};

module.exports = {
  getNotifications,
  getNotificationById,
  markAsRead,
  createNotification
};

