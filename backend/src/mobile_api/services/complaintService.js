const getComplaints = async (db, filters = {}) => {
  const { status, category, user_id, all, userId } = filters;
  let query = 'SELECT * FROM complaints';
  const params = [];
  let paramIndex = 1;
  const conditions = [];

  if (all !== 'true' && !user_id) {
    conditions.push(`user_id = $${paramIndex++}`);
    params.push(userId);
  } else if (user_id) {
    conditions.push(`user_id = $${paramIndex++}`);
    params.push(user_id);
  }

  if (status) {
    conditions.push(`status = $${paramIndex++}`);
    params.push(status);
  }

  if (category) {
    conditions.push(`category = $${paramIndex++}`);
    params.push(category);
  }

  if (conditions.length > 0) {
    query += ` WHERE ${conditions.join(' AND ')}`;
  }

  query += ' ORDER BY created_at DESC';
  const { rows } = await db.query(query, params);
  return rows;
};

const getComplaintById = async (db, complaintId, userId = null, requestedUserId = null) => {
  let query, params;
  if (requestedUserId) {
    query = 'SELECT * FROM complaints WHERE id = $1 AND user_id = $2';
    params = [complaintId, requestedUserId];
  } else {
    query = 'SELECT * FROM complaints WHERE id = $1';
    params = [complaintId];
  }

  const { rows } = await db.query(query, params);
  if (rows.length === 0) {
    return null;
  }

  if (userId && !requestedUserId && rows[0].user_id !== userId) {
    throw new Error('You do not have permission to view this complaint');
  }

  return rows[0];
};

const createComplaint = async (db, complaintData) => {
  const {
    userId,
    booking_id,
    booking_type,
    subject,
    description,
    category = 'other',
    priority = 'medium'
  } = complaintData;

  const { rows } = await db.query(
    `INSERT INTO complaints
     (user_id, booking_id, booking_type, subject, description, category, priority)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     RETURNING *`,
    [
      userId,
      booking_id || null,
      booking_type || null,
      subject,
      description,
      category,
      priority
    ]
  );

  return rows[0];
};

const updateComplaint = async (db, complaintId, userId, updateData) => {
  const { subject, description, category, priority, status, admin_notes } = updateData;

  const { rows: existing } = await db.query(
    'SELECT * FROM complaints WHERE id = $1',
    [complaintId]
  );

  if (existing.length === 0) {
    return null;
  }

  const complaint = existing[0];
  const isOwner = complaint.user_id === userId;
  const isAdminUpdate = status !== undefined || admin_notes !== undefined;

  if (!isOwner && !isAdminUpdate) {
    throw new Error('You can only update your own complaints');
  }

  if (isOwner && !isAdminUpdate && complaint.status !== 'open') {
    throw new Error('Only open complaints can be updated');
  }

  const updateFields = [];
  const values = [];
  let paramIndex = 1;

  if (subject !== undefined) {
    updateFields.push(`subject = $${paramIndex++}`);
    values.push(subject);
  }
  if (description !== undefined) {
    updateFields.push(`description = $${paramIndex++}`);
    values.push(description);
  }
  if (category !== undefined) {
    updateFields.push(`category = $${paramIndex++}`);
    values.push(category);
  }
  if (priority !== undefined) {
    updateFields.push(`priority = $${paramIndex++}`);
    values.push(priority);
  }
  if (status !== undefined) {
    updateFields.push(`status = $${paramIndex++}`);
    values.push(status);
  }
  if (admin_notes !== undefined) {
    updateFields.push(`admin_notes = $${paramIndex++}`);
    values.push(admin_notes);
  }

  if (updateFields.length === 0) {
    throw new Error('No fields to update');
  }

  if (isOwner && !isAdminUpdate) {
    values.push(complaintId, userId);
    const { rows } = await db.query(
      `UPDATE complaints
       SET ${updateFields.join(', ')}, updated_at = NOW()
       WHERE id = $${paramIndex++} AND user_id = $${paramIndex++}
       RETURNING *`,
      values
    );
    return rows[0];
  }

  values.push(complaintId);
  const { rows } = await db.query(
    `UPDATE complaints
     SET ${updateFields.join(', ')}, updated_at = NOW()
     WHERE id = $${paramIndex++}
     RETURNING *`,
    values
  );

  return rows[0];
};

module.exports = {
  getComplaints,
  getComplaintById,
  createComplaint,
  updateComplaint
};

