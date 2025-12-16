const getPaymentMethods = async (db, userId) => {
  const { rows } = await db.query(
    'SELECT * FROM payment_methods WHERE user_id = $1 AND is_active = TRUE ORDER BY is_default DESC, created_at DESC',
    [userId]
  );
  return rows;
};

const unsetDefaultPaymentMethods = async (db, userId) => {
  await db.query(
    'UPDATE payment_methods SET is_default = FALSE WHERE user_id = $1',
    [userId]
  );
};

const addPaymentMethod = async (db, paymentMethodData) => {
  const {
    userId,
    type,
    provider,
    card_number_last4,
    card_brand,
    card_holder_name,
    expiry_month,
    expiry_year,
    upi_id,
    is_default,
    payment_gateway_token,
    metadata
  } = paymentMethodData;

  if (is_default) {
    await unsetDefaultPaymentMethods(db, userId);
  }

  const { rows } = await db.query(
    `INSERT INTO payment_methods (
      user_id, type, provider, card_number_last4, card_brand, card_holder_name,
      expiry_month, expiry_year, upi_id, is_default,
      payment_gateway_token, metadata
    )
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
    RETURNING *`,
    [
      userId,
      type,
      provider || null,
      card_number_last4 || null,
      card_brand || null,
      card_holder_name || null,
      expiry_month || null,
      expiry_year || null,
      upi_id || null,
      is_default || false,
      payment_gateway_token || null,
      metadata ? JSON.stringify(metadata) : null
    ]
  );

  return rows[0];
};

const getPaymentMethodById = async (db, paymentMethodId, userId) => {
  const { rows } = await db.query(
    'SELECT * FROM payment_methods WHERE id = $1 AND user_id = $2',
    [paymentMethodId, userId]
  );
  return rows.length > 0 ? rows[0] : null;
};

const deletePaymentMethod = async (db, paymentMethodId, userId) => {
  await db.query(
    'UPDATE payment_methods SET is_active = FALSE WHERE id = $1 AND user_id = $2',
    [paymentMethodId, userId]
  );
};

module.exports = {
  getPaymentMethods,
  addPaymentMethod,
  getPaymentMethodById,
  deletePaymentMethod
};

