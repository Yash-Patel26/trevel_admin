const geofencingUtils = require('../utils/geofencingUtils');
const SERVICE_ZONES = {
pickups: [
{
id: 'pickup_main',
name: 'Main Pickup Zone',
address: 'Gurgaon, Haryana, India',
latitude: 28.44857672824609,
longitude: 77.03992263840074,
radius_km: 7,
service_types: ['airport', 'mini', 'hourly'],
is_active: true
}
],
drops: {
gurgaon: [
{
id: 'drop_gurgaon_main',
name: 'Gurgaon Drop Zone',
address: 'Gurgaon, Haryana, India',
latitude: 28.44857672824609,
longitude: 77.03992263840074,
radius_km: 7,
city: 'Gurgaon',
is_active: true
}
],
delhi: [
{
id: 'drop_delhi_circle1',
name: 'Delhi Drop Zone - Circle 1',
address: 'North Delhi, Delhi, India',
latitude: 28.63169,
longitude: 77.14760,
radius_km: 10,
city: 'Delhi',
is_active: true
},
{
id: 'drop_delhi_circle2',
name: 'Delhi Drop Zone - Circle 2',
address: 'South Delhi, Delhi, India',
latitude: 28.52380,
longitude: 77.22402,
radius_km: 5,
city: 'Delhi',
is_active: true
}
]
}
};
const getPickupZones = async (req, res) => {
try {
const { latitude, longitude, radius_km, service_type } = req.query;
if (!latitude || !longitude) {
return res.status(200).json({
success: true,
count: SERVICE_ZONES.pickups.length,
data: SERVICE_ZONES.pickups.filter(zone => zone.is_active)
});
}
const userLat = parseFloat(latitude);
const userLng = parseFloat(longitude);
if (isNaN(userLat) || isNaN(userLng)) {
return res.status(400).json({
success: false,
error: 'Invalid latitude or longitude values'
});
}
let availableZones = SERVICE_ZONES.pickups.filter(zone => zone.is_active);
if (service_type) {
const serviceTypeLower = service_type.toLowerCase();
availableZones = availableZones.filter(zone =>
zone.service_types.some(type => type.toLowerCase() === serviceTypeLower)
);
}
const zonesWithDistance = availableZones.map(zone => {
const distanceKm = geofencingUtils.calculateDistanceKm(
userLat,
userLng,
zone.latitude,
zone.longitude
);
const searchRadius = radius_km ? parseFloat(radius_km) : zone.radius_km;
const isWithinZone = distanceKm <= searchRadius;
return {
...zone,
distance_from_user_km: parseFloat(distanceKm.toFixed(2)),
is_within_zone: isWithinZone,
search_radius_km: searchRadius
};
});
zonesWithDistance.sort((a, b) =>
(a.distance_from_user_km || 0) - (b.distance_from_user_km || 0)
);
return res.status(200).json({
success: true,
count: zonesWithDistance.length,
search_params: {
latitude: userLat,
longitude: userLng,
radius_km: radius_km ? parseFloat(radius_km) : null,
service_type: service_type || null
},
data: zonesWithDistance
});
} catch (error) {
return res.status(500).json({
success: false,
error: 'Failed to fetch pickup zones'
});
}
};
const getDropZones = async (req, res) => {
try {
const { latitude, longitude, radius_km, city } = req.query;
let allDropZones = [];
if (!city || city.toLowerCase() === 'gurgaon') {
allDropZones = [...allDropZones, ...SERVICE_ZONES.drops.gurgaon];
}
if (!city || city.toLowerCase() === 'delhi') {
allDropZones = [...allDropZones, ...SERVICE_ZONES.drops.delhi];
}
allDropZones = allDropZones.filter(zone => zone.is_active);
if (!latitude || !longitude) {
return res.status(200).json({
success: true,
count: allDropZones.length,
data: allDropZones
});
}
const userLat = parseFloat(latitude);
const userLng = parseFloat(longitude);
if (isNaN(userLat) || isNaN(userLng)) {
return res.status(400).json({
success: false,
error: 'Invalid latitude or longitude values'
});
}
const zonesWithDistance = allDropZones.map(zone => {
const distanceKm = geofencingUtils.calculateDistanceKm(
userLat,
userLng,
zone.latitude,
zone.longitude
);
const searchRadius = radius_km ? parseFloat(radius_km) : zone.radius_km;
const isWithinZone = distanceKm <= searchRadius;
return {
...zone,
distance_from_user_km: parseFloat(distanceKm.toFixed(2)),
is_within_zone: isWithinZone,
search_radius_km: searchRadius
};
});
zonesWithDistance.sort((a, b) =>
(a.distance_from_user_km || 0) - (b.distance_from_user_km || 0)
);
return res.status(200).json({
success: true,
count: zonesWithDistance.length,
search_params: {
latitude: userLat,
longitude: userLng,
radius_km: radius_km ? parseFloat(radius_km) : null,
city: city || null
},
data: zonesWithDistance
});
} catch (error) {
return res.status(500).json({
success: false,
error: 'Failed to fetch drop zones'
});
}
};
const checkLocationInZone = async (req, res) => {
try {
const { latitude, longitude, zone_type, service_type } = req.body;
if (!latitude || !longitude || !zone_type) {
return res.status(400).json({
success: false,
error: 'latitude, longitude, and zone_type are required'
});
}
const lat = parseFloat(latitude);
const lng = parseFloat(longitude);
if (isNaN(lat) || isNaN(lng)) {
return res.status(400).json({
success: false,
error: 'Invalid latitude or longitude values'
});
}
let zones = [];
if (zone_type.toLowerCase() === 'pickup') {
zones = SERVICE_ZONES.pickups.filter(zone => zone.is_active);
if (service_type) {
const serviceTypeLower = service_type.toLowerCase();
zones = zones.filter(zone =>
zone.service_types.some(type => type.toLowerCase() === serviceTypeLower)
);
}
} else if (zone_type.toLowerCase() === 'drop') {
zones = [
...SERVICE_ZONES.drops.gurgaon,
...SERVICE_ZONES.drops.delhi
].filter(zone => zone.is_active);
} else {
return res.status(400).json({
success: false,
error: 'zone_type must be "pickup" or "drop"'
});
}
const matchingZones = zones.map(zone => {
const distanceKm = geofencingUtils.calculateDistanceKm(
lat,
lng,
zone.latitude,
zone.longitude
);
return {
zone_id: zone.id,
zone_name: zone.name,
distance_from_zone_center_km: parseFloat(distanceKm.toFixed(2)),
zone_radius_km: zone.radius_km,
is_within_zone: distanceKm <= zone.radius_km
};
}).filter(zone => zone.is_within_zone);
return res.status(200).json({
success: true,
location: { latitude: lat, longitude: lng },
zone_type: zone_type,
is_within_service_zone: matchingZones.length > 0,
matching_zones: matchingZones
});
} catch (error) {
return res.status(500).json({
success: false,
error: 'Failed to check location in zone'
});
}
};
module.exports = {
getPickupZones,
getDropZones,
checkLocationInZone
};
