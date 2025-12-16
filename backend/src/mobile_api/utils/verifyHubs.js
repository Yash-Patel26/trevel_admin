require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
if (!process.env.DB_PASSWORD) {
process.exit(1);
}
const db = require('../config/postgresClient');
const requiredHubs = [
{
name: 'Pickup Hub - Gurgaon',
latitude: 28.44857672824609,
longitude: 77.03992263840074,
radius_km: 7.0
},
{
name: 'Drop Hub - Gurgaon',
latitude: 28.44857672824609,
longitude: 77.03992263840074,
radius_km: 7.0
},
{
name: 'Drop Hub - Delhi Circle 1',
latitude: 28.63169,
longitude: 77.14760,
radius_km: 10.0
},
{
name: 'Drop Hub - Delhi Circle 2',
latitude: 28.52380,
longitude: 77.22402,
radius_km: 5.0
}
];
async function verifyHubs() {
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
const allHubs = await db.query(
'SELECT id, name, latitude, longitude, radius_km, is_active, created_at FROM hubs ORDER BY created_at DESC'
);
if (allHubs.rows.length === 0) {
process.exit(1);
}
allHubs.rows.forEach((hub, index) => {
});
let allPresent = true;
for (const required of requiredHubs) {
const found = allHubs.rows.find(hub => hub.name === required.name);
if (found) {
const latMatch = Math.abs(parseFloat(found.latitude) - required.latitude) < 0.0001;
const lngMatch = Math.abs(parseFloat(found.longitude) - required.longitude) < 0.0001;
const radiusMatch = Math.abs(parseFloat(found.radius_km) - required.radius_km) < 0.1;
if (latMatch && lngMatch && radiusMatch) {
} else {
allPresent = false;
}
} else {
allPresent = false;
}
}
if (allPresent) {
} else {
}
const testLat = 28.44857672824609;
const testLng = 77.03992263840074;
const testRadius = 10.0;
const pickupHub = allHubs.rows.find(hub => hub.name === 'Pickup Hub - Gurgaon');
if (pickupHub) {
const latDiff = Math.abs(parseFloat(pickupHub.latitude) - testLat);
const lngDiff = Math.abs(parseFloat(pickupHub.longitude) - testLng);
const approxDistance = Math.sqrt(latDiff * latDiff + lngDiff * lngDiff) * 111;
if (approxDistance <= testRadius) {
} else {
}
} else {
}
process.exit(0);
} catch (error) {
process.exit(1);
}
}
verifyHubs();
