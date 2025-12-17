const ensureFcmTokenColumn = async (db) => {
  try {
    await db.query(`
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM information_schema.columns
          WHERE table_name = 'Customer' AND column_name = 'fcm_token'
        ) THEN
          ALTER TABLE "Customer" ADD COLUMN fcm_token TEXT;
          CREATE INDEX IF NOT EXISTS idx_customer_fcm_token ON "Customer"(fcm_token);
        END IF;
      END $$;
    `);
  } catch (alterError) {

  }
};

const saveFcmToken = async (db, userId, fcmToken) => {
  await ensureFcmTokenColumn(db);

  const { rows } = await db.query(
    `UPDATE "Customer"
     SET fcm_token = $1
     WHERE id = $2
     RETURNING id, fcm_token`,
    [fcmToken, userId]
  );

  return rows.length > 0 ? rows[0] : null;
};

const removeFcmToken = async (db, userId) => {
  await db.query(
    `UPDATE "Customer"
     SET fcm_token = NULL
     WHERE id = $1`,
    [userId]
  );
};

module.exports = {
  saveFcmToken,
  removeFcmToken
};

