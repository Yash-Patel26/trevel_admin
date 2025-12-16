const EARTH_RADIUS_KM = 6371;
function toRadians(degrees) {
return degrees * (Math.PI / 180);
}
function calculateDistanceKm(lat1, lon1, lat2, lon2) {
if (!lat1 || !lon1 || !lat2 || !lon2) {
return null;
}
const dLat = toRadians(lat2 - lat1);
const dLon = toRadians(lon2 - lon1);
const a =
Math.sin(dLat / 2) * Math.sin(dLat / 2) +
Math.cos(toRadians(lat1)) *
Math.cos(toRadians(lat2)) *
Math.sin(dLon / 2) *
Math.sin(dLon / 2);
const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
const distanceKm = EARTH_RADIUS_KM * c;
return parseFloat(distanceKm.toFixed(2));
}
function isWithinHubRadius(vehicleLat, vehicleLon, hubLat, hubLon, radiusKm) {
const distanceKm = calculateDistanceKm(vehicleLat, vehicleLon, hubLat, hubLon);
if (distanceKm === null) {
return { isInside: false, distanceKm: null };
}
return {
isInside: distanceKm <= radiusKm,
distanceKm: distanceKm
};
}
function findHubsVehicleIsInside(vehicleLat, vehicleLon, hubs) {
if (!vehicleLat || !vehicleLon || !hubs || hubs.length === 0) {
return [];
}
const insideHubs = [];
for (const hub of hubs) {
if (!hub.latitude || !hub.longitude || !hub.radius_km) {
continue;
}
const result = isWithinHubRadius(
vehicleLat,
vehicleLon,
parseFloat(hub.latitude),
parseFloat(hub.longitude),
parseFloat(hub.radius_km)
);
if (result.isInside) {
insideHubs.push({
hubId: hub.id,
hubName: hub.name,
distanceKm: result.distanceKm
});
}
}
return insideHubs;
}
function detectHubEvent(wasInside, isInside) {
if (!wasInside && isInside) {
return 'entered';
} else if (wasInside && !isInside) {
return 'exited';
}
return null;
}
module.exports = {
calculateDistanceKm,
isWithinHubRadius,
findHubsVehicleIsInside,
detectHubEvent,
toRadians
};
