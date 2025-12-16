const boltPullService = require('./boltPullService');
const geofencingUtils = require('../utils/geofencingUtils');
async function syncVehiclePositions(db, options = {}) {
const {
checkHubRadius = true,
storeHistory = true
} = options;
try {
const boltDevices = await boltPullService.getAllDevicesParsed();
if (!boltDevices || boltDevices.length === 0) {
return {
success: true,
message: 'No vehicles found in Bolt API',
vehiclesTracked: 0,
hubEvents: []
};
}
let hubs = [];
if (checkHubRadius) {
const hubsResult = await db.query(
'SELECT id, name, latitude, longitude, radius_km FROM hubs WHERE is_active = TRUE'
);
hubs = hubsResult.rows;
}
const currentStatusResult = await db.query(
'SELECT vehicle_id, hub_id FROM vehicle_hub_status'
);
const currentStatusMap = new Map();
currentStatusResult.rows.forEach(row => {
if (!currentStatusMap.has(row.vehicle_id)) {
currentStatusMap.set(row.vehicle_id, new Set());
}
currentStatusMap.get(row.vehicle_id).add(row.hub_id);
});
const hubEvents = [];
let vehiclesTracked = 0;
for (const device of boltDevices) {
if (!device.latitude || !device.longitude) {
continue;
}
let vehicleResult;
if (device.deviceImei) {
vehicleResult = await db.query(
`SELECT id FROM makes WHERE device_imei = $1 LIMIT 1`,
[device.deviceImei]
);
}
if (!vehicleResult || vehicleResult.rows.length === 0) {
if (device.name) {
vehicleResult = await db.query(
`SELECT id FROM makes WHERE device_name = $1 OR number_plate = $1 LIMIT 1`,
[device.name]
);
}
}
if (!vehicleResult || vehicleResult.rows.length === 0) {
continue;
}
const vehicleId = vehicleResult.rows[0].id;
vehiclesTracked++;
if (storeHistory) {
await db.query(
`INSERT INTO vehicle_tracking
(vehicle_id, device_id, device_imei, device_name, latitude, longitude,
speed_kmh, course, ignition, status, total_distance, alarm, bolt_last_update)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)`,
[
vehicleId,
device.deviceId,
device.deviceImei,
device.name,
device.latitude,
device.longitude,
device.speed || 0,
device.course || null,
device.ignition,
device.status,
device.totalDistance || 0,
device.alarm,
device.lastUpdate ? new Date(device.lastUpdate) : null
]
);
}
try {
await db.query(
`UPDATE makes
SET current_latitude = $1,
current_longitude = $2,
last_tracked_at = NOW(),
device_imei = COALESCE($4, device_imei),
device_name = COALESCE($5, device_name)
WHERE id = $3`,
[
device.latitude,
device.longitude,
vehicleId,
device.deviceImei || null,
device.name || null
]
);
} catch (error) {
}
if (checkHubRadius && hubs.length > 0) {
const vehicleHubsInside = geofencingUtils.findHubsVehicleIsInside(
device.latitude,
device.longitude,
hubs
);
const previouslyInsideHubs = currentStatusMap.get(vehicleId) || new Set();
const currentlyInsideHubs = new Set(vehicleHubsInside.map(h => h.hubId));
for (const hubInfo of vehicleHubsInside) {
if (!previouslyInsideHubs.has(hubInfo.hubId)) {
const hub = hubs.find(h => h.id === hubInfo.hubId);
await db.query(
`INSERT INTO hub_events
(hub_id, vehicle_id, event_type, latitude, longitude, distance_from_hub_km, speed_kmh)
VALUES ($1, $2, $3, $4, $5, $6, $7)`,
[
hubInfo.hubId,
vehicleId,
'entered',
device.latitude,
device.longitude,
hubInfo.distanceKm,
device.speed || 0
]
);
await db.query(
`INSERT INTO vehicle_hub_status (vehicle_id, hub_id, entered_at)
VALUES ($1, $2, NOW())
ON CONFLICT (vehicle_id, hub_id) DO UPDATE SET last_updated = NOW()`,
[vehicleId, hubInfo.hubId]
);
hubEvents.push({
vehicleId,
vehicleName: device.name,
hubId: hubInfo.hubId,
hubName: hub?.name || 'Unknown',
eventType: 'entered',
distanceKm: hubInfo.distanceKm
});
}
}
for (const hubId of previouslyInsideHubs) {
if (!currentlyInsideHubs.has(hubId)) {
const hub = hubs.find(h => h.id === hubId);
const distance = geofencingUtils.calculateDistanceKm(
device.latitude,
device.longitude,
parseFloat(hub.latitude),
parseFloat(hub.longitude)
);
await db.query(
`INSERT INTO hub_events
(hub_id, vehicle_id, event_type, latitude, longitude, distance_from_hub_km, speed_kmh)
VALUES ($1, $2, $3, $4, $5, $6, $7)`,
[
hubId,
vehicleId,
'exited',
device.latitude,
device.longitude,
distance,
device.speed || 0
]
);
await db.query(
`DELETE FROM vehicle_hub_status WHERE vehicle_id = $1 AND hub_id = $2`,
[vehicleId, hubId]
);
hubEvents.push({
vehicleId,
vehicleName: device.name,
hubId,
hubName: hub?.name || 'Unknown',
eventType: 'exited',
distanceKm: distance
});
}
}
}
}
return {
success: true,
message: `Tracked ${vehiclesTracked} vehicles`,
vehiclesTracked,
hubEvents,
timestamp: new Date()
};
} catch (error) {
throw error;
}
}
async function getCurrentVehiclePositions(db, vehicleId = null) {
try {
let query = `
SELECT DISTINCT ON (vt.vehicle_id)
vt.*,
v.number_plate,
v.model,
v.color
FROM vehicle_tracking vt
JOIN makes v ON vt.vehicle_id = v.id
`;
const params = [];
if (vehicleId) {
query += ' WHERE vt.vehicle_id = $1';
params.push(vehicleId);
}
query += ' ORDER BY vt.vehicle_id, vt.tracked_at DESC';
const result = await db.query(query, params);
return result.rows;
} catch (error) {
throw error;
}
}
async function getVehiclesInHub(db, hubId) {
try {
const result = await db.query(
`SELECT
vhs.*,
v.number_plate,
v.model,
v.color,
vt.latitude,
vt.longitude,
vt.speed_kmh,
vt.status,
h.name as hub_name
FROM vehicle_hub_status vhs
JOIN makes v ON vhs.vehicle_id = v.id
JOIN hubs h ON vhs.hub_id = h.id
LEFT JOIN LATERAL (
SELECT latitude, longitude, speed_kmh, status
FROM vehicle_tracking
WHERE vehicle_id = v.id
ORDER BY tracked_at DESC
LIMIT 1
) vt ON true
WHERE vhs.hub_id = $1`,
[hubId]
);
return result.rows;
} catch (error) {
throw error;
}
}
async function getHubEvents(db, filters = {}) {
try {
const { hubId, vehicleId, limit = 100 } = filters;
let query = `
SELECT
he.*,
h.name as hub_name,
v.number_plate as vehicle_number_plate,
v.model as vehicle_model
FROM hub_events he
JOIN hubs h ON he.hub_id = h.id
JOIN makes v ON he.vehicle_id = v.id
WHERE 1=1
`;
const params = [];
let paramIndex = 1;
if (hubId) {
query += ` AND he.hub_id = $${paramIndex++}`;
params.push(hubId);
}
if (vehicleId) {
query += ` AND he.vehicle_id = $${paramIndex++}`;
params.push(vehicleId);
}
query += ` ORDER BY he.event_time DESC LIMIT $${paramIndex}`;
params.push(limit);
const result = await db.query(query, params);
return result.rows;
} catch (error) {
throw error;
}
}
module.exports = {
syncVehiclePositions,
getCurrentVehiclePositions,
getVehiclesInHub,
getHubEvents
};
