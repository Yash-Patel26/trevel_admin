const getUserSettings = async (db, userId) => {
  const { rows } = await db.query(
    'SELECT * FROM user_settings WHERE user_id = $1',
    [userId]
  );

  if (rows.length === 0) {

    const { rows: newSettings } = await db.query(
      `INSERT INTO user_settings (user_id)
       VALUES ($1)
       RETURNING *`,
      [userId]
    );
    return newSettings[0];
  }

  return rows[0];
};

const updateUserSettings = async (db, userId, updateData) => {
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
  } = updateData;

  const { rows: existing } = await db.query(
    'SELECT * FROM user_settings WHERE user_id = $1',
    [userId]
  );

  let result;

  if (existing.length === 0) {

    const updateFields = [];
    const values = [];
    let paramIndex = 1;

    if (notifications_enabled !== undefined) { updateFields.push(`notifications_enabled = $${paramIndex++}`); values.push(notifications_enabled); }
    if (notifications_push_enabled !== undefined) { updateFields.push(`notifications_push_enabled = $${paramIndex++}`); values.push(notifications_push_enabled); }
    if (notifications_email_enabled !== undefined) { updateFields.push(`notifications_email_enabled = $${paramIndex++}`); values.push(notifications_email_enabled); }
    if (notifications_sms_enabled !== undefined) { updateFields.push(`notifications_sms_enabled = $${paramIndex++}`); values.push(notifications_sms_enabled); }
    if (theme !== undefined) { updateFields.push(`theme = $${paramIndex++}`); values.push(theme); }
    if (language !== undefined) { updateFields.push(`language = $${paramIndex++}`); values.push(language); }
    if (currency !== undefined) { updateFields.push(`currency = $${paramIndex++}`); values.push(currency); }
    if (preferred_payment_method !== undefined) { updateFields.push(`preferred_payment_method = $${paramIndex++}`); values.push(preferred_payment_method); }
    if (auto_apply_promos !== undefined) { updateFields.push(`auto_apply_promos = $${paramIndex++}`); values.push(auto_apply_promos); }
    if (share_ride_data !== undefined) { updateFields.push(`share_ride_data = $${paramIndex++}`); values.push(share_ride_data); }
    if (emergency_contacts_enabled !== undefined) { updateFields.push(`emergency_contacts_enabled = $${paramIndex++}`); values.push(emergency_contacts_enabled); }
    if (location_sharing_enabled !== undefined) { updateFields.push(`location_sharing_enabled = $${paramIndex++}`); values.push(location_sharing_enabled); }

    values.push(userId);
    const query = `
      INSERT INTO user_settings (user_id${updateFields.length > 0 ? ', ' + updateFields.map(f => f.split('=')[0].trim()).join(', ') : ''})
      VALUES ($${paramIndex}${updateFields.map((_, i) => `, $${i + 1}`).join('')})
      RETURNING *
    `;
    const { rows } = await db.query(query, values);
    result = rows[0];
  } else {

    const updateFields = [];
    const values = [];
    let paramIndex = 1;

    if (notifications_enabled !== undefined) { updateFields.push(`notifications_enabled = $${paramIndex++}`); values.push(notifications_enabled); }
    if (notifications_push_enabled !== undefined) { updateFields.push(`notifications_push_enabled = $${paramIndex++}`); values.push(notifications_push_enabled); }
    if (notifications_email_enabled !== undefined) { updateFields.push(`notifications_email_enabled = $${paramIndex++}`); values.push(notifications_email_enabled); }
    if (notifications_sms_enabled !== undefined) { updateFields.push(`notifications_sms_enabled = $${paramIndex++}`); values.push(notifications_sms_enabled); }
    if (theme !== undefined) { updateFields.push(`theme = $${paramIndex++}`); values.push(theme); }
    if (language !== undefined) { updateFields.push(`language = $${paramIndex++}`); values.push(language); }
    if (currency !== undefined) { updateFields.push(`currency = $${paramIndex++}`); values.push(currency); }
    if (preferred_payment_method !== undefined) { updateFields.push(`preferred_payment_method = $${paramIndex++}`); values.push(preferred_payment_method); }
    if (auto_apply_promos !== undefined) { updateFields.push(`auto_apply_promos = $${paramIndex++}`); values.push(auto_apply_promos); }
    if (share_ride_data !== undefined) { updateFields.push(`share_ride_data = $${paramIndex++}`); values.push(share_ride_data); }
    if (emergency_contacts_enabled !== undefined) { updateFields.push(`emergency_contacts_enabled = $${paramIndex++}`); values.push(emergency_contacts_enabled); }
    if (location_sharing_enabled !== undefined) { updateFields.push(`location_sharing_enabled = $${paramIndex++}`); values.push(location_sharing_enabled); }

    if (updateFields.length === 0) {
      throw new Error('No fields to update');
    }

    values.push(userId);
    const query = `
      UPDATE user_settings
      SET ${updateFields.join(', ')}
      WHERE user_id = $${paramIndex}
      RETURNING *
    `;
    const { rows } = await db.query(query, values);
    result = rows[0];
  }

  return result;
};

module.exports = {
  getUserSettings,
  updateUserSettings
};

