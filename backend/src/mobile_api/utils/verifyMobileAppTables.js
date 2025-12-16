const db = require('../config/postgresClient');

const REQUIRED_MOBILE_APP_TABLES = [
  'notifications',
  'user_settings',
  'payment_methods',
  'faq',
  'emergency_contacts',
  'emergency_sos_events'
];

async function checkTableExists(tableName) {
  try {
    const query = `
      SELECT EXISTS (
        SELECT FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_type = 'BASE TABLE'
        AND table_name = $1
      );
    `;
    const result = await db.query(query, [tableName]);
    return result.rows[0].exists;
  } catch (error) {
    return false;
  }
}

async function verifyMobileAppTables() {
  try {
    // Test database connection
    await db.query('SELECT NOW()');

    const missingTables = [];
    const existingTables = [];

    for (const table of REQUIRED_MOBILE_APP_TABLES) {
      const exists = await checkTableExists(table);
      if (exists) {
        existingTables.push(table);
      } else {
        missingTables.push(table);
      }
    }

    if (missingTables.length > 0) {
      const errorMessage = `Missing mobile app tables: ${missingTables.join(', ')}. Please run COMPLETE_DATABASE_SCHEMA.sql first.`;
      return {
        success: false,
        existingTables,
        missingTables,
        error: errorMessage
      };
    }

    existingTables.forEach(table => console.log(`Verified table: ${table}`));

    return {
      success: true,
      tables: existingTables
    };
  } catch (error) {
    const errorMessage = error.message || 'Unknown error occurred';
    throw error;
  }
}

if (require.main === module) {
  verifyMobileAppTables()
    .then((result) => {
      process.exit(result.success ? 0 : 1);
    })
    .catch((error) => {
      process.exit(1);
    });
}

module.exports = {
  verifyMobileAppTables,
  REQUIRED_MOBILE_APP_TABLES
};
