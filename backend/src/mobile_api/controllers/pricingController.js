const pricingService = require('../services/pricingService');
function parseTime(timeInput) {
if (!timeInput) return null;
if (timeInput instanceof Date) {
return timeInput;
}
if (typeof timeInput === 'string') {
const trimmed = timeInput.trim();
const amPmMatch = /^(\d{1,2}):(\d{2})\s?(AM|PM)$/i.exec(trimmed);
if (amPmMatch) {
let [, hourStr, minuteStr, suffix] = amPmMatch;
let hour = parseInt(hourStr, 10);
const minutes = parseInt(minuteStr, 10);
const isPm = suffix.toUpperCase() === 'PM';
if (hour === 12) {
hour = isPm ? 12 : 0;
} else if (isPm) {
hour += 12;
}
return `${String(hour).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:00`;
}
if (/^\d{2}:\d{2}(:\d{2})?$/.test(trimmed)) {
if (trimmed.length === 5) {
return `${trimmed}:00`;
}
return trimmed;
}
}
return timeInput;
}
const estimateMiniTravelPrice = async (req, res) => {
try {
const { distance, distanceKm, pickupTime } = req.query;
const distanceValue = parseFloat(distance || distanceKm);
const timeValue = parseTime(pickupTime);
if (!distanceValue || distanceValue <= 0) {
return res.status(400).json({
success: false,
error: 'Invalid distance',
message: 'distance or distanceKm is required and must be greater than 0'
});
}
if (distanceValue < 0.1) {
return res.status(400).json({
success: false,
error: 'Invalid distance',
message: 'Distance must be at least 0.1 km (minimum booking distance)'
});
}
if (!timeValue) {
return res.status(400).json({
success: false,
error: 'Invalid pickup time',
message: 'pickupTime is required (format: HH:MM or HH:MM:SS)'
});
}
const pricing = pricingService.calculateMiniTravelPrice(distanceValue, timeValue);
res.status(200).json({
success: true,
service: 'mini_travel',
pricing: {
distanceKm: pricing.distanceKm,
isPeakHours: pricing.isPeakHours,
basePrice: pricing.basePrice,
gstAmount: pricing.gstAmount,
finalPrice: pricing.finalPrice,
currency: 'INR',
breakdown: {
basePrice: `₹${pricing.basePrice.toFixed(2)}`,
gst: `₹${pricing.gstAmount.toFixed(2)} (5%)`,
total: `₹${pricing.finalPrice}`
}
}
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to estimate price',
message: error.message
});
}
};
const estimateAirportDropPrice = async (req, res) => {
try {
const { pickupTime } = req.query;
const timeValue = parseTime(pickupTime);
if (!timeValue) {
return res.status(400).json({
success: false,
error: 'Invalid pickup time',
message: 'pickupTime is required (format: HH:MM or HH:MM:SS)'
});
}
const pricing = pricingService.calculateAirportDropPrice(timeValue);
res.status(200).json({
success: true,
service: 'airport_drop',
pricing: {
isPeakHours: pricing.isPeakHours,
basePrice: pricing.basePrice,
gstAmount: pricing.gstAmount,
finalPrice: pricing.finalPrice,
currency: 'INR',
breakdown: {
basePrice: `₹${pricing.basePrice.toFixed(2)}`,
gst: `₹${pricing.gstAmount.toFixed(2)} (5%)`,
total: `₹${pricing.finalPrice}`
}
}
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to estimate price',
message: error.message
});
}
};
const estimateAirportPickupPrice = async (req, res) => {
try {
const { pickupTime } = req.query;
const timeValue = parseTime(pickupTime);
if (!timeValue) {
return res.status(400).json({
success: false,
error: 'Invalid pickup time',
message: 'pickupTime is required (format: HH:MM or HH:MM:SS)'
});
}
const pricing = pricingService.calculateAirportPickupPrice(timeValue);
res.status(200).json({
success: true,
service: 'airport_pickup',
pricing: {
isPeakHours: pricing.isPeakHours,
basePrice: pricing.basePrice,
gstAmount: pricing.gstAmount,
finalPrice: pricing.finalPrice,
currency: 'INR',
breakdown: {
basePrice: `₹${pricing.basePrice.toFixed(2)}`,
gst: `₹${pricing.gstAmount.toFixed(2)} (5%)`,
total: `₹${pricing.finalPrice}`
}
}
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to estimate price',
message: error.message
});
}
};
const estimateHourlyRentalPrice = async (req, res) => {
try {
const { hours } = req.query;
const hoursValue = parseFloat(hours);
if (!hoursValue || hoursValue <= 0) {
return res.status(400).json({
success: false,
error: 'Invalid hours',
message: 'hours is required and must be greater than 0'
});
}
const pricing = pricingService.calculateHourlyRentalPrice(hoursValue);
res.status(200).json({
success: true,
service: 'hourly_rental',
pricing: {
hours: pricing.hours,
basePrice: pricing.basePrice,
gstAmount: pricing.gstAmount,
finalPrice: pricing.finalPrice,
currency: 'INR',
breakdown: {
basePrice: `₹${pricing.basePrice.toFixed(2)}`,
gst: `₹${pricing.gstAmount.toFixed(2)} (5%)`,
total: `₹${pricing.finalPrice}`
}
}
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to estimate price',
message: error.message
});
}
};
const estimatePrice = async (req, res) => {
try {
const { serviceType, distanceKm, distance, pickupTime, hours } = req.body;
if (!serviceType) {
return res.status(400).json({
success: false,
error: 'Missing service type',
message: 'serviceType is required (miniTravel, airportDrop, airportPickup, hourlyRental)'
});
}
const validServiceTypes = ['minitravel', 'mini_travel', 'mini-travel', 'airportdrop', 'airport_drop', 'airport-drop', 'to_airport', 'airportpickup', 'airport_pickup', 'airport-pickup', 'from_airport', 'hourlyrental', 'hourly_rental', 'hourly-rental'];
if (!validServiceTypes.includes(serviceType.toLowerCase())) {
return res.status(400).json({
success: false,
error: 'Invalid service type',
message: `serviceType must be one of: miniTravel, airportDrop, airportPickup, hourlyRental`
});
}
const params = {};
if (distanceKm || distance) {
params.distanceKm = parseFloat(distanceKm || distance);
}
if (pickupTime) {
params.pickupTime = parseTime(pickupTime);
}
if (hours) {
params.hours = parseFloat(hours);
}
const pricing = pricingService.calculatePrice(serviceType, params);
res.status(200).json({
success: true,
service: serviceType,
pricing: {
...pricing,
currency: 'INR',
breakdown: {
basePrice: `₹${pricing.basePrice.toFixed(2)}`,
gst: `₹${pricing.gstAmount.toFixed(2)} (5%)`,
total: `₹${pricing.finalPrice}`
}
}
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to estimate price',
message: error.message
});
}
};
const getRouteOptions = async (req, res) => {
try {
const { pickup_location, dropoff_location, pickup_time, pickup_date, routes, include_traffic } = req.body;
if (!pickup_location || !dropoff_location || !pickup_time) {
return res.status(400).json({
success: false,
error: 'Missing required fields',
message: 'pickup_location, dropoff_location, and pickup_time are required'
});
}
const timeValue = parseTime(pickup_time);
if (!timeValue) {
return res.status(400).json({
success: false,
error: 'Invalid pickup time',
message: 'pickupTime is required (format: HH:MM or HH:MM:SS)'
});
}
const googleMapsService = require('../services/googleMapsService');
let routesData = [];
if (routes && Array.isArray(routes) && routes.length > 0) {
routesData = routes;
} else {
try {
let departureTime = null;
if (pickup_date && pickup_time) {
const dateStr = pickup_date.includes('-') ? pickup_date : pickup_date.split('-').reverse().join('-');
const [hours, minutes] = timeValue.split(':');
departureTime = new Date(`${dateStr}T${hours}:${minutes}:00`);
if (departureTime < new Date()) {
const today = new Date();
const [h, m] = timeValue.split(':');
today.setHours(parseInt(h), parseInt(m), 0, 0);
departureTime = today;
}
}
let googleRoutes;
let trafficInfo = null;
if (include_traffic !== false) {
try {
const optimizedRoute = await googleMapsService.getOptimizedRoute(
pickup_location,
dropoff_location,
departureTime
);
googleRoutes = optimizedRoute.routes;
trafficInfo = optimizedRoute.traffic_info;
} catch (trafficError) {
googleRoutes = await googleMapsService.getRouteOptions(
pickup_location,
dropoff_location,
departureTime
);
}
} else {
googleRoutes = await googleMapsService.getRouteOptions(
pickup_location,
dropoff_location,
departureTime
);
}
if (googleRoutes.length === 0) {
return res.status(400).json({
success: false,
error: 'No routes found',
message: 'Google Maps could not find routes between the provided locations'
});
}
routesData = googleRoutes;
} catch (error) {
return res.status(500).json({
success: false,
error: 'Failed to get routes from Google Maps',
message: error.message || 'Could not fetch routes. Please check your Google Maps API key and try again.'
});
}
}
const routeOptions = routesData.map(route => {
const { type, distance_km, duration_minutes, duration_in_traffic_minutes } = route;
if (!distance_km || distance_km <= 0) {
return null;
}
try {
const pricing = pricingService.calculateMiniTravelPrice(distance_km, timeValue);
return {
type: type || 'balanced',
distance_km: parseFloat(distance_km.toFixed(2)),
duration_minutes: duration_minutes || null,
duration_in_traffic_minutes: duration_in_traffic_minutes || duration_minutes || null,
summary: route.summary || null,
overview_polyline: route.overview_polyline || null,
bounds: route.bounds || null,
price: {
basePrice: pricing.basePrice,
gstAmount: pricing.gstAmount,
finalPrice: pricing.finalPrice,
currency: 'INR'
},
isPeakHours: pricing.isPeakHours,
traffic_delay_minutes: duration_in_traffic_minutes && duration_minutes
? duration_in_traffic_minutes - duration_minutes
: null
};
} catch (error) {
return null;
}
}).filter(route => route !== null);
if (routeOptions.length === 0) {
return res.status(400).json({
success: false,
error: 'No valid routes',
message: 'Could not calculate prices for any routes'
});
}
let fastestRoute = routeOptions[0];
let fastestDuration = typeof fastestRoute.duration_minutes === 'number'
? fastestRoute.duration_minutes
: Number.MAX_SAFE_INTEGER;
for (const r of routeOptions) {
if (
typeof r.duration_minutes === 'number' &&
r.duration_minutes < fastestDuration
) {
fastestDuration = r.duration_minutes;
fastestRoute = r;
}
}
fastestRoute.type = 'fastest';

let routeTypeForTolerance = fastestRoute.type || 'fastest';
const validRouteTypes = ['fastest', 'shortest', 'balanced'];
if (!validRouteTypes.includes(routeTypeForTolerance.toLowerCase())) {

routeTypeForTolerance = 'fastest';
}
const toleranceInfo = require('../services/pricingService').TOLERANCE_THRESHOLDS[routeTypeForTolerance];
res.status(200).json({
success: true,
routes: [fastestRoute],
recommended_route: 'fastest',
recommended_price: fastestRoute.price.finalPrice,
price_difference: 0,
traffic_info: trafficInfo ? {
has_traffic_data: trafficInfo.has_traffic_data,
traffic_delay_minutes: trafficInfo.traffic_delay_minutes,
duration_with_traffic: trafficInfo.duration_in_traffic_minutes
} : null,
tolerance_info: {
route_type: fastestRoute.type || 'fastest',
tolerance_percent: toleranceInfo.tolerancePercent,
mandatory: toleranceInfo.mandatory,
reason: toleranceInfo.reason,
message: `Distance changes up to ${toleranceInfo.tolerancePercent}% will not incur additional charges`
},
message: 'Fastest route selected automatically based on Google Maps duration'
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to get route options',
message: error.message
});
}
};
const getComprehensiveRoute = async (req, res) => {
try {
const {
pickup_location,
dropoff_location,
pickup_time,
pickup_date,
service_type = 'miniTravel'
} = req.body;
if (!pickup_location || !dropoff_location || !pickup_time) {
return res.status(400).json({
success: false,
error: 'Missing required fields',
message: 'pickup_location, dropoff_location, and pickup_time are required'
});
}
const timeValue = parseTime(pickup_time);
if (!timeValue) {
return res.status(400).json({
success: false,
error: 'Invalid pickup time',
message: 'pickupTime is required (format: HH:MM or HH:MM:SS)'
});
}
const googleMapsService = require('../services/googleMapsService');
let departureTime = null;
if (pickup_date && pickup_time) {
const dateStr = pickup_date.includes('-') ? pickup_date : pickup_date.split('-').reverse().join('-');
const [hours, minutes] = timeValue.split(':');
departureTime = new Date(`${dateStr}T${hours}:${minutes}:00`);
if (departureTime < new Date()) {
const today = new Date();
const [h, m] = timeValue.split(':');
today.setHours(parseInt(h), parseInt(m), 0, 0);
departureTime = today;
}
}
const optimizedRoute = await googleMapsService.getOptimizedRoute(
pickup_location,
dropoff_location,
departureTime
);
if (!optimizedRoute.routes || optimizedRoute.routes.length === 0) {
return res.status(400).json({
success: false,
error: 'No routes found',
message: 'Google Maps could not find routes between the provided locations'
});
}
const recommendedRoute = optimizedRoute.recommended_route;
const distanceKm = recommendedRoute.distance_km || optimizedRoute.traffic_info.distance_km;
let pricing;
if (service_type === 'miniTravel' || service_type === 'mini_travel') {
pricing = pricingService.calculateMiniTravelPrice(distanceKm, timeValue);
} else if (service_type === 'airportDrop' || service_type === 'airport_drop') {
pricing = pricingService.calculateAirportDropPrice(timeValue);
} else if (service_type === 'airportPickup' || service_type === 'airport_pickup') {
pricing = pricingService.calculateAirportPickupPrice(timeValue);
} else {
return res.status(400).json({
success: false,
error: 'Invalid service type',
message: 'service_type must be miniTravel, airportDrop, or airportPickup'
});
}
let pickupAddress = null;
let dropoffAddress = null;
try {
if (typeof pickup_location === 'string' && !pickup_location.includes(',')) {
pickupAddress = await googleMapsService.geocodeAddress(pickup_location);
}
if (typeof dropoff_location === 'string' && !dropoff_location.includes(',')) {
dropoffAddress = await googleMapsService.geocodeAddress(dropoff_location);
}
} catch (geocodeError) {
}
const routeType = recommendedRoute.type || 'fastest';

const validRouteTypes = ['fastest', 'shortest', 'balanced'];
const normalizedRouteType = routeType.toLowerCase();
if (!validRouteTypes.includes(normalizedRouteType)) {
return res.status(400).json({
success: false,
error: 'Invalid route type',
message: `route_type must be one of: ${validRouteTypes.join(', ')}`
});
}
const toleranceInfo = pricingService.TOLERANCE_THRESHOLDS[normalizedRouteType] || pricingService.TOLERANCE_THRESHOLDS.fastest;
res.status(200).json({
success: true,
service_type: service_type,
route: {
type: routeType,
distance_km: parseFloat(distanceKm.toFixed(2)),
duration_minutes: recommendedRoute.duration_minutes || optimizedRoute.traffic_info.duration_minutes,
duration_in_traffic_minutes: recommendedRoute.duration_in_traffic_minutes || optimizedRoute.traffic_info.duration_in_traffic_minutes,
summary: recommendedRoute.summary || null,
overview_polyline: recommendedRoute.overview_polyline || null,
bounds: recommendedRoute.bounds || null
},
traffic: {
has_traffic_data: optimizedRoute.traffic_info.has_traffic_data,
traffic_delay_minutes: optimizedRoute.traffic_info.traffic_delay_minutes,
duration_with_traffic: optimizedRoute.traffic_info.duration_in_traffic_minutes
},
tolerance_info: {
route_type: routeType,
tolerance_percent: toleranceInfo.tolerancePercent,
mandatory: toleranceInfo.mandatory,
reason: toleranceInfo.reason,
message: `Distance changes up to ${toleranceInfo.tolerancePercent}% will not incur additional charges`,
max_price_increase_cap: '50%'
},
pricing: {
basePrice: pricing.basePrice,
gstAmount: pricing.gstAmount,
finalPrice: pricing.finalPrice,
currency: 'INR',
isPeakHours: pricing.isPeakHours,
breakdown: {
basePrice: `₹${pricing.basePrice.toFixed(2)}`,
gst: `₹${pricing.gstAmount.toFixed(2)} (5%)`,
total: `₹${pricing.finalPrice}`
}
},
locations: {
pickup: {
input: pickup_location,
formatted: pickupAddress?.formatted_address || pickup_location,
coordinates: pickupAddress?.location || null
},
dropoff: {
input: dropoff_location,
formatted: dropoffAddress?.formatted_address || dropoff_location,
coordinates: dropoffAddress?.location || null
}
},
alternative_routes: optimizedRoute.routes.length > 1 ? optimizedRoute.routes.slice(1).map(route => ({
type: route.type,
distance_km: route.distance_km,
duration_minutes: route.duration_minutes,
summary: route.summary,
tolerance_percent: pricingService.TOLERANCE_THRESHOLDS[route.type]?.tolerancePercent || null
})) : []
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to get comprehensive route',
message: error.message
});
}
};
module.exports = {
estimateMiniTravelPrice,
estimateAirportDropPrice,
estimateAirportPickupPrice,
estimateHourlyRentalPrice,
estimatePrice,
getRouteOptions,
getComprehensiveRoute
};
