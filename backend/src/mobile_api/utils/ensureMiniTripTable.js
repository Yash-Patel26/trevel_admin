let initPromise = null;
const STATEMENTS = [
`CREATE OR REPLACE FUNCTION update_mini_trip_bookings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
NEW.updated_at = NOW();
RETURN NEW;
END;
$$ LANGUAGE plpgsql;`,
`CREATE TABLE IF NOT EXISTS mini_trip_bookings (
id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
pickup_location TEXT NOT NULL,
pickup_city TEXT,
pickup_state TEXT,
dropoff_location TEXT NOT NULL,
dropoff_city TEXT,
dropoff_state TEXT,
pickup_date DATE NOT NULL,
pickup_time TIME NOT NULL,
make_id UUID REFERENCES makes(id) ON DELETE SET NULL,
make_selected TEXT NOT NULL,
make_image_url TEXT,
passenger_name TEXT NOT NULL,
passenger_email TEXT,
passenger_phone TEXT NOT NULL,
estimated_distance_km NUMERIC(10,2) NOT NULL CHECK (estimated_distance_km >= 0),
estimated_time_min TIME NOT NULL DEFAULT '00:00:00'::time,
base_price NUMERIC(10,2) NOT NULL CHECK (base_price >= 0),
gst_amount NUMERIC(10,2) DEFAULT 0 CHECK (gst_amount >= 0),
final_price NUMERIC(10,2) NOT NULL CHECK (final_price >= 0),
currency TEXT NOT NULL DEFAULT 'INR',
status TEXT NOT NULL DEFAULT 'pending',
notes TEXT,
created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);`,
`ALTER TABLE mini_trip_bookings ADD COLUMN IF NOT EXISTS make_id UUID REFERENCES makes(id) ON DELETE SET NULL;`,
`ALTER TABLE mini_trip_bookings ADD COLUMN IF NOT EXISTS make_selected TEXT;`,
`ALTER TABLE mini_trip_bookings ALTER COLUMN make_selected DROP NOT NULL;`,
`ALTER TABLE mini_trip_bookings ADD COLUMN IF NOT EXISTS make_image_url TEXT;`,
`ALTER TABLE mini_trip_bookings ADD COLUMN IF NOT EXISTS driver_arrival_time TIMESTAMP WITH TIME ZONE;`,
`ALTER TABLE mini_trip_bookings ADD COLUMN IF NOT EXISTS customer_arrival_time TIMESTAMP WITH TIME ZONE;`,
`ALTER TABLE mini_trip_bookings ADD COLUMN IF NOT EXISTS driver_compensation NUMERIC(10,2) DEFAULT 0 CHECK (driver_compensation >= 0);`,
`ALTER TABLE mini_trip_bookings ADD COLUMN IF NOT EXISTS customer_late_fee NUMERIC(10,2) DEFAULT 0 CHECK (customer_late_fee >= 0);`,
`ALTER TABLE mini_trip_bookings ADD COLUMN IF NOT EXISTS original_final_price NUMERIC(10,2);`,
`ALTER TABLE mini_trip_bookings ADD COLUMN IF NOT EXISTS route_preference TEXT DEFAULT 'fastest';`,
`ALTER TABLE mini_trip_bookings ADD COLUMN IF NOT EXISTS promo_code TEXT;`,
`ALTER TABLE mini_trip_bookings ADD COLUMN IF NOT EXISTS promo_discount NUMERIC(10,2) DEFAULT 0 CHECK (promo_discount >= 0);`,
`ALTER TABLE mini_trip_bookings ADD COLUMN IF NOT EXISTS pickup_latitude NUMERIC(10, 8);`,
`ALTER TABLE mini_trip_bookings ADD COLUMN IF NOT EXISTS pickup_longitude NUMERIC(11, 8);`,
`ALTER TABLE mini_trip_bookings ADD COLUMN IF NOT EXISTS dropoff_latitude NUMERIC(10, 8);`,
`ALTER TABLE mini_trip_bookings ADD COLUMN IF NOT EXISTS dropoff_longitude NUMERIC(11, 8);`,
`DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'mini_trip_bookings' AND column_name = 'vehicle_selected') THEN UPDATE mini_trip_bookings SET make_selected = vehicle_selected WHERE (make_selected IS NULL OR make_selected = '') AND vehicle_selected IS NOT NULL; ALTER TABLE mini_trip_bookings ALTER COLUMN vehicle_selected DROP NOT NULL; END IF; END $$;`,
`CREATE INDEX IF NOT EXISTS idx_mini_trip_bookings_user_id ON mini_trip_bookings(user_id);`,
`CREATE INDEX IF NOT EXISTS idx_mini_trip_bookings_status ON mini_trip_bookings(status);`,
`CREATE INDEX IF NOT EXISTS idx_mini_trip_bookings_pickup_date ON mini_trip_bookings(pickup_date);`,
`DROP TRIGGER IF EXISTS trg_update_mini_trip_bookings ON mini_trip_bookings;`,
`CREATE TRIGGER trg_update_mini_trip_bookings
BEFORE UPDATE ON mini_trip_bookings
FOR EACH ROW EXECUTE FUNCTION update_mini_trip_bookings_updated_at();`
];
const ensureMiniTripTableExists = async (db) => {
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
ensureMiniTripTableExists
};
