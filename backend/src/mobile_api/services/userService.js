const getUserById = async (db, userId) => {
  const { rows } = await db.query('SELECT * FROM users WHERE id = $1', [userId]);
  return rows.length > 0 ? rows[0] : null;
};

const createUser = async (db, userData) => {
  const { id, email, phone, full_name } = userData;
  const { rows } = await db.query(
    `INSERT INTO users (id, email, phone, full_name)
     VALUES ($1, $2, $3, $4)
     RETURNING *`,
    [id, email, phone || null, full_name || null]
  );
  return rows.length > 0 ? rows[0] : null;
};

const updateUser = async (db, userId, updateData) => {
  const setClauses = Object.keys(updateData).map((key, index) => `${key} = $${index + 1}`).join(', ');
  const values = Object.values(updateData);
  values.push(userId);
  const queryText = `UPDATE users SET ${setClauses}, updated_at = NOW() WHERE id = $${values.length} RETURNING *`;
  const { rows } = await db.query(queryText, values);
  return rows.length > 0 ? rows[0] : null;
};

module.exports = {
  getUserById,
  createUser,
  updateUser
};

