const fs = require('fs');
const path = require('path');
const db = require('../config/postgresClient');
async function runSchemaSafe() {
try {
const testClient = await db.getClient();
try {
await testClient.query('SELECT NOW()');
} catch (error) {
throw new Error(`Cannot connect to database: ${error.message}\nPlease check your .env file and ensure PostgreSQL is running.`);
} finally {
testClient.release();
}
const schemaPath = path.join(__dirname, '../../database/COMPLETE_DATABASE_SCHEMA.sql');
if (!fs.existsSync(schemaPath)) {
throw new Error(`Schema file not found at: ${schemaPath}`);
}
const sql = fs.readFileSync(schemaPath, 'utf8');
const statements = [];
let currentStatement = '';
let inDoBlock = false;
let inFunction = false;
let parenDepth = 0;
for (let i = 0; i < sql.length; i++) {
const char = sql[i];
const nextChars = sql.substring(i, i + 10);
if (nextChars.match(/^\s*DO\s*\$\$/i)) {
inDoBlock = true;
}
if (nextChars.match(/^\s*(CREATE|ALTER)\s+.*FUNCTION/i)) {
inFunction = true;
}
currentStatement += char;
if (char === '(') parenDepth++;
if (char === ')') parenDepth--;
if (inDoBlock && nextChars.match(/\$\$\s*;/)) {
statements.push(currentStatement.trim());
currentStatement = '';
inDoBlock = false;
i += nextChars.indexOf(';');
continue;
}
if (char === ';' && !inDoBlock && !inFunction) {
const trimmed = currentStatement.trim();
if (trimmed && !trimmed.match(/^\s*--/)) {
statements.push(trimmed);
}
currentStatement = '';
}
if (inFunction && char === ';' && parenDepth === 0) {
inFunction = false;
}
}
if (currentStatement.trim()) {
statements.push(currentStatement.trim());
}
const client = await db.getClient();
let successCount = 0;
let errorCount = 0;
const errors = [];
try {
for (let i = 0; i < statements.length; i++) {
const statement = statements[i];
if (!statement || statement.trim().length === 0) continue;
try {
await client.query(statement);
successCount++;
if (statement.match(/CREATE TABLE/i)) {
const tableMatch = statement.match(/CREATE TABLE.*?(\w+)/i);
if (tableMatch) {
}
}
} catch (error) {
errorCount++;
const errorMsg = error.message;
if (errorMsg.includes('already exists') ||
errorMsg.includes('duplicate') ||
errorMsg.includes('does not exist') && errorMsg.includes('constraint')) {
continue;
}
errors.push({
statement: statement.substring(0, 100) + '...',
error: errorMsg
});
}
}
if (errors.length > 0) {
errors.forEach((err, idx) => {
});
}
const tablesResult = await client.query(`
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE'
ORDER BY table_name;
`);
tablesResult.rows.forEach(row => {
});
const viewsResult = await client.query(`
SELECT table_name
FROM information_schema.views
WHERE table_schema = 'public'
ORDER BY table_name;
`);
if (viewsResult.rows.length > 0) {
viewsResult.rows.forEach(row => {
});
}
if (errors.length === 0) {
} else {
}
} finally {
client.release();
}
} catch (error) {
if (error.code === 'ENOENT') {
} else if (error.code === 'ECONNREFUSED') {
}
process.exit(1);
}
}
if (require.main === module) {
runSchemaSafe()
.then(() => {
process.exit(0);
})
.catch((error) => {
process.exit(1);
});
}
module.exports = { runSchemaSafe };
