const crypto = require('crypto');
const sanitizePayload = (payload = {}) =>
Object.entries(payload).reduce((acc, [key, value]) => {
if (value === undefined || value === null || value === '') return acc;
acc[key] = value;
return acc;
}, {});
const serializePayload = (payload = {}) =>
Object.keys(payload)
.sort()
.map((key) => `${key}=${payload[key]}`)
.join('&');
const getMerchantKey = () => {
const key = process.env.ZAAKPAY_MERCHANT_KEY;
if (!key) {
throw new Error('ZAAKPAY_MERCHANT_KEY is not configured');
}
return key;
};
const generateChecksum = (payload, secret = getMerchantKey()) => {
const sanitized = sanitizePayload(payload);
const serialized = serializePayload(sanitized);
return crypto.createHash('sha256').update(`${serialized}${secret}`, 'utf8').digest('hex');
};
const verifyChecksum = (payload = {}, secret) => {
const { checksum, ...rest } = payload;
if (!checksum) return false;
const expected = generateChecksum(rest, secret);
return checksum === expected;
};
module.exports = {
sanitizePayload,
serializePayload,
generateChecksum,
verifyChecksum
};
