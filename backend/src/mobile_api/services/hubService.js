const getAllHubs = async (db, activeOnly = false) => {
  let query = 'SELECT id, name, address, latitude, longitude, radius_km, description, is_active, created_at, updated_at FROM hubs';
  const params = [];

  if (activeOnly) {
    query += ' WHERE is_active = TRUE';
  }

  query += ' ORDER BY created_at DESC';

  const { rows } = await db.query(query, params);

  return rows.map(hub => ({
    id: hub.id,
    name: hub.name || '',
    address: hub.address || hub.name || '',
    latitude: parseFloat(hub.latitude),
    longitude: parseFloat(hub.longitude),
    radius_km: parseFloat(hub.radius_km),
    description: hub.description || '',
    is_active: hub.is_active,
    created_at: hub.created_at,
    updated_at: hub.updated_at
  }));
};

module.exports = {
  getAllHubs
};

