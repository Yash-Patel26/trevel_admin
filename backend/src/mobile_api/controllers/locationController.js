const googleMapsService = require('../services/googleMapsService');
const locationService = require('../services/locationService');
const getSavedLocations = async (req, res) => {
try {
const userId = req.user?.id;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized',
message: 'User authentication required'
});
}
const locations = await locationService.getSavedLocations(userId);
res.status(200).json({
success: true,
count: locations.length,
data: locations
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to fetch saved locations',
message: error.message
});
}
};
const getSavedLocationById = async (req, res) => {
try {
const userId = req.user?.id;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized',
message: 'User authentication required'
});
}
const { id } = req.params;
const location = await locationService.getSavedLocationById(id, userId);
if (!location) {
return res.status(404).json({
success: false,
error: 'Location not found'
});
}
res.status(200).json({
success: true,
data: location
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to fetch saved location',
message: error.message
});
}
};
const createSavedLocation = async (req, res) => {
try {
const userId = req.user?.id;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized',
message: 'User authentication required'
});
}
const { name, address, latitude, longitude, city, state, country, postal_code, is_default } = req.body;
if (!name || !address) {
return res.status(400).json({
success: false,
error: 'Missing required fields',
message: 'name and address are required'
});
}
const location = await locationService.createSavedLocation({
userId,
name,
address,
latitude,
longitude,
city,
state,
country,
postal_code,
is_default
});
res.status(201).json({
success: true,
message: 'Location saved successfully',
data: location
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to create saved location',
message: error.message
});
}
};
const updateSavedLocation = async (req, res) => {
try {
const userId = req.user?.id;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized',
message: 'User authentication required'
});
}
const { id } = req.params;
const { name, address, latitude, longitude, city, state, country, postal_code, is_default } = req.body;
try {
const location = await locationService.updateSavedLocation(id, userId, {
name,
address,
latitude,
longitude,
city,
state,
country,
postal_code,
is_default
});
if (!location) {
return res.status(404).json({
success: false,
error: 'Location not found'
});
}
res.status(200).json({
success: true,
message: 'Location updated successfully',
data: location
});
} catch (error) {
if (error.message.includes('No fields to update')) {
return res.status(400).json({
success: false,
error: 'No fields to update',
message: error.message
});
}
throw error;
}
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to update saved location',
message: error.message
});
}
};
const deleteSavedLocation = async (req, res) => {
try {
const userId = req.user?.id;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized',
message: 'User authentication required'
});
}
const { id } = req.params;
const location = await locationService.deleteSavedLocation(id, userId);
if (!location) {
return res.status(404).json({
success: false,
error: 'Location not found'
});
}
res.status(200).json({
success: true,
message: 'Location deleted successfully'
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to delete saved location',
message: error.message
});
}
};
const geocodeAddress = async (req, res) => {
try {
const { address } = req.body;
if (!address) {
return res.status(400).json({
success: false,
error: 'Missing required field',
message: 'address is required'
});
}
const result = await googleMapsService.geocodeAddress(address);
res.status(200).json({
success: true,
data: result
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to geocode address',
message: error.message
});
}
};
const reverseGeocode = async (req, res) => {
try {
const { lat, lng, latitude, longitude } = req.body;
const latitudeValue = lat || latitude;
const longitudeValue = lng || longitude;
if (!latitudeValue || !longitudeValue) {
return res.status(400).json({
success: false,
error: 'Missing required fields',
message: 'lat/latitude and lng/longitude are required'
});
}
const result = await googleMapsService.reverseGeocode(latitudeValue, longitudeValue);
res.status(200).json({
success: true,
data: result
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to reverse geocode',
message: error.message
});
}
};
const getPlaceAutocomplete = async (req, res) => {
try {
const { input, location, radius, types, components } = req.query;
if (!input) {
return res.status(400).json({
success: false,
error: 'Missing required parameter',
message: 'input is required'
});
}
const options = {};
if (location) {
const [lat, lng] = location.split(',').map(Number);
if (!isNaN(lat) && !isNaN(lng)) {
options.location = { lat, lng };
options.radius = radius ? parseInt(radius) : 50000;
}
}
if (types) {
options.types = types;
}
if (components) {
options.components = components;
}
const predictions = await googleMapsService.getPlaceAutocomplete(input, options);
res.status(200).json({
success: true,
count: predictions.length,
data: predictions
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to get autocomplete suggestions',
message: error.message
});
}
};
const getPlaceDetails = async (req, res) => {
try {
const { place_id, placeId } = req.query;
const placeIdValue = place_id || placeId;
if (!placeIdValue) {
return res.status(400).json({
success: false,
error: 'Missing required parameter',
message: 'place_id is required'
});
}
const result = await googleMapsService.getPlaceDetails(placeIdValue);
res.status(200).json({
success: true,
data: result
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to get place details',
message: error.message
});
}
};
const getDistanceWithTraffic = async (req, res) => {
try {
const { origin, destination, departure_time, departureTime } = req.body;
if (!origin || !destination) {
return res.status(400).json({
success: false,
error: 'Missing required fields',
message: 'origin and destination are required'
});
}
const departureTimeValue = departure_time || departureTime;
const result = await googleMapsService.getDistanceWithTraffic(
origin,
destination,
departureTimeValue
);
res.status(200).json({
success: true,
data: result
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to get distance with traffic',
message: error.message
});
}
};
const getOptimizedRoute = async (req, res) => {
try {
const { origin, destination, departure_time, departureTime } = req.body;
if (!origin || !destination) {
return res.status(400).json({
success: false,
error: 'Missing required fields',
message: 'origin and destination are required'
});
}
const departureTimeValue = departure_time || departureTime;
const result = await googleMapsService.getOptimizedRoute(
origin,
destination,
departureTimeValue
);
res.status(200).json({
success: true,
data: result
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to get optimized route',
message: error.message
});
}
};
module.exports = {
getSavedLocations,
getSavedLocationById,
createSavedLocation,
updateSavedLocation,
deleteSavedLocation,
geocodeAddress,
reverseGeocode,
getPlaceAutocomplete,
getPlaceDetails,
getDistanceWithTraffic,
getOptimizedRoute
};
