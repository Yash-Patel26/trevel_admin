let initPromise = null;
const STATEMENTS = [
`CREATE TABLE IF NOT EXISTS promo_codes (
id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
code TEXT NOT NULL UNIQUE,
amount NUMERIC(10,2) NOT NULL CHECK (amount > 0),
booking_id UUID REFERENCES mini_trip_bookings(id) ON DELETE SET NULL,
reason TEXT,
status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'used', 'expired')),
used_at TIMESTAMP WITH TIME ZONE,
expires_at TIMESTAMP WITH TIME ZONE,
created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);`,
`CREATE INDEX IF NOT EXISTS idx_promo_codes_user_id ON promo_codes(user_id);`,
`CREATE INDEX IF NOT EXISTS idx_promo_codes_code ON promo_codes(code);`,
`CREATE INDEX IF NOT EXISTS idx_promo_codes_status ON promo_codes(status);`,
`CREATE OR REPLACE FUNCTION update_promo_codes_updated_at()
RETURNS TRIGGER AS $$
BEGIN
NEW.updated_at = NOW();
RETURN NEW;
END;
$$ LANGUAGE plpgsql;`,
`DROP TRIGGER IF EXISTS trg_update_promo_codes ON promo_codes;`,
`CREATE TRIGGER trg_update_promo_codes
BEFORE UPDATE ON promo_codes
FOR EACH ROW EXECUTE FUNCTION update_promo_codes_updated_at();`
];
const ensurePromoCodesTableExists = async (db) => {
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
ensurePromoCodesTableExists
};
