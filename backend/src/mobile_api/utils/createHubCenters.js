require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
if (!process.env.DB_PASSWORD) {
process.exit(1);
}
const db = require('../config/postgresClient');
const hubs = [
{
name: 'Pickup Hub - Gurgaon',
address: 'Gurgaon Pickup Zone',
latitude: 28.44857672824609,
longitude: 77.03992263840074,
radius_km: 7.0,
description: 'Main pickup hub for AIRPORT, MINI, and HOURLY bookings. Radius: 7km from epicenter.',
is_active: true
},
{
name: 'Drop Hub - Gurgaon',
address: 'Gurgaon Drop Zone',
latitude: 28.44857672824609,
longitude: 77.03992263840074,
radius_km: 7.0,
description: 'Drop hub for Gurgaon area. Radius: 7km from epicenter.',
is_active: true
},
{
name: 'Drop Hub - Delhi Circle 1',
address: 'Delhi Drop Zone - Circle 1',
latitude: 28.63169,
longitude: 77.14760,
radius_km: 10.0,
description: 'Drop hub for Delhi area - Circle 1. Radius: 10km from epicenter.',
is_active: true
},
{
name: 'Drop Hub - Delhi Circle 2',
address: 'Delhi Drop Zone - Circle 2',
latitude: 28.52380,
longitude: 77.22402,
radius_km: 5.0,
description: 'Drop hub for Delhi area - Circle 2. Radius: 5km from epicenter.',
is_active: true
},
{
name: 'Airport Terminal 1 - New Delhi (DEL)',
address: 'Terminal 1, Indira Gandhi International Airport, New Delhi',
latitude: 28.5672,
longitude: 77.1031,
radius_km: 2.0,
description: 'Airport Terminal 1 pickup and drop hub. Used for airport transfers.',
is_active: true
},
{
name: 'Airport Terminal 2 - New Delhi (DEL)',
address: 'Terminal 2, Indira Gandhi International Airport, New Delhi',
latitude: 28.5567,
longitude: 77.0870,
radius_km: 2.0,
description: 'Airport Terminal 2 pickup and drop hub. Used for airport transfers.',
is_active: true
},
{
name: 'Airport Terminal 3 - New Delhi (DEL)',
address: 'Terminal 3, Indira Gandhi International Airport, New Delhi',
latitude: 28.5562,
longitude: 77.1000,
radius_km: 2.0,
description: 'Airport Terminal 3 pickup and drop hub. Used for airport transfers.',
is_active: true
}
];
async function createHubCenters() {
try {
const tableCheck = await db.query(
`SELECT EXISTS (
SELECT FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name = 'hubs'
)`
);
if (!tableCheck.rows[0]?.exists) {
process.exit(1);
}
let created = 0;
let skipped = 0;
let errors = 0;
for (const hub of hubs) {
try {
const existing = await db.query(
'SELECT id, name FROM hubs WHERE name = $1',
[hub.name]
);
if (existing.rows.length > 0) {
skipped++;
continue;
}
const result = await db.query(
`INSERT INTO hubs (name, address, latitude, longitude, radius_km, description, is_active)
VALUES ($1, $2, $3, $4, $5, $6, $7)
RETURNING id, name, latitude, longitude, radius_km`,
[
hub.name,
hub.address,
hub.latitude,
hub.longitude,
hub.radius_km,
hub.description,
hub.is_active
]
);
const createdHub = result.rows[0];
created++;
} catch (error) {
errors++;
}
}
const allHubs = await db.query(
'SELECT id, name, latitude, longitude, radius_km, is_active FROM hubs ORDER BY created_at DESC'
);
allHubs.rows.forEach((hub, index) => {
});
process.exit(0);
} catch (error) {
process.exit(1);
}
}
createHubCenters();
