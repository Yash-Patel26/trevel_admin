let initPromise = null;
const STATEMENTS = [
`CREATE OR REPLACE FUNCTION update_transfer_bookings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
NEW.updated_at = NOW();
RETURN NEW;
END;
$$ LANGUAGE plpgsql;`,
`CREATE TABLE IF NOT EXISTS to_airport_transfer_bookings (
id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
pickup_location TEXT NOT NULL,
pickup_date DATE NOT NULL,
pickup_time TIME NOT NULL,
destination_airport TEXT NOT NULL,
make_id UUID REFERENCES makes(id) ON DELETE SET NULL,
make_selected TEXT,
make_image_url TEXT,
passenger_name TEXT NOT NULL,
passenger_email TEXT,
passenger_phone TEXT,
estimated_distance_km NUMERIC(10,2),
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
`ALTER TABLE to_airport_transfer_bookings DROP COLUMN IF EXISTS pickup_city;`,
`ALTER TABLE to_airport_transfer_bookings DROP COLUMN IF EXISTS pickup_state;`,
`ALTER TABLE to_airport_transfer_bookings ADD COLUMN IF NOT EXISTS make_id UUID REFERENCES makes(id) ON DELETE SET NULL;`,
`ALTER TABLE to_airport_transfer_bookings ADD COLUMN IF NOT EXISTS make_selected TEXT;`,
`ALTER TABLE to_airport_transfer_bookings ADD COLUMN IF NOT EXISTS make_image_url TEXT;`,
`ALTER TABLE to_airport_transfer_bookings ADD COLUMN IF NOT EXISTS original_final_price NUMERIC(10,2);`,
`ALTER TABLE to_airport_transfer_bookings ADD COLUMN IF NOT EXISTS route_preference TEXT DEFAULT 'shortest';`,
`ALTER TABLE to_airport_transfer_bookings ADD COLUMN IF NOT EXISTS promo_code TEXT;`,
`ALTER TABLE to_airport_transfer_bookings ADD COLUMN IF NOT EXISTS promo_discount NUMERIC(10,2) DEFAULT 0 CHECK (promo_discount >= 0);`,
`ALTER TABLE to_airport_transfer_bookings ADD COLUMN IF NOT EXISTS pickup_latitude NUMERIC(10, 8);`,
`ALTER TABLE to_airport_transfer_bookings ADD COLUMN IF NOT EXISTS pickup_longitude NUMERIC(11, 8);`,
`CREATE TABLE IF NOT EXISTS from_airport_transfer_bookings (
id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
pickup_location TEXT NOT NULL,
pickup_date DATE NOT NULL,
pickup_time TIME NOT NULL,
destination_airport TEXT NOT NULL,
make_id UUID REFERENCES makes(id) ON DELETE SET NULL,
make_selected TEXT,
make_image_url TEXT,
passenger_name TEXT NOT NULL,
passenger_email TEXT,
passenger_phone TEXT,
estimated_distance_km NUMERIC(10,2),
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
`ALTER TABLE from_airport_transfer_bookings DROP COLUMN IF EXISTS pickup_city;`,
`ALTER TABLE from_airport_transfer_bookings DROP COLUMN IF EXISTS pickup_state;`,
`ALTER TABLE from_airport_transfer_bookings ADD COLUMN IF NOT EXISTS make_id UUID REFERENCES makes(id) ON DELETE SET NULL;`,
`ALTER TABLE from_airport_transfer_bookings ADD COLUMN IF NOT EXISTS make_selected TEXT;`,
`ALTER TABLE from_airport_transfer_bookings ADD COLUMN IF NOT EXISTS make_image_url TEXT;`,
`ALTER TABLE from_airport_transfer_bookings ADD COLUMN IF NOT EXISTS original_final_price NUMERIC(10,2);`,
`ALTER TABLE from_airport_transfer_bookings ADD COLUMN IF NOT EXISTS route_preference TEXT DEFAULT 'shortest';`,
`ALTER TABLE from_airport_transfer_bookings ADD COLUMN IF NOT EXISTS promo_code TEXT;`,
`ALTER TABLE from_airport_transfer_bookings ADD COLUMN IF NOT EXISTS promo_discount NUMERIC(10,2) DEFAULT 0 CHECK (promo_discount >= 0);`,
`ALTER TABLE from_airport_transfer_bookings ADD COLUMN IF NOT EXISTS pickup_latitude NUMERIC(10, 8);`,
`ALTER TABLE from_airport_transfer_bookings ADD COLUMN IF NOT EXISTS pickup_longitude NUMERIC(11, 8);`,
`CREATE INDEX IF NOT EXISTS idx_to_airport_transfer_user_id ON to_airport_transfer_bookings(user_id);`,
`CREATE INDEX IF NOT EXISTS idx_to_airport_transfer_status ON to_airport_transfer_bookings(status);`,
`CREATE INDEX IF NOT EXISTS idx_to_airport_transfer_pickup_date ON to_airport_transfer_bookings(pickup_date);`,
`CREATE INDEX IF NOT EXISTS idx_from_airport_transfer_user_id ON from_airport_transfer_bookings(user_id);`,
`CREATE INDEX IF NOT EXISTS idx_from_airport_transfer_status ON from_airport_transfer_bookings(status);`,
`CREATE INDEX IF NOT EXISTS idx_from_airport_transfer_pickup_date ON from_airport_transfer_bookings(pickup_date);`,
`DROP TRIGGER IF EXISTS trg_update_to_airport_transfer_bookings ON to_airport_transfer_bookings;`,
`CREATE TRIGGER trg_update_to_airport_transfer_bookings
BEFORE UPDATE ON to_airport_transfer_bookings
FOR EACH ROW EXECUTE FUNCTION update_transfer_bookings_updated_at();`,
`DROP TRIGGER IF EXISTS trg_update_from_airport_transfer_bookings ON from_airport_transfer_bookings;`,
`CREATE TRIGGER trg_update_from_airport_transfer_bookings
BEFORE UPDATE ON from_airport_transfer_bookings
FOR EACH ROW EXECUTE FUNCTION update_transfer_bookings_updated_at();`
];
const ensureTransferTablesExist = async (db) => {
if (!initPromise) {
initPromise = (async () => {
for (const statement of STATEMENTS) {
await db.query(statement);
}
})().catch((err) => {
initPromise = null;
throw err;
});
}
return initPromise;
};
module.exports = {
ensureTransferTablesExist
};
