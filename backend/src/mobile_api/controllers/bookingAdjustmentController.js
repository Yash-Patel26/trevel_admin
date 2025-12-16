const pricingService = require('../services/pricingService');
const bookingAdjustmentService = require('../services/bookingAdjustmentService');
const updateActualDistance = async (req, res) => {
try {
const { booking_uuid } = req.params;
const { actual_distance_km, actual_time_minutes, route_type, booking_type } = req.body;
if (!actual_distance_km || actual_distance_km < 0) {
return res.status(400).json({
success: false,
error: 'Invalid actual distance',
message: 'actual_distance_km is required and must be >= 0'
});
}
if (!route_type || !['fastest', 'shortest', 'balanced'].includes(route_type)) {
return res.status(400).json({
success: false,
error: 'Invalid route type',
message: 'route_type must be: fastest, shortest, or balanced'
});
}
const bookingResult = await bookingAdjustmentService.findBookingInTables(booking_uuid, booking_type);
if (!bookingResult) {
return res.status(404).json({
success: false,
error: 'Booking not found'
});
}
const { table: tableName, record: bookingRecord } = bookingResult;
const estimatedDistance = parseFloat(bookingRecord.estimated_distance_km || bookingRecord.distance_km || 0);
const originalPrice = parseFloat(bookingRecord.original_final_price || bookingRecord.final_price);
const pickupTime = bookingRecord.pickup_time;
const bookingType = booking_type || (tableName.includes('mini_trip') ? 'mini_trip' :
tableName.includes('to_airport') ? 'to_airport' : 'from_airport');
const serviceType = bookingType === 'mini_trip' ? 'miniTravel' :
bookingType === 'to_airport' ? 'airportDrop' : 'airportPickup';
const adjustmentResult = pricingService.calculateTripStartPriceAdjustment({
bookingDistanceKm: estimatedDistance,
tripStartDistanceKm: actual_distance_km,
bookingPrice: originalPrice,
pickupTime: pickupTime,
routeType: route_type,
serviceType: serviceType
});
const priceAdjusted = adjustmentResult.status === 'WARNING' && adjustmentResult.additionalCharge > 0;
const updated = await bookingAdjustmentService.updateBookingWithActualDistance(
tableName,
booking_uuid,
{
actual_distance_km,
actual_time_minutes,
route_type,
price_adjusted: priceAdjusted,
adjusted_final_price: adjustmentResult.tripStartPrice,
price_adjustment_reason: adjustmentResult.reason,
final_price: adjustmentResult.tripStartPrice
}
);
if (!updated) {
return res.status(404).json({
success: false,
error: 'Failed to update booking'
});
}
res.status(200).json({
success: true,
message: priceAdjusted
? 'Distance updated and price adjusted'
: 'Distance updated (no price adjustment)',
data: {
booking_id: booking_uuid,
booking_distance_km: adjustmentResult.bookingDistanceKm,
trip_start_distance_km: adjustmentResult.tripStartDistanceKm,
distance_change_km: adjustmentResult.distanceChangeKm,
percentage_change: adjustmentResult.percentageChange,
route_type: adjustmentResult.routeType,
tolerance_percent: adjustmentResult.tolerancePercent,
within_tolerance: adjustmentResult.withinTolerance,
booking_price: adjustmentResult.bookingPrice,
trip_start_price: adjustmentResult.tripStartPrice,
additional_charge: adjustmentResult.additionalCharge,
result: adjustmentResult.result,
status: adjustmentResult.status,
reason: adjustmentResult.reason
}
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to update actual distance',
message: error.message
});
}
};
const calculateTripStartPrice = async (req, res) => {
try {
const {
booking_distance_km,
trip_start_distance_km,
booking_price,
pickup_time,
route_type = 'fastest',
service_type = 'miniTravel'
} = req.body;
if (!booking_distance_km || booking_distance_km <= 0) {
return res.status(400).json({
success: false,
error: 'Invalid booking distance',
message: 'booking_distance_km is required and must be > 0'
});
}
if (!trip_start_distance_km || trip_start_distance_km <= 0) {
return res.status(400).json({
success: false,
error: 'Invalid trip start distance',
message: 'trip_start_distance_km is required and must be > 0'
});
}
if (!booking_price || booking_price <= 0) {
return res.status(400).json({
success: false,
error: 'Invalid booking price',
message: 'booking_price is required and must be > 0'
});
}
if (!pickup_time) {
return res.status(400).json({
success: false,
error: 'Missing pickup time',
message: 'pickup_time is required'
});
}
if (!['fastest', 'shortest', 'balanced'].includes(route_type.toLowerCase())) {
return res.status(400).json({
success: false,
error: 'Invalid route type',
message: 'route_type must be: fastest, shortest, or balanced'
});
}
const adjustmentResult = pricingService.calculateTripStartPriceAdjustment({
bookingDistanceKm: booking_distance_km,
tripStartDistanceKm: trip_start_distance_km,
bookingPrice: booking_price,
pickupTime: pickup_time,
routeType: route_type,
serviceType: service_type
});
res.status(200).json({
success: true,
message: adjustmentResult.status === 'WARNING'
? 'Price adjustment required'
: 'No price adjustment needed',
data: adjustmentResult
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to calculate trip start price',
message: error.message
});
}
};
const checkTolerance = async (req, res) => {
try {
const {
booking_distance_km,
trip_start_distance_km,
route_type = 'fastest'
} = req.body;
if (!booking_distance_km || booking_distance_km <= 0) {
return res.status(400).json({
success: false,
error: 'Invalid booking distance',
message: 'booking_distance_km is required and must be > 0'
});
}
if (!trip_start_distance_km || trip_start_distance_km <= 0) {
return res.status(400).json({
success: false,
error: 'Invalid trip start distance',
message: 'trip_start_distance_km is required and must be > 0'
});
}
const toleranceCheck = pricingService.checkTolerance(
booking_distance_km,
trip_start_distance_km,
route_type
);
res.status(200).json({
success: true,
data: toleranceCheck
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to check tolerance',
message: error.message
});
}
};
module.exports = {
updateActualDistance,
calculateTripStartPrice,
checkTolerance
};
