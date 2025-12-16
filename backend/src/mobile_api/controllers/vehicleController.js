const db = require('../config/postgresClient');
const staticVehicles = require('../data/staticVehicles');
const vehicleService = require('../services/vehicleService');
const { ensureMakesTableExists } = require('../utils/ensureMakesTable');
const formatVehiclePayload = (vehicle) => ({
id: vehicle.id,
name: vehicle.name,
fleet: vehicle.fleet || 'Trevel Fleet',
seats: vehicle.seats || 4,
serviceTypes: vehicle.serviceTypes || ['AIRPORT'],
imageUrl: vehicle.image?.url || vehicle.imageUrl || null,
oemRangeKms: vehicle.oemRangeKms || vehicle.rangeIncluded?.kms || null,
currentLatitude: vehicle.currentLocation?.lat ?? vehicle.currentLatitude ?? null,
currentLongitude: vehicle.currentLocation?.lng ?? vehicle.currentLongitude ?? null,
priceAmount: vehicle.priceAmount || null,
priceUnit: vehicle.priceUnit || 'per ride',
etaText: vehicle.etaText || null,
distanceText: vehicle.distanceText || null,
seatLabel: vehicle.seatLabel || null,
category: vehicle.category || null
});
const mapDbVehicleToPayload = (vehicle) =>
formatVehiclePayload({
id: vehicle.id,
name: vehicle.model || vehicle.name || 'Vehicle',
fleet: vehicle.color ? `${vehicle.color} exterior` : 'Trevel Fleet',
seats: vehicle.seats || vehicle.capacity || 4,
oemRangeKms: vehicle.oem_range_kms || vehicle.oemRangeKms || null,
currentLatitude: vehicle.current_latitude || vehicle.currentLatitude || null,
currentLongitude: vehicle.current_longitude || vehicle.currentLongitude || null,
serviceTypes: vehicle.service_types || vehicle.serviceTypes || ['AIRPORT', 'RENTAL', 'MINI'],
image: {
url: vehicle.image_url || vehicle.imageUrl || null
},
priceAmount: vehicle.price_amount || vehicle.priceAmount || vehicle.base_price || null,
etaText: vehicle.eta_text || vehicle.etaText || null,
distanceText: vehicle.distance_text || vehicle.distanceText || null,
seatLabel: vehicle.seat_label || vehicle.seatLabel || null,
category: vehicle.category || vehicle.type || null
});
const buildStaticCatalog = () => staticVehicles.map((vehicle) => formatVehiclePayload(vehicle));
const formatResponse = (data, source, extras = {}) => ({
success: true,
count: data.length,
data,
source,
...extras
});
const respondWithStaticCatalog = (res, extras = {}) => {
const data = buildStaticCatalog();
return res.status(200).json(formatResponse(data, 'static', extras));
};
const fetchVehiclesFromDb = async () => {
return await vehicleService.getAllVehicles(db);
};
const fetchVehicleById = async (id) => {
return await vehicleService.getVehicleById(db, id);
};
const getAvailableVehicles = async (req, res) => {
try {
await ensureMakesTableExists(db);
const validCategories = ['mg-win', 'byd-emax', 'kia-carens', 'bmw-ix1'];

const vehiclesData = await vehicleService.getAllVehicles(db);
const vehicles = vehiclesData.map(mapDbVehicleToPayload);
const staticVehiclesList = buildStaticCatalog();
const allVehicles = [...vehicles, ...staticVehiclesList];
const uniqueVehicles = Array.from(
new Map(allVehicles.map(v => [v.id, v])).values()
);
const vehiclesByCategory = {};
validCategories.forEach(category => {
const categoryVehicle = uniqueVehicles.find(vehicle =>
vehicle.id && vehicle.id.startsWith(category)
);
if (categoryVehicle) {
vehiclesByCategory[category] = categoryVehicle;
}
});
const resultVehicles = validCategories
.map(category => vehiclesByCategory[category])
.filter(vehicle => vehicle != null);
if (resultVehicles.length === 0) {
return res.status(200).json({
success: true,
count: 0,
data: [],
source: 'database',
message: 'Fleet not available',
available: false
});
}
return res.status(200).json(formatResponse(resultVehicles, 'database', {
categories: validCategories,
available: true
}));
} catch (error) {
return res.status(500).json({
success: false,
error: 'Failed to fetch available vehicles',
message: error.message
});
}
};
const getAllVehicles = async (req, res) => {
try {
await ensureMakesTableExists(db);
const vehicles = await fetchVehiclesFromDb();
if (Array.isArray(vehicles) && vehicles.length > 0) {
const formatted = vehicles.map((vehicle) => mapDbVehicleToPayload(vehicle));
return res.status(200).json(formatResponse(formatted, 'postgres'));
}
return respondWithStaticCatalog(res, {
message: 'Serving curated Trevel vehicle catalog until database data is seeded.'
});
} catch (error) {
return respondWithStaticCatalog(res, {
message: 'Database unavailable, served static Trevel vehicle catalog.',
details: error.message
});
}
};
const HAVERSINE_EARTH_RADIUS_METERS = 6371e3;
const toRadians = (value) => (value * Math.PI) / 180;
const computeDistanceMeters = (lat1, lon1, lat2, lon2) => {
const φ1 = toRadians(lat1);
const φ2 = toRadians(lat2);
const Δφ = toRadians(lat2 - lat1);
const Δλ = toRadians(lon2 - lon1);
const a =
Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
return HAVERSINE_EARTH_RADIUS_METERS * c;
};
const filterVehiclesByRadius = (vehicles, pickupLat, pickupLng, radiusMeters) =>
vehicles.filter((vehicle) => {
if (
typeof vehicle.currentLatitude !== 'number' ||
typeof vehicle.currentLongitude !== 'number'
) {
return false;
}
const distance = computeDistanceMeters(
pickupLat,
pickupLng,
vehicle.currentLatitude,
vehicle.currentLongitude
);
return distance <= radiusMeters;
});
const parseCoordinate = (value) => {
if (value === undefined || value === null) return null;
const num = parseFloat(value);
return Number.isFinite(num) ? num : null;
};
const parseRadiusMeters = (radiusMetersParam, radiusKmParam) => {
if (radiusMetersParam !== undefined) {
const meters = parseFloat(radiusMetersParam);
if (Number.isFinite(meters) && meters > 0) {
return meters;
}
}
if (radiusKmParam !== undefined) {
const meters = parseFloat(radiusKmParam) * 1000;
if (Number.isFinite(meters) && meters > 0) {
return meters;
}
}
return 3000;
};
const getNearbyVehicles = async (req, res) => {
const pickupLat = parseCoordinate(req.query.pickupLat ?? req.query.pickup_lat);
const pickupLng = parseCoordinate(req.query.pickupLng ?? req.query.pickup_lng);
const pickupDateRaw = req.query.pickupDate ?? req.query.pickup_date ?? null;
const pickupTimeRaw = req.query.pickupTime ?? req.query.pickup_time ?? null;
if (pickupLat === null || pickupLng === null) {
return res.status(400).json({
success: false,
error: 'Missing pickup coordinates',
message: 'pickupLat/pickupLng query parameters are required'
});
}
const radiusMeters = parseRadiusMeters(
req.query.radiusMeters ?? req.query.radius ?? req.query.radius_meters,
req.query.radiusKm ?? req.query.radius_km
);
const pickupDate = pickupDateRaw ? formatDateForResponse(pickupDateRaw) : null;
const pickupTime = pickupTimeRaw ? formatTimeForResponse(pickupTimeRaw) : null;
try {
await ensureMakesTableExists(db);
const vehicles = await fetchVehiclesFromDb();
if (Array.isArray(vehicles) && vehicles.length > 0) {
const formatted = vehicles.map((vehicle) => mapDbVehicleToPayload(vehicle));
const filtered = filterVehiclesByRadius(formatted, pickupLat, pickupLng, radiusMeters);
return res.status(200).json(
formatResponse(filtered, 'postgres', {
radiusMeters,
pickupDate,
pickupTime,
message:
filtered.length === 0
? `No vehicles found within ${(radiusMeters / 1000).toFixed(
1
)} km of pickup location`
: undefined
})
);
}
const staticData = buildStaticCatalog();
const filteredStatic = filterVehiclesByRadius(staticData, pickupLat, pickupLng, radiusMeters);
return res.status(200).json(
formatResponse(filteredStatic, 'static', {
radiusMeters,
pickupDate,
pickupTime,
message:
filteredStatic.length === 0
? `No vehicles found within ${(radiusMeters / 1000).toFixed(
1
)} km of pickup location`
: 'Serving curated Trevel vehicle catalog until database data is seeded.'
})
);
} catch (error) {
const staticData = buildStaticCatalog();
const filteredStatic = filterVehiclesByRadius(staticData, pickupLat, pickupLng, radiusMeters);
return res.status(200).json(
formatResponse(filteredStatic, 'static', {
radiusMeters,
pickupDate,
pickupTime,
message:
filteredStatic.length === 0
? `No vehicles found within ${(radiusMeters / 1000).toFixed(
1
)} km of pickup location`
: 'Database unavailable, served static Trevel vehicle catalog.',
details: error.message
})
);
}
};
const formatDateForResponse = (value) => {
const trimmed = value.trim();
const isoCandidate = trimmed.length === 10 ? `${trimmed}T00:00:00Z` : trimmed;
const date = new Date(isoCandidate);
if (!isNaN(date.getTime())) {
const day = String(date.getDate()).padStart(2, '0');
const month = String(date.getMonth() + 1).padStart(2, '0');
const year = date.getFullYear();
return `${day}-${month}-${year}`;
}
const parts = trimmed.split(/[-/]/);
if (parts.length === 3) {
return `${parts[2]}-${parts[1]}-${parts[0]}`;
}
return trimmed;
};
const formatTimeForResponse = (value) => {
const trimmed = value.trim();
if (/^\d{1,2}:\d{2}$/.test(trimmed)) {
return `${trimmed}:00`;
}
if (/^\d{1,2}:\d{2}:\d{2}$/.test(trimmed)) {
return trimmed;
}
return trimmed;
};
const getVehicleById = async (req, res) => {
try {
await ensureMakesTableExists(db);
const { id } = req.params;
const vehicle = await fetchVehicleById(id);
if (vehicle) {
return res.status(200).json({
success: true,
data: mapDbVehicleToPayload(vehicle),
source: 'postgres'
});
}
const fallbackVehicle = buildStaticCatalog().find((vehicle) => vehicle.id === id);
if (fallbackVehicle) {
return res.status(200).json({
success: true,
data: fallbackVehicle,
source: 'static'
});
}
return res.status(404).json({
success: false,
error: 'Vehicle not found'
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to fetch vehicle',
message: error.message
});
}
};
const createVehicle = async (req, res) => {
try {
await ensureMakesTableExists(db);
const { model, number_plate, color, driver_id } = req.body;
if (!model || !number_plate) {
return res.status(400).json({
success: false,
error: 'Missing required fields',
message: 'model and number_plate are required'
});
}

const vehicle = await vehicleService.createVehicle(db, {
model,
number_plate,
color,
driver_id
});
if (!vehicle) {
return res.status(500).json({
success: false,
error: 'Failed to create vehicle',
message: 'Vehicle creation failed'
});
}
return res.status(201).json({
success: true,
message: 'Vehicle created successfully',
data: vehicle
});
} catch (error) {
if (error.code === '23505') {
return res.status(409).json({
success: false,
error: 'Vehicle already exists',
message: 'A vehicle with this number plate already exists'
});
}
res.status(500).json({
success: false,
error: 'Failed to create vehicle',
message: error.message
});
}
};
const updateVehicle = async (req, res) => {
try {
await ensureMakesTableExists(db);
const { id } = req.params;
const { model, number_plate, color, driver_id } = req.body;
const updateFields = [];
const values = [];
let paramIndex = 1;
if (model !== undefined) {
updateFields.push(`model = $${paramIndex++}`);
values.push(model);
}
if (number_plate !== undefined) {
updateFields.push(`number_plate = $${paramIndex++}`);
values.push(number_plate);
}
if (color !== undefined) {
updateFields.push(`color = $${paramIndex++}`);
values.push(color);
}
if (driver_id !== undefined) {
updateFields.push(`driver_id = $${paramIndex++}`);
values.push(driver_id);
}
if (updateFields.length === 0) {
return res.status(400).json({
success: false,
error: 'No fields provided to update'
});
}

try {
const vehicle = await vehicleService.updateVehicle(db, id, {
model,
number_plate,
color,
driver_id
});
if (!vehicle) {
return res.status(404).json({
success: false,
error: 'Vehicle not found'
});
}
res.status(200).json({
success: true,
message: 'Vehicle updated successfully',
data: vehicle
});
} catch (error) {
if (error.message.includes('No fields to update')) {
return res.status(400).json({
success: false,
error: 'No fields provided to update',
message: error.message
});
}
throw error;
}
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to update vehicle',
message: error.message
});
}
};
const deleteVehicle = async (req, res) => {
try {
await ensureMakesTableExists(db);
const { id } = req.params;

const deleted = await vehicleService.deleteVehicle(db, id);
if (!deleted) {
return res.status(404).json({
success: false,
error: 'Vehicle not found'
});
}
res.status(200).json({
success: true,
message: 'Vehicle deleted successfully'
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to delete vehicle',
message: error.message
});
}
};
const getMake = getAvailableVehicles;
module.exports = {
getMake
};
