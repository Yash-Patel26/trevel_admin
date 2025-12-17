const ensureHubsTable = async (db) => {
  try {
    // Check if table exists (created by Prisma)
    const tableCheck = await db.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'hubs'
      );
    `);

    if (!tableCheck.rows[0].exists) {
      // Table doesn't exist - this shouldn't happen if Prisma migrations ran
      console.warn('Hubs table does not exist. Please run Prisma migrations.');
      // Don't create it - let Prisma handle it
      return false;
    }

    // Table exists - verify it has required columns (from Prisma schema)
    const columnCheck = await db.query(`
      SELECT column_name, data_type
      FROM information_schema.columns 
      WHERE table_name = 'hubs'
      ORDER BY ordinal_position
    `);
    
    const columns = columnCheck.rows.map(row => row.column_name);
    const requiredColumns = ['id', 'name', 'latitude', 'longitude', 'radius_km', 'is_active'];
    const missingColumns = requiredColumns.filter(col => !columns.includes(col));

    if (missingColumns.length > 0) {
      console.warn(`Hubs table missing columns: ${missingColumns.join(', ')}. Please run Prisma migrations.`);
      return false;
    }

    return true;
  } catch (error) {
    // Check if it's a connection error
    if (error.code === 'ECONNREFUSED' || error.message?.includes('ECONNREFUSED')) {
      console.error('Database connection refused when checking hubs table. DATABASE_URL may not be configured correctly.');
      return false;
    }
    console.error('Error checking hubs table:', error.message || error);
    // Don't throw - let the service handle it gracefully
    return false;
  }
};

module.exports = { ensureHubsTable };

