const crypto = require('crypto');

const createEmergencySos = async (db, sosData) => {
  const { userId, booking_id, latitude, longitude, address } = sosData;

  const id = crypto.randomUUID();

  const { rows: sosEvent } = await db.query(
    `INSERT INTO emergency_sos_events (id, user_id, booking_id, latitude, longitude, address, status)
     VALUES ($1, $2, $3, $4, $5, $6, 'active')
     RETURNING *`,
    [id, userId, booking_id || null, latitude, longitude, address || null]
  );

  const { rows: contacts } = await db.query(
    `SELECT * FROM emergency_contacts
     WHERE user_id = $1 AND can_receive_alerts = TRUE`,
    [userId]
  );

  const contactsNotified = contacts.map(c => c.id);

  if (contactsNotified.length > 0) {
    await db.query(
      `UPDATE emergency_sos_events
       SET contacts_notified = $1
       WHERE id = $2`,
      [contactsNotified, sosEvent[0].id]
    );
  }

  return {
    ...sosEvent[0],
    contacts_notified: contactsNotified.length
  };
};

const getEmergencyContacts = async (db, userId) => {
  const { rows } = await db.query(
    'SELECT * FROM emergency_contacts WHERE user_id = $1 ORDER BY is_primary DESC, created_at ASC',
    [userId]
  );
  return rows;
};

const addEmergencyContact = async (db, contactData) => {
  const { userId, name, phone_number, relationship, is_primary, can_receive_alerts } = contactData;

  if (is_primary) {
    await db.query(
      'UPDATE emergency_contacts SET is_primary = FALSE WHERE user_id = $1',
      [userId]
    );
  }

  const id = crypto.randomUUID();

  const { rows } = await db.query(
    `INSERT INTO emergency_contacts (id, user_id, name, phone_number, relationship, is_primary, can_receive_alerts)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     RETURNING *`,
    [id, userId, name, phone_number, relationship || null, is_primary || false, can_receive_alerts !== false]
  );

  return rows[0];
};

const getEmergencyContactById = async (db, contactId, userId) => {
  const { rows: existing } = await db.query(
    'SELECT * FROM emergency_contacts WHERE id = $1 AND user_id = $2',
    [contactId, userId]
  );
  return existing.length > 0 ? existing[0] : null;
};

const updateEmergencyContact = async (db, contactId, userId, updateData) => {
  const { name, phone_number, relationship, is_primary, can_receive_alerts } = updateData;

  const existing = await getEmergencyContactById(db, contactId, userId);
  if (!existing) {
    return null;
  }

  if (is_primary) {
    await db.query(
      'UPDATE emergency_contacts SET is_primary = FALSE WHERE user_id = $1 AND id != $2',
      [userId, contactId]
    );
  }

  const updateFields = [];
  const values = [];
  let paramIndex = 1;

  if (name !== undefined) {
    updateFields.push(`name = $${paramIndex++}`);
    values.push(name);
  }
  if (phone_number !== undefined) {
    updateFields.push(`phone_number = $${paramIndex++}`);
    values.push(phone_number);
  }
  if (relationship !== undefined) {
    updateFields.push(`relationship = $${paramIndex++}`);
    values.push(relationship);
  }
  if (is_primary !== undefined) {
    updateFields.push(`is_primary = $${paramIndex++}`);
    values.push(is_primary);
  }
  if (can_receive_alerts !== undefined) {
    updateFields.push(`can_receive_alerts = $${paramIndex++}`);
    values.push(can_receive_alerts);
  }

  if (updateFields.length === 0) {
    throw new Error('No fields to update');
  }

  values.push(contactId, userId);
  const { rows } = await db.query(
    `UPDATE emergency_contacts
     SET ${updateFields.join(', ')}
     WHERE id = $${paramIndex++} AND user_id = $${paramIndex}
     RETURNING *`,
    values
  );

  return rows[0];
};

const deleteEmergencyContact = async (db, contactId, userId) => {
  const { rows } = await db.query(
    'DELETE FROM emergency_contacts WHERE id = $1 AND user_id = $2 RETURNING *',
    [contactId, userId]
  );
  return rows.length > 0 ? rows[0] : null;
};

module.exports = {
  createEmergencySos,
  getEmergencyContacts,
  addEmergencyContact,
  getEmergencyContactById,
  updateEmergencyContact,
  deleteEmergencyContact
};

