let initPromise = null;

const STATEMENTS = [
  `CREATE TABLE IF NOT EXISTS makes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'sedan',
    capacity INTEGER DEFAULT 4 CHECK (capacity > 0),
    luggage INTEGER DEFAULT 0 CHECK (luggage >= 0),
    base_price NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (base_price >= 0),
    image_url TEXT,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    -- Additional fields for vehicle tracking
    model TEXT,
    number_plate TEXT,
    color TEXT,
    driver_id UUID,
    current_latitude NUMERIC(10, 8),
    current_longitude NUMERIC(11, 8),
    last_tracked_at TIMESTAMP WITH TIME ZONE,
    device_imei TEXT,
    device_name TEXT,
    -- Additional fields for pricing
    seats INTEGER DEFAULT 4,
    service_types TEXT[],
    oem_range_kms NUMERIC(10, 2),
    price_amount NUMERIC(10, 2),
    price_unit TEXT DEFAULT 'per ride',
    eta_text TEXT,
    distance_text TEXT,
    seat_label TEXT,
    category TEXT
  );`,
  `CREATE INDEX IF NOT EXISTS idx_makes_is_active ON makes(is_active);`,
  `CREATE INDEX IF NOT EXISTS idx_makes_type ON makes(type);`,
  `CREATE INDEX IF NOT EXISTS idx_makes_driver_id ON makes(driver_id) WHERE driver_id IS NOT NULL;`,
  `CREATE INDEX IF NOT EXISTS idx_makes_number_plate ON makes(number_plate) WHERE number_plate IS NOT NULL;`,
  `CREATE INDEX IF NOT EXISTS idx_makes_device_imei ON makes(device_imei) WHERE device_imei IS NOT NULL;`
];

const ensureMakesTableExists = async (db) => {
  if (!initPromise) {
    initPromise = (async () => {
      for (const statement of STATEMENTS) {
        try {
          await db.query(statement);
        } catch (error) {
          // Ignore errors for columns that already exist
          if (!error.message.includes('already exists') && !error.message.includes('duplicate')) {
            throw error;
          }
        }
      }
    })().catch((error) => {
      initPromise = null;
      throw error;
    });
  }
  return initPromise;
};

module.exports = {
  ensureMakesTableExists
};

