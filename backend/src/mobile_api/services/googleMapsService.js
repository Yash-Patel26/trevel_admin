const axios = require('axios');
const GOOGLE_MAPS_API_KEY = process.env.GOOGLE_MAPS_API_KEY;
if (!GOOGLE_MAPS_API_KEY) {
  throw new Error('GOOGLE_MAPS_API_KEY is required. Please set it in your .env file.');
}
const GOOGLE_MAPS_BASE_URL = 'https://maps.googleapis.com/maps/api';
const DIRECTIONS_URL = `${GOOGLE_MAPS_BASE_URL}/directions/json`;
const GOOGLE_MAPS_DIRECTIONS_URL = DIRECTIONS_URL;
const DISTANCE_MATRIX_URL = `${GOOGLE_MAPS_BASE_URL}/distancematrix/json`;
const GEOCODING_URL = `${GOOGLE_MAPS_BASE_URL}/geocode/json`;
const PLACES_AUTOCOMPLETE_URL = `${GOOGLE_MAPS_BASE_URL}/place/autocomplete/json`;
const PLACE_DETAILS_URL = `${GOOGLE_MAPS_BASE_URL}/place/details/json`;
async function getRoutes(origin, destination, options = {}) {
try {
const params = {
origin: origin,
destination: destination,
key: GOOGLE_MAPS_API_KEY,
mode: 'driving',
alternatives: true,
...options
};
if (options.departure_time) {
const nowUnix = Math.floor(Date.now() / 1000);
if (options.departure_time >= nowUnix) {
params.departure_time = options.departure_time;
}
}
const response = await axios.get(GOOGLE_MAPS_DIRECTIONS_URL, { params });
if (response.data.status !== 'OK') {
throw new Error(`Google Maps API error: ${response.data.status} - ${response.data.error_message || 'Unknown error'}`);
}
return response.data;
} catch (error) {
throw error;
}
}
function parseRoutes(googleMapsData) {
if (!googleMapsData.routes || googleMapsData.routes.length === 0) {
return [];
}
const routes = [];
googleMapsData.routes.forEach((route, index) => {
const leg = route.legs[0];
if (!leg) return;
const distanceKm = leg.distance.value / 1000;
const durationMinutes = Math.round(leg.duration.value / 60);
const durationInTrafficMinutes = leg.duration_in_traffic
? Math.round(leg.duration_in_traffic.value / 60)
: durationMinutes;
let hasTolls = false;
let tollAmount = 0;
if (route.legs && route.legs[0] && route.legs[0].steps) {
hasTolls = route.legs[0].steps.some(step => {
const htmlInstructions = step.html_instructions?.toLowerCase() || '';
return htmlInstructions.includes('toll') ||
htmlInstructions.includes('收费') ||
htmlInstructions.includes('peaje');
});
if (hasTolls) {
tollAmount = 50;
}
}
let routeType = 'balanced';
if (index === 0) {
routeType = 'fastest';
} else {
const firstRoute = googleMapsData.routes[0].legs[0];
if (leg.distance.value < firstRoute.distance.value) {
routeType = 'shortest';
} else {
routeType = 'balanced';
}
}
routes.push({
type: routeType,
distance_km: parseFloat(distanceKm.toFixed(2)),
duration_minutes: durationMinutes,
duration_in_traffic_minutes: durationInTrafficMinutes,
summary: route.summary || `Route ${index + 1}`,
overview_polyline: route.overview_polyline?.points || null,
bounds: route.bounds || null,
has_tolls: hasTolls,
toll_amount: tollAmount,
warnings: route.warnings || []
});
});
routes.sort((a, b) => {
if (a.distance_km < b.distance_km) return -1;
if (a.distance_km > b.distance_km) return 1;
return a.duration_minutes - b.duration_minutes;
});
if (routes.length > 0) {
const shortestDistance = Math.min(...routes.map(r => r.distance_km));
const shortestIndex = routes.findIndex(r => r.distance_km === shortestDistance);
if (shortestIndex >= 0) {
routes[shortestIndex].type = 'shortest';
}
}
if (routes.length > 0) {
const fastestDuration = Math.min(...routes.map(r => r.duration_minutes));
const fastestIndex = routes.findIndex(r => r.duration_minutes === fastestDuration);
if (fastestIndex >= 0) {
if (fastestIndex !== routes.findIndex(r => r.type === 'shortest')) {
routes[fastestIndex].type = 'fastest';
}
}
}
routes.forEach((route, index) => {
if (route.type === 'balanced' && index > 0) {
}
});
return routes;
}
async function getRouteOptions(pickupLocation, dropoffLocation, departureTime = null) {
try {
const options = {};
if (departureTime) {
const time = departureTime instanceof Date ? departureTime : new Date(departureTime);
options.departure_time = Math.floor(time.getTime() / 1000);
}
const googleMapsData = await getRoutes(pickupLocation, dropoffLocation, options);
const routes = parseRoutes(googleMapsData);
return routes;
} catch (error) {
throw error;
}
}
async function getDistanceMatrix(origins, destinations, options = {}) {
try {
const params = {
origins: Array.isArray(origins) ? origins.join('|') : origins,
destinations: Array.isArray(destinations) ? destinations.join('|') : destinations,
key: GOOGLE_MAPS_API_KEY,
mode: options.mode || 'driving',
units: options.units || 'metric',
...options
};
if (options.departure_time) {
const nowUnix = Math.floor(Date.now() / 1000);
if (options.departure_time >= nowUnix) {
params.departure_time = options.departure_time;
params.traffic_model = options.traffic_model || 'best_guess';
}
}
const response = await axios.get(DISTANCE_MATRIX_URL, { params });
if (response.data.status !== 'OK') {
throw new Error(`Google Maps Distance Matrix API error: ${response.data.status} - ${response.data.error_message || 'Unknown error'}`);
}
return response.data;
} catch (error) {
throw error;
}
}
async function geocodeAddress(address) {
try {
const params = {
address: address,
key: GOOGLE_MAPS_API_KEY
};
const response = await axios.get(GEOCODING_URL, { params });
if (response.data.status !== 'OK') {
throw new Error(`Google Maps Geocoding API error: ${response.data.status} - ${response.data.error_message || 'Unknown error'}`);
}
if (response.data.results.length === 0) {
throw new Error('No results found for the given address');
}
const result = response.data.results[0];
return {
formatted_address: result.formatted_address,
location: {
lat: result.geometry.location.lat,
lng: result.geometry.location.lng
},
place_id: result.place_id,
address_components: result.address_components,
geometry: {
location_type: result.geometry.location_type,
viewport: result.geometry.viewport,
bounds: result.geometry.bounds
}
};
} catch (error) {
throw error;
}
}
async function reverseGeocode(lat, lng) {
try {
const params = {
latlng: `${lat},${lng}`,
key: GOOGLE_MAPS_API_KEY
};
const response = await axios.get(GEOCODING_URL, { params });
if (response.data.status !== 'OK') {
throw new Error(`Google Maps Reverse Geocoding API error: ${response.data.status} - ${response.data.error_message || 'Unknown error'}`);
}
if (response.data.results.length === 0) {
throw new Error('No results found for the given coordinates');
}
const result = response.data.results[0];
return {
formatted_address: result.formatted_address,
location: {
lat: result.geometry.location.lat,
lng: result.geometry.location.lng
},
place_id: result.place_id,
address_components: result.address_components,
geometry: {
location_type: result.geometry.location_type,
viewport: result.geometry.viewport,
bounds: result.geometry.bounds
}
};
} catch (error) {
throw error;
}
}
async function getPlaceAutocomplete(input, options = {}) {
try {
const params = {
input: input,
key: GOOGLE_MAPS_API_KEY,
...options
};
if (options.location) {
params.location = `${options.location.lat},${options.location.lng}`;
params.radius = options.radius || 50000;
}
if (options.types) {
params.types = options.types;
}
if (options.components) {
params.components = options.components;
}
const response = await axios.get(PLACES_AUTOCOMPLETE_URL, { params });
if (response.data.status !== 'OK' && response.data.status !== 'ZERO_RESULTS') {
throw new Error(`Google Maps Places Autocomplete API error: ${response.data.status} - ${response.data.error_message || 'Unknown error'}`);
}
return response.data.predictions || [];
} catch (error) {
throw error;
}
}
async function getPlaceDetails(placeId, options = {}) {
try {
const params = {
place_id: placeId,
key: GOOGLE_MAPS_API_KEY,
fields: options.fields || 'formatted_address,geometry,place_id,name,address_components,types'
};
const response = await axios.get(PLACE_DETAILS_URL, { params });
if (response.data.status !== 'OK') {
throw new Error(`Google Maps Place Details API error: ${response.data.status} - ${response.data.error_message || 'Unknown error'}`);
}
return response.data.result;
} catch (error) {
throw error;
}
}
async function getDistanceWithTraffic(origin, destination, departureTime = null) {
try {

let originString = origin;
let destinationString = destination;

if (typeof origin === 'object' && origin !== null && !Array.isArray(origin)) {
  const lat = origin.lat || origin.latitude;
  const lng = origin.lng || origin.longitude;
  if (lat != null && lng != null) {
    originString = `${lat},${lng}`;
  } else {
    throw new Error('Invalid origin format: must have lat/lng or latitude/longitude properties, or be a string');
  }
}

if (typeof destination === 'object' && destination !== null && !Array.isArray(destination)) {
  const lat = destination.lat || destination.latitude;
  const lng = destination.lng || destination.longitude;
  if (lat != null && lng != null) {
    destinationString = `${lat},${lng}`;
  } else {
    throw new Error('Invalid destination format: must have lat/lng or latitude/longitude properties, or be a string');
  }
}

const options = {};
if (departureTime) {
const time = departureTime instanceof Date
? departureTime
: typeof departureTime === 'number'
? new Date(departureTime * 1000)
: new Date(departureTime);
options.departure_time = Math.floor(time.getTime() / 1000);
options.traffic_model = 'best_guess';
}
const matrixData = await getDistanceMatrix(originString, destinationString, options);
if (!matrixData.rows || matrixData.rows.length === 0 || !matrixData.rows[0].elements || matrixData.rows[0].elements.length === 0) {
throw new Error('No distance data available');
}
const element = matrixData.rows[0].elements[0];
if (element.status !== 'OK') {
throw new Error(`Distance Matrix error: ${element.status}`);
}
return {
distance_km: element.distance.value / 1000,
distance_meters: element.distance.value,
distance_text: element.distance.text,
duration_minutes: Math.round(element.duration.value / 60),
duration_seconds: element.duration.value,
duration_text: element.duration.text,
duration_in_traffic_minutes: element.duration_in_traffic
? Math.round(element.duration_in_traffic.value / 60)
: Math.round(element.duration.value / 60),
duration_in_traffic_seconds: element.duration_in_traffic?.value || element.duration.value,
duration_in_traffic_text: element.duration_in_traffic?.text || element.duration.text,
has_traffic_data: !!element.duration_in_traffic
};
} catch (error) {
throw error;
}
}
async function getOptimizedRoute(origin, destination, departureTime = null, options = {}) {
try {
const routeOptions = {};
if (departureTime) {
const time = departureTime instanceof Date
? departureTime
: typeof departureTime === 'number'
? new Date(departureTime * 1000)
: new Date(departureTime);
routeOptions.departure_time = Math.floor(time.getTime() / 1000);
}
const routes = await getRouteOptions(origin, destination, departureTime);
if (routes.length === 0) {
throw new Error('No routes found');
}
const fastestRoute = routes[0];
const trafficData = await getDistanceWithTraffic(origin, destination, departureTime);
return {
routes: routes,
recommended_route: fastestRoute,
traffic_info: {
distance_km: trafficData.distance_km,
duration_minutes: trafficData.duration_minutes,
duration_in_traffic_minutes: trafficData.duration_in_traffic_minutes,
has_traffic_data: trafficData.has_traffic_data,
traffic_delay_minutes: trafficData.duration_in_traffic_minutes - trafficData.duration_minutes
},
summary: {
total_routes: routes.length,
fastest_route_index: 0,
shortest_route: routes.reduce((shortest, route) =>
route.distance_km < shortest.distance_km ? route : shortest
)
}
};
} catch (error) {
throw error;
}
}
async function getRoutesWithPricing(pickupLocation, dropoffLocation, pickupTime, pricingService) {
try {
const routes = await getRouteOptions(pickupLocation, dropoffLocation, pickupTime);
const routesWithPricing = routes.map(route => {
const pricing = pricingService.calculateMiniTravelPrice(route.distance_km, pickupTime);
return {
...route,
base_price: pricing.basePrice,
gst_amount: pricing.gstAmount,
final_price: pricing.finalPrice,
is_peak_hours: pricing.isPeakHours
};
});
return routesWithPricing;
} catch (error) {
throw error;
}
}
module.exports = {
getRoutes,
parseRoutes,
getRouteOptions,
getRoutesWithPricing,
getDistanceMatrix,
getDistanceWithTraffic,
geocodeAddress,
reverseGeocode,
getPlaceAutocomplete,
getPlaceDetails,
getOptimizedRoute
};
