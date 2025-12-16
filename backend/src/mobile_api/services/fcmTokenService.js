const ensureFcmTokenColumn = async (db) => {
  try {
    await db.query(`
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM information_schema.columns
          WHERE table_name = 'users' AND column_name = 'fcm_token'
        ) THEN
          ALTER TABLE users ADD COLUMN fcm_token TEXT;
          CREATE INDEX IF NOT EXISTS idx_users_fcm_token ON users(fcm_token);
        END IF;
      END $$;
    `);
  } catch (alterError) {

  }
};

const saveFcmToken = async (db, userId, fcmToken) => {
  await ensureFcmTokenColumn(db);

  const { rows } = await db.query(
    `UPDATE users
     SET fcm_token = $1, updated_at = NOW()
     WHERE id = $2
     RETURNING id, fcm_token`,
    [fcmToken, userId]
  );

  return rows.length > 0 ? rows[0] : null;
};

const removeFcmToken = async (db, userId) => {
  await db.query(
    `UPDATE users
     SET fcm_token = NULL, updated_at = NOW()
     WHERE id = $1`,
    [userId]
  );
};

module.exports = {
  saveFcmToken,
  removeFcmToken
};

