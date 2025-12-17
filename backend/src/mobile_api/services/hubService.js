const { ensureHubsTable } = require('../utils/ensureHubsTable');
const airportService = require('./airportService');
const crypto = require('crypto');

// Airport terminal hubs configuration (matches createHubCenters.js)
const AIRPORT_TERMINAL_HUBS = [
  {
    name: 'Airport Terminal 1 - New Delhi (DEL)',
    address: 'Terminal 1, Indira Gandhi International Airport, New Delhi',
    latitude: 28.5672,
    longitude: 77.1031,
    radius_km: 2.0,
    description: 'Airport Terminal 1 pickup and drop hub. Used for airport transfers.',
    is_active: true
  },
  {
    name: 'Airport Terminal 2 - New Delhi (DEL)',
    address: 'Terminal 2, Indira Gandhi International Airport, New Delhi',
    latitude: 28.5567,
    longitude: 77.0870,
    radius_km: 2.0,
    description: 'Airport Terminal 2 pickup and drop hub. Used for airport transfers.',
    is_active: true
  },
  {
    name: 'Airport Terminal 3 - New Delhi (DEL)',
    address: 'Terminal 3, Indira Gandhi International Airport, New Delhi',
    latitude: 28.5562,
    longitude: 77.1000,
    radius_km: 2.0,
    description: 'Airport Terminal 3 pickup and drop hub. Used for airport transfers.',
    is_active: true
  }
];

// Ensure airport terminal hubs exist in the database
const ensureAirportTerminalHubs = async (db) => {
  try {
    const tableExists = await ensureHubsTable(db);
    if (!tableExists) {
      return false;
    }

    for (const terminalHub of AIRPORT_TERMINAL_HUBS) {
      try {
        // Check if hub already exists
        const existing = await db.query(
          'SELECT id FROM hubs WHERE name = $1',
          [terminalHub.name]
        );

        if (existing.rows.length === 0) {
          // Create the hub
          const hubId = crypto.randomUUID();
          await db.query(
            `INSERT INTO hubs (id, name, address, latitude, longitude, radius_km, description, is_active)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
            [
              hubId,
              terminalHub.name,
              terminalHub.address,
              terminalHub.latitude,
              terminalHub.longitude,
              terminalHub.radius_km,
              terminalHub.description,
              terminalHub.is_active
            ]
          );
          console.log(`Created airport terminal hub: ${terminalHub.name}`);
        }
      } catch (error) {
        console.error(`Error ensuring terminal hub ${terminalHub.name}:`, error);
        // Continue with other terminals
      }
    }
    return true;
  } catch (error) {
    console.error('Error ensuring airport terminal hubs:', error);
    return false;
  }
};

const getAllHubs = async (db, activeOnly = false) => {
  let hubs = [];
  let dbAvailable = false;

  // Try to fetch from database first
  try {
    const tableExists = await ensureHubsTable(db);
    if (tableExists) {
      // Ensure airport terminal hubs exist
      await ensureAirportTerminalHubs(db);

      // Query matches Prisma schema: Hub model with @@map("hubs")
      // Fields: id (UUID/String), name, address, latitude, longitude, radius_km, description, is_active, created_at, updated_at
      let query = 'SELECT id, name, address, latitude, longitude, radius_km, description, is_active, created_at, updated_at FROM hubs';
      const params = [];

      if (activeOnly) {
        query += ' WHERE is_active = TRUE';
      }

      query += ' ORDER BY created_at DESC';

      const { rows } = await db.query(query, params);
      dbAvailable = true;

      hubs = rows.map(hub => ({
        id: hub.id, // UUID from Prisma
        name: hub.name || '',
        address: hub.address || hub.name || '',
        latitude: parseFloat(hub.latitude) || 0,
        longitude: parseFloat(hub.longitude) || 0,
        radius_km: parseFloat(hub.radius_km) || 0,
        description: hub.description || '',
        is_active: hub.is_active !== undefined ? hub.is_active : true,
        created_at: hub.created_at,
        updated_at: hub.updated_at
      }));
    } else {
      console.warn('Hubs table not available. Will use airport terminals as fallback.');
    }
  } catch (error) {
    console.error('Error fetching hubs from database:', error.message || error);
    // Continue to fallback - don't return early
  }

  // Always include airport terminals as fallback (from airport service)
  // This ensures terminals are always available even if database is down
  try {
    console.log('Fetching airport terminals as fallback...');
    const airports = await airportService.getAllAirports();
    console.log(`Found ${airports.length} airports from airport service`);
    
    const terminalHubs = airports
      .filter(airport => airport.airport_name && airport.airport_name.toLowerCase().includes('terminal'))
      .map(airport => {
        // Check if this terminal already exists in hubs from DB
        const existing = hubs.find(hub => 
          hub.name.toLowerCase().includes(airport.airport_name.toLowerCase()) ||
          hub.name.toLowerCase().includes(airport.airport_code.toLowerCase())
        );

        if (existing) {
          return null; // Skip if already in DB
        }

        // Create hub entry from airport data
        return {
          id: airport.id || `terminal-${airport.airport_code}`,
          name: airport.airport_name,
          address: `${airport.airport_name}, ${airport.city}, ${airport.country}`,
          latitude: airport.latitude,
          longitude: airport.longitude,
          radius_km: 2.0,
          description: `Airport ${airport.airport_name} pickup and drop hub. Used for airport transfers.`,
          is_active: true,
          created_at: new Date(),
          updated_at: new Date()
        };
      })
      .filter(hub => hub !== null); // Remove nulls

    console.log(`Created ${terminalHubs.length} terminal hubs from airport service`);

    // Add terminal hubs that aren't already in the list
    terminalHubs.forEach(terminalHub => {
      const exists = hubs.some(hub => hub.id === terminalHub.id || hub.name === terminalHub.name);
      if (!exists) {
        hubs.push(terminalHub);
        console.log(`Added terminal hub: ${terminalHub.name}`);
      }
    });
  } catch (error) {
    console.error('Error adding airport terminals as fallback:', error);
    // If database also failed, at least return the static terminal hubs
    if (!dbAvailable && hubs.length === 0) {
      console.log('Using static terminal hubs as last resort');
      // Return static terminal hubs as last resort
      hubs = AIRPORT_TERMINAL_HUBS.map(hub => ({
        id: `static-${hub.name.toLowerCase().replace(/\s+/g, '-')}`,
        name: hub.name,
        address: hub.address,
        latitude: hub.latitude,
        longitude: hub.longitude,
        radius_km: hub.radius_km,
        description: hub.description,
        is_active: hub.is_active,
        created_at: new Date(),
        updated_at: new Date()
      }));
    }
  }

  console.log(`getAllHubs returning ${hubs.length} hubs (${hubs.filter(h => h.name.toLowerCase().includes('terminal')).length} terminals)`);

  return hubs;
};

module.exports = {
  getAllHubs,
  ensureAirportTerminalHubs
};

