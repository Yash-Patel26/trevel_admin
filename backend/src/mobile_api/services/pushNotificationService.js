const { firebaseAdmin, initializeFirebase } = require('../../config/firebase');

// Ensure initialized
initializeFirebase();

const admin = firebaseAdmin;
const firebaseInitialized = true; // derived from module state, but for this file's logic we assume it works if init didn't throw

async function sendPushNotification(fcmToken, title, body, data = {}) {
  if (!firebaseInitialized) {
    initializeFirebase();
  }
  if (!firebaseInitialized) {
    return { success: false, error: 'Firebase not configured' };
  }
  if (!fcmToken) {
    return { success: false, error: 'No FCM token' };
  }
  try {
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        ...data,
        ...Object.fromEntries(
          Object.entries(data).map(([key, value]) => [key, String(value)])
        ),
      },
      token: fcmToken,
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'driver_arrival',
          priority: 'high',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
            priority: 10,
          },
        },
      },
    };
    const response = await admin.messaging().send(message);
    return { success: true, messageId: response };
  } catch (error) {
    if (error.code === 'messaging/invalid-registration-token' ||
      error.code === 'messaging/registration-token-not-registered') {
      return { success: false, error: 'Invalid token', shouldRemoveToken: true };
    }
    return { success: false, error: error.message };
  }
}
async function sendPushNotificationToUser(db, userId, title, body, data = {}) {
  try {
    const { rows } = await db.query(
      'SELECT fcm_token FROM "Customer" WHERE id = $1 AND fcm_token IS NOT NULL',
      [userId]
    );
    if (rows.length === 0 || !rows[0].fcm_token) {
      return { success: false, error: 'No FCM token found' };
    }
    const fcmToken = rows[0].fcm_token;
    return await sendPushNotification(fcmToken, title, body, data);
  } catch (error) {
    return { success: false, error: error.message };
  }
}
async function sendPushNotificationToUsers(userIds, title, body, data = {}) {
  const results = {
    success: 0,
    failed: 0,
    errors: [],
  };
  for (const userId of userIds) {
    const result = await sendPushNotificationToUser(userId, title, body, data);
    if (result.success) {
      results.success++;
    } else {
      results.failed++;
      results.errors.push({ userId, error: result.error });
    }
  }
  return results;
}
initializeFirebase();
module.exports = {
  initializeFirebase,
  sendPushNotification,
  sendPushNotificationToUser,
  sendPushNotificationToUsers,
};
