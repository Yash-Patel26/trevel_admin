let initPromise = null;
const STATEMENTS = [
`CREATE OR REPLACE FUNCTION update_hourly_rental_bookings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
NEW.updated_at = NOW();
RETURN NEW;
END;
$$ LANGUAGE plpgsql;`,
`CREATE TABLE IF NOT EXISTS hourly_rental_bookings (
id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
pickup_location TEXT NOT NULL,
pickup_city TEXT,
pickup_state TEXT,
pickup_date DATE NOT NULL,
pickup_time TIME NOT NULL,
make_id UUID REFERENCES makes(id) ON DELETE SET NULL,
make_selected TEXT NOT NULL,
make_image_url TEXT,
passenger_name TEXT NOT NULL,
passenger_email TEXT,
passenger_phone TEXT NOT NULL,
rental_hours NUMERIC(5,2) NOT NULL CHECK (rental_hours > 0),
covered_distance_km NUMERIC(10,2) NOT NULL CHECK (covered_distance_km >= 0),
base_price NUMERIC(10,2) NOT NULL CHECK (base_price >= 0),
gst_amount NUMERIC(10,2) DEFAULT 0 CHECK (gst_amount >= 0),
final_price NUMERIC(10,2) NOT NULL CHECK (final_price >= 0),
currency TEXT NOT NULL DEFAULT 'INR',
notes TEXT,
status TEXT NOT NULL DEFAULT 'pending',
created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);`,
`ALTER TABLE hourly_rental_bookings ADD COLUMN IF NOT EXISTS make_id UUID REFERENCES makes(id) ON DELETE SET NULL;`,
`ALTER TABLE hourly_rental_bookings ADD COLUMN IF NOT EXISTS make_selected TEXT;`,
`ALTER TABLE hourly_rental_bookings ALTER COLUMN make_selected DROP NOT NULL;`,
// Handle old vehicle_selected column - migrate data if needed
`DO $$
BEGIN
  -- If vehicle_selected exists but make_selected doesn't have data, copy it
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'hourly_rental_bookings' AND column_name = 'vehicle_selected')
     AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'hourly_rental_bookings' AND column_name = 'make_selected') THEN
    UPDATE hourly_rental_bookings 
    SET make_selected = vehicle_selected 
    WHERE (make_selected IS NULL OR make_selected = '') AND vehicle_selected IS NOT NULL;
  END IF;
END $$;`,
// Ensure vehicle_selected is not null if it exists (for backward compatibility)
`DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'hourly_rental_bookings' AND column_name = 'vehicle_selected') THEN
    ALTER TABLE hourly_rental_bookings ALTER COLUMN vehicle_selected DROP NOT NULL;
  END IF;
END $$;`,
`ALTER TABLE hourly_rental_bookings ADD COLUMN IF NOT EXISTS make_image_url TEXT;`,
`ALTER TABLE hourly_rental_bookings ADD COLUMN IF NOT EXISTS extension_minutes INTEGER DEFAULT 0 CHECK (extension_minutes >= 0);`,
`ALTER TABLE hourly_rental_bookings ADD COLUMN IF NOT EXISTS airport_visits_count INTEGER DEFAULT 0 CHECK (airport_visits_count >= 0);`,
`ALTER TABLE hourly_rental_bookings ADD COLUMN IF NOT EXISTS extension_charge NUMERIC(10,2) DEFAULT 0 CHECK (extension_charge >= 0);`,
`ALTER TABLE hourly_rental_bookings ADD COLUMN IF NOT EXISTS airport_visit_charge NUMERIC(10,2) DEFAULT 0 CHECK (airport_visit_charge >= 0);`,
`ALTER TABLE hourly_rental_bookings ADD COLUMN IF NOT EXISTS original_final_price NUMERIC(10,2);`,
`ALTER TABLE hourly_rental_bookings ADD COLUMN IF NOT EXISTS route_preference TEXT DEFAULT 'shortest';`,
`ALTER TABLE hourly_rental_bookings ADD COLUMN IF NOT EXISTS promo_code TEXT;`,
`ALTER TABLE hourly_rental_bookings ADD COLUMN IF NOT EXISTS promo_discount NUMERIC(10,2) DEFAULT 0 CHECK (promo_discount >= 0);`,
`ALTER TABLE hourly_rental_bookings ADD COLUMN IF NOT EXISTS pickup_latitude NUMERIC(10, 8);`,
`ALTER TABLE hourly_rental_bookings ADD COLUMN IF NOT EXISTS pickup_longitude NUMERIC(11, 8);`,
`CREATE INDEX IF NOT EXISTS idx_hourly_rental_bookings_user_id ON hourly_rental_bookings(user_id);`,
`CREATE INDEX IF NOT EXISTS idx_hourly_rental_bookings_status ON hourly_rental_bookings(status);`,
`CREATE INDEX IF NOT EXISTS idx_hourly_rental_bookings_pickup_date ON hourly_rental_bookings(pickup_date);`,
`DROP TRIGGER IF EXISTS trg_update_hourly_rental_bookings ON hourly_rental_bookings;`,
`CREATE TRIGGER trg_update_hourly_rental_bookings
BEFORE UPDATE ON hourly_rental_bookings
FOR EACH ROW EXECUTE FUNCTION update_hourly_rental_bookings_updated_at();`
];
const ensureHourlyRentalTableExists = async (db) => {
if (!initPromise) {
initPromise = (async () => {
for (const statement of STATEMENTS) {
await db.query(statement);
}
})().catch((error) => {
initPromise = null;
throw error;
});
}
return initPromise;
};
module.exports = {
ensureHourlyRentalTableExists
};
