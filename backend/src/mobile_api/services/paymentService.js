const upsertGatewayEvent = async (db, eventData) => {
  const {
    orderId,
    tripId,
    userId,
    amount,
    currency = 'INR',
    status = 'pending',
    rawPayload
  } = eventData;

  if (!orderId) return null;

  const query = `
    INSERT INTO payment_gateway_events (order_id, trip_id, user_id, payment_method, amount, currency, status, raw_payload)
    VALUES ($1, $2, $3, 'zaakpay', $4, $5, $6, $7)
    ON CONFLICT (order_id) DO UPDATE SET
    trip_id = COALESCE(EXCLUDED.trip_id, payment_gateway_events.trip_id),
    user_id = COALESCE(EXCLUDED.user_id, payment_gateway_events.user_id),
    amount = COALESCE(EXCLUDED.amount, payment_gateway_events.amount),
    currency = COALESCE(EXCLUDED.currency, payment_gateway_events.currency),
    status = EXCLUDED.status,
    raw_payload = COALESCE(EXCLUDED.raw_payload, payment_gateway_events.raw_payload),
    updated_at = NOW()
    RETURNING *;
  `;

  const params = [
    orderId,
    tripId || null,
    userId || null,
    amount !== undefined && amount !== null ? Number(amount) : null,
    currency,
    status,
    rawPayload ? JSON.stringify(rawPayload) : null
  ];

  try {
    const { rows } = await db.query(query, params);
    return rows[0];
  } catch (error) {
    return null;
  }
};

const recordPaymentSnapshot = async (db, paymentData) => {
  const { tripId, userId, amount, currency = 'INR', status } = paymentData;

  if (!tripId || amount === undefined || amount === null) return;

  const query = `
    INSERT INTO payments (id, trip_id, user_id, amount, currency, payment_method, status, created_at)
    VALUES (gen_random_uuid(), $1, $2, $3, $4, 'zaakpay', $5, NOW())
    ON CONFLICT DO NOTHING;
  `;

  try {
    await db.query(query, [tripId, userId || null, Number(amount), currency, status]);
  } catch (error) {

  }
};

const getAllPayments = async (db, filters = {}) => {
  const { trip_id, status, user_id, limit } = filters;
  let queryText = 'SELECT * FROM payments';
  const queryParams = [];
  let paramIndex = 1;
  const conditions = [];

  if (trip_id) {
    conditions.push(`trip_id = $${paramIndex}`);
    queryParams.push(trip_id);
    paramIndex++;
  }

  if (user_id) {
    conditions.push(`user_id = $${paramIndex}`);
    queryParams.push(user_id);
    paramIndex++;
  }

  if (status && status !== 'all') {
    conditions.push(`status = $${paramIndex}`);
    queryParams.push(status);
    paramIndex++;
  }

  if (conditions.length > 0) {
    queryText += ' WHERE ' + conditions.join(' AND ');
  }

  const limitValue = Math.min(parseInt(limit) || 100, 1000);
  queryText += ` ORDER BY created_at DESC LIMIT $${paramIndex}`;
  queryParams.push(limitValue);

  const { rows, rowCount } = await db.query(queryText, queryParams);
  return { payments: rows, count: rowCount };
};

const getPaymentById = async (db, paymentId) => {
  const { rows } = await db.query('SELECT * FROM payments WHERE id = $1', [paymentId]);
  return rows.length > 0 ? rows[0] : null;
};

const getUserPayments = async (db, userId) => {
  const { rows, rowCount } = await db.query(
    `SELECT * FROM payments
     WHERE user_id = $1
     ORDER BY created_at DESC`,
    [userId]
  );
  return { payments: rows, count: rowCount };
};

const createPayment = async (db, paymentData) => {
  const {
    trip_id,
    userId,
    amount,
    currency = 'INR',
    status = 'pending',
    payment_method,
    transaction_id,
    notes
  } = paymentData;

  const { rows } = await db.query(
    `INSERT INTO payments (id, trip_id, user_id, amount, currency, status, payment_method, transaction_id, notes, created_at)
     VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7, $8, NOW())
     RETURNING *`,
    [trip_id, userId, amount, currency, status, payment_method, transaction_id, notes]
  );

  return rows.length > 0 ? rows[0] : null;
};

const getPaymentByIdAndUserId = async (db, paymentId, userId) => {
  const { rows } = await db.query(
    `SELECT * FROM payments
     WHERE id = $1 AND user_id = $2`,
    [paymentId, userId]
  );
  return rows.length > 0 ? rows[0] : null;
};

const updatePayment = async (db, paymentId, updateData) => {
  const { status, notes } = updateData;
  const updateFields = {};

  if (status !== undefined) updateFields.status = status;
  if (notes !== undefined) updateFields.notes = notes;

  if (Object.keys(updateFields).length === 0) {
    throw new Error('No fields to update');
  }

  const setClauses = Object.keys(updateFields).map((key, index) => `${key} = $${index + 1}`).join(', ');
  const values = Object.values(updateFields);
  values.push(paymentId);

  const queryText = `UPDATE payments SET ${setClauses}, updated_at = NOW() WHERE id = $${values.length} RETURNING *`;
  const { rows } = await db.query(queryText, values);

  return rows.length > 0 ? rows[0] : null;
};

const deletePayment = async (db, paymentId) => {
  const { rows } = await db.query('DELETE FROM payments WHERE id = $1 RETURNING *', [paymentId]);
  return rows.length > 0 ? rows[0] : null;
};

module.exports = {
  upsertGatewayEvent,
  recordPaymentSnapshot,
  getAllPayments,
  getPaymentById,
  getUserPayments,
  createPayment,
  getPaymentByIdAndUserId,
  updatePayment,
  deletePayment
};

