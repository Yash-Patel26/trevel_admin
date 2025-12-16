const promoCodeService = require('../services/promoCodeService');
const validatePromoCode = async (req, res) => {
try {
const userId = req.user?.id;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized',
message: 'User authentication required'
});
}
const { code } = req.body;
if (!code || typeof code !== 'string' || code.trim().length === 0) {
return res.status(400).json({
success: false,
error: 'Missing promo code',
message: 'Promo code is required'
});
}

const promo = await promoCodeService.getPromoCodeByCode(code, userId);
if (!promo) {
return res.status(404).json({
success: false,
error: 'Promo code not found',
message: 'The promo code you entered does not exist or does not belong to you.',
valid: false
});
}
const now = new Date();
if (promo.status === 'used' || promo.used_at) {
return res.status(400).json({
success: false,
error: 'Promo code already used',
message: 'This promo code has already been used.',
valid: false,
details: {
code: promo.code,
amount: parseFloat(promo.amount),
usedAt: promo.used_at
}
});
}
if (promo.expires_at && new Date(promo.expires_at) < now) {

await promoCodeService.markPromoCodeAsExpired(promo.id);
return res.status(400).json({
success: false,
error: 'Promo code expired',
message: 'This promo code has expired.',
valid: false,
details: {
code: promo.code,
amount: parseFloat(promo.amount),
expiresAt: promo.expires_at
}
});
}
if (promo.status !== 'active') {
return res.status(400).json({
success: false,
error: 'Promo code not active',
message: 'This promo code is not active.',
valid: false,
details: {
code: promo.code,
status: promo.status
}
});
}
return res.status(200).json({
success: true,
valid: true,
message: 'Promo code is valid',
data: {
code: promo.code,
amount: parseFloat(promo.amount),
expiresAt: promo.expires_at,
createdAt: promo.created_at
}
});
} catch (error) {
return res.status(500).json({
success: false,
error: 'Failed to validate promo code',
message: error.message
});
}
};
const calculatePromoDiscount = async (req, res) => {
try {
const userId = req.user?.id;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized',
message: 'User authentication required'
});
}
const { code, booking_amount } = req.body;
if (!code || typeof code !== 'string' || code.trim().length === 0) {
return res.status(400).json({
success: false,
error: 'Missing promo code',
message: 'Promo code is required'
});
}
if (!booking_amount || isNaN(parseFloat(booking_amount)) || parseFloat(booking_amount) <= 0) {
return res.status(400).json({
success: false,
error: 'Invalid booking amount',
message: 'Valid booking amount is required'
});
}

const promoCode = code.trim().toUpperCase();
const bookingAmount = parseFloat(booking_amount);
const promo = await promoCodeService.getPromoCodeByCode(code, userId);
if (!promo) {
return res.status(404).json({
success: false,
error: 'Promo code not found',
message: 'The promo code you entered does not exist or does not belong to you.'
});
}
const now = new Date();
if (promo.status === 'used' || promo.used_at) {
return res.status(400).json({
success: false,
error: 'Promo code already used',
message: 'This promo code has already been used.'
});
}
if (promo.expires_at && new Date(promo.expires_at) < now) {
return res.status(400).json({
success: false,
error: 'Promo code expired',
message: 'This promo code has expired.'
});
}
if (promo.status !== 'active') {
return res.status(400).json({
success: false,
error: 'Promo code not active',
message: 'This promo code is not active.'
});
}
const promoAmount = parseFloat(promo.amount);
const discountAmount = Math.min(promoAmount, bookingAmount);
const finalAmount = Math.max(0, bookingAmount - discountAmount);
return res.status(200).json({
success: true,
message: 'Discount calculated successfully',
data: {
promoCode: promo.code,
promoAmount: promoAmount,
originalAmount: bookingAmount,
discountAmount: discountAmount,
finalAmount: finalAmount,
savings: discountAmount
}
});
} catch (error) {
return res.status(500).json({
success: false,
error: 'Failed to calculate discount',
message: error.message
});
}
};
const applyPromoCodeToBooking = async (req, res) => {
try {
const userId = req.user?.id;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized',
message: 'User authentication required'
});
}
const { id } = req.params;
const { code } = req.body;
if (!code || typeof code !== 'string' || code.trim().length === 0) {
return res.status(400).json({
success: false,
error: 'Missing promo code',
message: 'Promo code is required'
});
}

const promoCode = code.trim().toUpperCase();
const promo = await promoCodeService.getPromoCodeByCode(code, userId);
if (!promo) {
return res.status(404).json({
success: false,
error: 'Promo code not found',
message: 'The promo code you entered does not exist or does not belong to you.'
});
}
const now = new Date();
if (promo.status === 'used' || promo.used_at) {
return res.status(400).json({
success: false,
error: 'Promo code already used',
message: 'This promo code has already been used.'
});
}
if (promo.expires_at && new Date(promo.expires_at) < now) {
return res.status(400).json({
success: false,
error: 'Promo code expired',
message: 'This promo code has expired.'
});
}
if (promo.status !== 'active') {
return res.status(400).json({
success: false,
error: 'Promo code not active',
message: 'This promo code is not active.'
});
}

const bookingResult = await promoCodeService.findBookingInTables(id, userId);
if (!bookingResult) {
return res.status(404).json({
success: false,
error: 'Booking not found',
message: 'Booking not found or does not belong to you.'
});
}
const { booking, table: tableName, type: bookingType } = bookingResult;
const bookingStatus = (booking.status || '').toLowerCase();
if (!['pending', 'confirmed'].includes(bookingStatus)) {
return res.status(400).json({
success: false,
error: 'Cannot apply promo code',
message: `Promo code can only be applied to pending or confirmed bookings. Current status: ${bookingStatus}`
});
}
const currentPrice = parseFloat(booking.final_price || booking.original_final_price || 0);
const promoAmount = parseFloat(promo.amount);
const discountAmount = Math.min(promoAmount, currentPrice);
const newFinalPrice = Math.max(0, currentPrice - discountAmount);

const updatedBooking = await promoCodeService.applyPromoCodeToBooking(
promo.id,
id,
promoCode,
discountAmount,
newFinalPrice,
userId,
tableName
);
if (!updatedBooking) {
return res.status(404).json({
success: false,
error: 'Booking not found',
message: 'Booking not found or does not belong to you.'
});
}
return res.status(200).json({
success: true,
message: 'Promo code applied successfully',
data: {
bookingId: id,
bookingType: bookingType,
promoCode: promoCode,
originalPrice: currentPrice,
discountAmount: discountAmount,
finalPrice: newFinalPrice,
savings: discountAmount
}
});
} catch (error) {
return res.status(500).json({
success: false,
error: 'Failed to apply promo code',
message: error.message
});
}
};
module.exports = {
validatePromoCode,
calculatePromoDiscount,
applyPromoCodeToBooking
};
