const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth');
const {
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
} = require('../controllers/locationController');
router.get('/saved', authMiddleware, getSavedLocations);
router.get('/saved/:id', authMiddleware, getSavedLocationById);
router.post('/saved', authMiddleware, createSavedLocation);
router.put('/saved/:id', authMiddleware, updateSavedLocation);
router.delete('/saved/:id', authMiddleware, deleteSavedLocation);
router.get('/', authMiddleware, getSavedLocations);
router.post('/', authMiddleware, createSavedLocation);
router.put('/:id', authMiddleware, updateSavedLocation);
router.delete('/:id', authMiddleware, deleteSavedLocation);
router.post('/geocode', geocodeAddress);
router.post('/reverse-geocode', reverseGeocode);
router.get('/autocomplete', getPlaceAutocomplete);
router.get('/place-details', getPlaceDetails);
router.post('/distance', getDistanceWithTraffic);
router.post('/optimized-route', getOptimizedRoute);
module.exports = router;
