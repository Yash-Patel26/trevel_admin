const ensureNotificationsTable = async (db) => {
  try {
    // Check if table exists
    const tableCheck = await db.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'notifications'
      );
    `);

    if (tableCheck.rows[0].exists) {
      // Table exists, check if it has required columns
      const columnCheck = await db.query(`
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'notifications'
      `);
      
      const columns = columnCheck.rows.map(row => row.column_name);
      const requiredColumns = ['id', 'user_id', 'title', 'message', 'type', 'is_read', 'created_at'];
      const missingColumns = requiredColumns.filter(col => !columns.includes(col));

      if (missingColumns.length > 0) {
        // Add missing columns
        if (!columns.includes('is_read')) {
          await db.query(`ALTER TABLE notifications ADD COLUMN IF NOT EXISTS is_read BOOLEAN DEFAULT FALSE;`);
        }
        if (!columns.includes('read_at')) {
          await db.query(`ALTER TABLE notifications ADD COLUMN IF NOT EXISTS read_at TIMESTAMP;`);
        }
        if (!columns.includes('related_booking_id')) {
          await db.query(`ALTER TABLE notifications ADD COLUMN IF NOT EXISTS related_booking_id TEXT;`);
        }
        if (!columns.includes('metadata')) {
          await db.query(`ALTER TABLE notifications ADD COLUMN IF NOT EXISTS metadata JSONB;`);
        }
      }
      return true;
    }

    // Create the notifications table
    await db.query(`
      CREATE TABLE IF NOT EXISTS notifications (
        id SERIAL PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT DEFAULT 'info',
        is_read BOOLEAN DEFAULT FALSE,
        read_at TIMESTAMP,
        related_booking_id TEXT,
        metadata JSONB,
        created_at TIMESTAMP DEFAULT NOW()
      );

      CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
      CREATE INDEX IF NOT EXISTS idx_notifications_user_id_is_read ON notifications(user_id, is_read);
      CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
    `);
    return true;
  } catch (error) {
    console.error('Error ensuring notifications table:', error);
    // Don't throw - return false to indicate failure
    // This allows the calling code to handle it gracefully
    return false;
  }
};

module.exports = { ensureNotificationsTable };

