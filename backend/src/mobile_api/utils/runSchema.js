const fs = require('fs');
const path = require('path');
const db = require('../config/postgresClient');
async function runSchema() {
try {
const testClient = await db.getClient();
try {
await testClient.query('SELECT NOW()');
} catch (error) {
throw new Error(`Cannot connect to database: ${error.message}\nPlease check your .env file and ensure PostgreSQL is running.`);
} finally {
testClient.release();
}
const checkClient = await db.getClient();
let existingTables = [];
try {
const result = await checkClient.query(`
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE'
ORDER BY table_name;
`);
existingTables = result.rows.map(r => r.table_name);
if (existingTables.length > 0) {
}
} catch (error) {
} finally {
checkClient.release();
}
const schemaPath = path.join(__dirname, '../../database/COMPLETE_DATABASE_SCHEMA.sql');
if (!fs.existsSync(schemaPath)) {
throw new Error(`Schema file not found at: ${schemaPath}`);
}
const sql = fs.readFileSync(schemaPath, 'utf8');
const client = await db.getClient();
try {
await client.query('BEGIN');
await client.query(sql);
await client.query('COMMIT');
const tablesQuery = `
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE'
ORDER BY table_name;
`;
const tablesResult = await client.query(tablesQuery);
tablesResult.rows.forEach(row => {
});
const viewsQuery = `
SELECT table_name
FROM information_schema.views
WHERE table_schema = 'public'
ORDER BY table_name;
`;
const viewsResult = await client.query(viewsQuery);
if (viewsResult.rows.length > 0) {
viewsResult.rows.forEach(row => {
});
}
} catch (error) {
try {
await client.query('ROLLBACK');
} catch (rollbackError) {
}
throw error;
} finally {
client.release();
}
} catch (error) {
if (error.code === 'ENOENT') {
} else if (error.code === 'ECONNREFUSED') {
} else if (error.message.includes('does not exist')) {
} else {
}
process.exit(1);
}
}
if (require.main === module) {
runSchema()
.then(() => {
process.exit(0);
})
.catch((error) => {
process.exit(1);
});
}
module.exports = { runSchema };
