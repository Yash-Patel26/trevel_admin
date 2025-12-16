const geofencingUtils = require('../utils/geofencingUtils');
const hubService = require('../services/hubService');
const db = require('../config/postgresClient');

const getNearbyHubs = async (req, res) => {
  try {
    const { latitude, longitude, radius_km, active_only } = req.query;

    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        error: 'Missing required parameters',
        message: 'latitude and longitude are required'
      });
    }

    const lat = parseFloat(latitude);
    const lon = parseFloat(longitude);

    if (isNaN(lat) || isNaN(lon)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid coordinates',
        message: 'latitude and longitude must be valid numbers'
      });
    }

    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
      return res.status(400).json({
        success: false,
        error: 'Invalid coordinates',
        message: 'latitude must be between -90 and 90, longitude must be between -180 and 180'
      });
    }

    const searchRadius = radius_km ? parseFloat(radius_km) : 5.0;
    const activeOnly = active_only !== 'false' && active_only !== false;

    const allHubs = await hubService.getAllHubs(db, activeOnly);

    const nearbyHubs = [];
    for (const hub of allHubs) {
      const distance = geofencingUtils.calculateDistanceKm(
        lat,
        lon,
        parseFloat(hub.latitude),
        parseFloat(hub.longitude)
      );

      if (distance !== null && distance <= searchRadius) {
        nearbyHubs.push({
          id: hub.id,
          name: hub.name || '',
          address: hub.address || hub.name || '',
          latitude: parseFloat(hub.latitude),
          longitude: parseFloat(hub.longitude),
          radius_km: parseFloat(hub.radius_km),
          description: hub.description || '',
          is_active: hub.is_active,
          distance_from_user_km: parseFloat(distance.toFixed(2)),
          created_at: hub.created_at,
          updated_at: hub.updated_at
        });
      }
    }

    nearbyHubs.sort((a, b) => a.distance_from_user_km - b.distance_from_user_km);

    res.status(200).json({
      success: true,
      count: nearbyHubs.length,
      data: nearbyHubs,
      search_params: {
        latitude: lat,
        longitude: lon,
        radius_km: searchRadius,
        active_only: activeOnly
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to fetch nearby hubs',
      message: error.message
    });
  }
};

const getAllHubs = async (req, res) => {
  try {
    const { active_only } = req.query;
    const activeOnly = active_only === 'true' || active_only === true;

    const hubs = await hubService.getAllHubs(db, activeOnly);

    res.status(200).json({
      success: true,
      count: hubs.length,
      data: hubs
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to fetch hubs',
      message: error.message
    });
  }
};

module.exports = {
  getNearbyHubs,
  getAllHubs
};

