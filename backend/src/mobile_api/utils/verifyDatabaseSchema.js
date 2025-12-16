const db = require('../config/postgresClient');
const REQUIRED_TABLES = [
'users',
'drivers',
'makes',
'mini_trip_bookings',
'hourly_rental_bookings',
'to_airport_transfer_bookings',
'from_airport_transfer_bookings',
'payments',
'payment_gateway_events',
'ratings',
'complaints',
'saved_locations',
'hubs',
'vehicle_tracking',
'vehicle_hub_status'
];
const REQUIRED_VIEWS = [
'my_bookings_view'
];
async function checkTableExists(tableName) {
try {
const query = `
SELECT EXISTS (
SELECT FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name = $1
);
`;
const result = await db.query(query, [tableName]);
return result.rows[0].exists;
} catch (error) {
return false;
}
}
async function checkViewExists(viewName) {
try {
const query = `
SELECT EXISTS (
SELECT FROM information_schema.views
WHERE table_schema = 'public'
AND table_name = $1
);
`;
const result = await db.query(query, [viewName]);
return result.rows[0].exists;
} catch (error) {
return false;
}
}
async function verifyDatabaseSchema() {
const missingTables = [];
const existingTables = [];
const missingViews = [];
const existingViews = [];
for (const table of REQUIRED_TABLES) {
const exists = await checkTableExists(table);
if (exists) {
existingTables.push(table);
} else {
missingTables.push(table);
}
}
for (const view of REQUIRED_VIEWS) {
const exists = await checkViewExists(view);
if (exists) {
existingViews.push(view);
} else {
missingViews.push(view);
}
}
if (missingTables.length > 0 || missingViews.length > 0) {
if (missingTables.length > 0) {
}
if (missingViews.length > 0) {
}
return false;
} else {
return true;
}
}
if (require.main === module) {
verifyDatabaseSchema()
.then((success) => {
process.exit(success ? 0 : 1);
})
.catch((error) => {
process.exit(1);
});
}
module.exports = {
verifyDatabaseSchema,
REQUIRED_TABLES,
REQUIRED_VIEWS
};
