function generatePromoCode() {
const prefix = 'TREVEL';
const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
let randomPart = '';
for (let i = 0; i < 6; i++) {
randomPart += chars.charAt(Math.floor(Math.random() * chars.length));
}
return `${prefix}${randomPart}`;
}
async function generateUniquePromoCode(db) {
let code = generatePromoCode();
let attempts = 0;
const maxAttempts = 10;
while (attempts < maxAttempts) {
const checkQuery = 'SELECT id FROM promo_codes WHERE code = $1';
const { rows } = await db.query(checkQuery, [code]);
if (rows.length === 0) {
return code;
}
code = generatePromoCode();
attempts++;
}
return `${generatePromoCode()}${Date.now().toString().slice(-4)}`;
}
module.exports = {
generatePromoCode,
generateUniquePromoCode
};
