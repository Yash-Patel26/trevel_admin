const GST_RATE = 0.05;
const MINI_TRAVEL_PRICING = [
{ minKm: 0.1, maxKm: 5, peakBasePrice: 189.52, nonPeakBasePrice: 189.52 },
{ minKm: 5.1, maxKm: 8, peakBasePrice: 284.76, nonPeakBasePrice: 237.14 },
{ minKm: 8.1, maxKm: 12, peakBasePrice: 380.00, nonPeakBasePrice: 284.76 },
{ minKm: 12.1, maxKm: 15, peakBasePrice: 475.24, nonPeakBasePrice: 380.00 },
{ minKm: 15.1, maxKm: 18, peakBasePrice: 570.48, nonPeakBasePrice: 475.24 },
{ minKm: 18.1, maxKm: 21, peakBasePrice: 665.71, nonPeakBasePrice: 570.48 },
{ minKm: 21.1, maxKm: 25, peakBasePrice: 760.95, nonPeakBasePrice: 665.71 },
{ minKm: 25.5, maxKm: 30, peakBasePrice: 856.19, nonPeakBasePrice: 760.95 }
];
const MINI_TRAVEL_BEYOND_30KM = {
peak: { perKmRate: 25, baseCharge: 299 },
nonPeak: { perKmRate: 20, baseCharge: 299 }
};
const PEAK_HOURS = {
miniTravel: [
{ start: 8, end: 11 },
{ start: 17, end: 21 }
],
airport: [
{ start: 8, end: 11 },
{ start: 16, end: 22 }
]
};
const TOLERANCE_THRESHOLDS = {
fastest: {
tolerancePercent: 30,
mandatory: true,
reason: 'Protects customers from traffic variations'
},
shortest: {
tolerancePercent: 20,
mandatory: true,
reason: 'Shorter routes are more predictable'
},
balanced: {
tolerancePercent: 15,
mandatory: true,
reason: 'Most strict for balanced routes'
}
};
const MAX_PRICE_INCREASE_CAP = 0.50;
const AIRPORT_PRICING = {
drop: {
basePrice: 951.43,
totalPrice: 999
},
pickup: {
basePrice: 1189.52,
totalPrice: 1249
}
};
const HOURLY_RENTAL_PRICING = {
2: { basePrice: 951.43, totalPrice: 999 },
3: { basePrice: 1427.62, totalPrice: 1499 },
4: { basePrice: 1903.81, totalPrice: 1999 },
5: { basePrice: 2380.00, totalPrice: 2499 },
6: { basePrice: 2856.19, totalPrice: 2999 },
7: { basePrice: 3332.38, totalPrice: 3499 },
8: { basePrice: 3808.57, totalPrice: 3999 },
9: { basePrice: 4284.76, totalPrice: 4499 },
10: { basePrice: 4760.95, totalPrice: 4999 },
11: { basePrice: 5237.14, totalPrice: 5499 },
12: { basePrice: 5713.33, totalPrice: 5999 }
};
function isPeakHours(time, serviceType = 'miniTravel') {
let hour;
if (typeof time === 'string') {
const timeMatch = time.match(/^(\d{2}):(\d{2})/);
if (!timeMatch) {
return false;
}
hour = parseInt(timeMatch[1], 10);
} else if (time instanceof Date) {
hour = time.getHours();
} else {
return false;
}
if (hour < 0 || hour > 23) {
return false;
}
const peakHoursRanges = PEAK_HOURS[serviceType] || PEAK_HOURS.miniTravel;
return peakHoursRanges.some(range => {
if (range.start <= range.end) {
return hour >= range.start && hour < range.end;
} else {
return hour >= range.start || hour < range.end;
}
});
}
function calculateGST(basePrice) {
return Math.round((basePrice * GST_RATE) * 100) / 100;
}
function calculateMiniTravelPrice(distanceKm, pickupTime) {
if (!distanceKm || distanceKm <= 0) {
throw new Error('Distance must be greater than 0');
}
const isPeak = isPeakHours(pickupTime, 'miniTravel');
let basePrice = 0;
let gstAmount = 0;
let finalPrice = 0;
if (distanceKm <= 30) {
const pricingTier = MINI_TRAVEL_PRICING.find((tier) => {
return distanceKm >= tier.minKm && distanceKm <= tier.maxKm;
});
if (!pricingTier) {
throw new Error(`No pricing tier found for distance: ${distanceKm} km`);
}
basePrice = isPeak ? pricingTier.peakBasePrice : pricingTier.nonPeakBasePrice;
gstAmount = calculateGST(basePrice);
finalPrice = Math.round(basePrice + gstAmount);
} else {
const config = isPeak ? MINI_TRAVEL_BEYOND_30KM.peak : MINI_TRAVEL_BEYOND_30KM.nonPeak;
const billableKm = Math.ceil(distanceKm);
const finalBeforeTax = billableKm * config.perKmRate + config.baseCharge;
const baseRaw = finalBeforeTax / (1 + GST_RATE);
basePrice = Math.round(baseRaw * 100) / 100;
gstAmount = Math.round((finalBeforeTax - basePrice) * 100) / 100;
finalPrice = Math.round(finalBeforeTax);
}
return {
basePrice,
gstAmount,
finalPrice,
isPeakHours: isPeak,
distanceKm: Math.round(distanceKm * 100) / 100
};
}
function calculateAirportDropPrice(pickupTime) {
const isPeak = isPeakHours(pickupTime, 'airport');
const basePrice = AIRPORT_PRICING.drop.basePrice;
const gstAmount = calculateGST(basePrice);
const finalPrice = AIRPORT_PRICING.drop.totalPrice;
return {
basePrice: basePrice,
gstAmount: gstAmount,
finalPrice: finalPrice,
isPeakHours: isPeak
};
}
function calculateAirportPickupPrice(pickupTime) {
const isPeak = isPeakHours(pickupTime, 'airport');
const basePrice = AIRPORT_PRICING.pickup.basePrice;
const gstAmount = calculateGST(basePrice);
const finalPrice = AIRPORT_PRICING.pickup.totalPrice;
return {
basePrice: basePrice,
gstAmount: gstAmount,
finalPrice: finalPrice,
isPeakHours: isPeak
};
}
function calculateHourlyRentalPrice(hours) {
let rentalHours = Math.round(hours);
if (rentalHours < 2) {
rentalHours = 2;
} else if (rentalHours > 12) {
rentalHours = 12;
}
const pricing = HOURLY_RENTAL_PRICING[rentalHours];
if (!pricing) {
throw new Error(`No pricing found for ${rentalHours} hours. Valid hours: 2-12`);
}
const basePrice = pricing.basePrice;
const gstAmount = calculateGST(basePrice);
const finalPrice = pricing.totalPrice;
return {
basePrice: basePrice,
gstAmount: gstAmount,
finalPrice: finalPrice,
hours: rentalHours
};
}
function calculateExtensionCharge(extensionMinutes) {
if (!extensionMinutes || extensionMinutes <= 0) {
return {
extensionCharge: 0,
extensionMinutes: 0,
baseExtensionCharge: 0,
extensionGST: 0
};
}
const tenMinuteBlocks = Math.ceil(extensionMinutes / 10);
const extensionCharge = tenMinuteBlocks * 125;
const baseExtensionCharge = Math.round((extensionCharge / (1 + GST_RATE)) * 100) / 100;
const extensionGST = Math.round((extensionCharge - baseExtensionCharge) * 100) / 100;
return {
extensionCharge: extensionCharge,
extensionMinutes: extensionMinutes,
baseExtensionCharge: baseExtensionCharge,
extensionGST: extensionGST
};
}
function calculateAirportVisitCharge(airportVisitsCount) {
if (!airportVisitsCount || airportVisitsCount <= 0) {
return {
airportVisitCharge: 0,
airportVisitsCount: 0,
baseAirportVisitCharge: 0,
airportVisitGST: 0
};
}
const airportVisitCharge = airportVisitsCount * 250;
const baseAirportVisitCharge = Math.round((airportVisitCharge / (1 + GST_RATE)) * 100) / 100;
const airportVisitGST = Math.round((airportVisitCharge - baseAirportVisitCharge) * 100) / 100;
return {
airportVisitCharge: airportVisitCharge,
airportVisitsCount: airportVisitsCount,
baseAirportVisitCharge: baseAirportVisitCharge,
airportVisitGST: airportVisitGST
};
}
function calculateHourlyRentalTotalPrice(baseHours, extensionMinutes = 0, airportVisitsCount = 0) {
const basePricing = calculateHourlyRentalPrice(baseHours);
const extensionPricing = calculateExtensionCharge(extensionMinutes);
const airportPricing = calculateAirportVisitCharge(airportVisitsCount);
const finalPrice = basePricing.finalPrice + extensionPricing.extensionCharge + airportPricing.airportVisitCharge;
return {
basePrice: basePricing.basePrice,
baseGstAmount: basePricing.gstAmount,
baseFinalPrice: basePricing.finalPrice,
extensionCharge: extensionPricing.extensionCharge,
extensionBaseCharge: extensionPricing.baseExtensionCharge,
extensionGST: extensionPricing.extensionGST,
airportVisitCharge: airportPricing.airportVisitCharge,
airportVisitBaseCharge: airportPricing.baseAirportVisitCharge,
airportVisitGST: airportPricing.airportVisitGST,
additionalChargesGST: 0,
finalPrice: Math.round(finalPrice),
hours: basePricing.hours,
extensionMinutes: extensionPricing.extensionMinutes,
airportVisitsCount: airportPricing.airportVisitsCount
};
}
function calculatePrice(serviceType, params) {
const { distanceKm, pickupTime, hours } = params;
switch (serviceType.toLowerCase()) {
case 'minitravel':
case 'mini_travel':
case 'mini-travel':
if (!distanceKm || !pickupTime) {
throw new Error('distanceKm and pickupTime are required for Mini Travel pricing');
}
return calculateMiniTravelPrice(distanceKm, pickupTime);
case 'airportdrop':
case 'airport_drop':
case 'airport-drop':
case 'to_airport':
if (!pickupTime) {
throw new Error('pickupTime is required for Airport Drop pricing');
}
return calculateAirportDropPrice(pickupTime);
case 'airportpickup':
case 'airport_pickup':
case 'airport-pickup':
case 'from_airport':
if (!pickupTime) {
throw new Error('pickupTime is required for Airport Pickup pricing');
}
return calculateAirportPickupPrice(pickupTime);
case 'hourlyrental':
case 'hourly_rental':
case 'hourly-rental':
if (!hours) {
throw new Error('hours is required for Hourly Rental pricing');
}
return calculateHourlyRentalPrice(hours);
default:
throw new Error(`Unknown service type: ${serviceType}`);
}
}
function calculateTripStartPriceAdjustment({
bookingDistanceKm,
tripStartDistanceKm,
bookingPrice,
pickupTime,
routeType = 'fastest',
serviceType = 'miniTravel'
}) {
if (!bookingDistanceKm || bookingDistanceKm <= 0) {
throw new Error('bookingDistanceKm must be greater than 0');
}
if (!tripStartDistanceKm || tripStartDistanceKm <= 0) {
throw new Error('tripStartDistanceKm must be greater than 0');
}
if (!bookingPrice || bookingPrice <= 0) {
throw new Error('bookingPrice must be greater than 0');
}
const normalizedRouteType = routeType.toLowerCase();
if (!['fastest', 'shortest', 'balanced'].includes(normalizedRouteType)) {
throw new Error('routeType must be: fastest, shortest, or balanced');
}
const tolerance = TOLERANCE_THRESHOLDS[normalizedRouteType];
if (!tolerance) {
throw new Error(`Invalid route type: ${routeType}`);
}
const distanceChangeKm = tripStartDistanceKm - bookingDistanceKm;
const percentageChange = (distanceChangeKm / bookingDistanceKm) * 100;
const result = {
bookingDistanceKm: parseFloat(bookingDistanceKm.toFixed(2)),
tripStartDistanceKm: parseFloat(tripStartDistanceKm.toFixed(2)),
distanceChangeKm: parseFloat(distanceChangeKm.toFixed(2)),
percentageChange: parseFloat(percentageChange.toFixed(2)),
routeType: normalizedRouteType,
tolerancePercent: tolerance.tolerancePercent,
bookingPrice: bookingPrice,
tripStartPrice: bookingPrice,
additionalCharge: 0,
withinTolerance: null,
result: 'No charge',
status: 'OK',
reason: ''
};
if (distanceChangeKm < 0) {
result.withinTolerance = 'N/A';
result.result = 'Customer benefits (shorter route)';
result.status = 'OK';
result.reason = `Distance decreased by ${Math.abs(distanceChangeKm).toFixed(2)} km (${Math.abs(percentageChange).toFixed(2)}%). Customer pays original price.`;
return result;
}
if (distanceChangeKm === 0) {
result.withinTolerance = 'Yes';
result.result = 'No charge';
result.status = 'OK';
result.reason = 'Distance unchanged. No price adjustment.';
return result;
}
const withinTolerance = percentageChange <= tolerance.tolerancePercent;
result.withinTolerance = withinTolerance ? 'Yes' : 'No';
if (withinTolerance) {
result.result = 'No charge (within tolerance)';
result.status = 'OK';
result.reason = `Distance increased by ${distanceChangeKm.toFixed(2)} km (${percentageChange.toFixed(2)}%) is within ${tolerance.tolerancePercent}% tolerance. No additional charge.`;
return result;
}
let newPricing;
try {
if (serviceType === 'miniTravel' || serviceType === 'mini_travel') {
newPricing = calculateMiniTravelPrice(tripStartDistanceKm, pickupTime);
} else if (serviceType === 'airportDrop' || serviceType === 'airport_drop') {
result.result = 'No charge (fixed pricing)';
result.status = 'OK';
result.reason = 'Airport drops have fixed pricing. No adjustment for distance changes.';
return result;
} else if (serviceType === 'airportPickup' || serviceType === 'airport_pickup') {
result.result = 'No charge (fixed pricing)';
result.status = 'OK';
result.reason = 'Airport pickups have fixed pricing. No adjustment for distance changes.';
return result;
} else {
throw new Error(`Price adjustment not supported for service type: ${serviceType}`);
}
} catch (error) {
result.result = 'Error calculating price';
result.status = 'ERROR';
result.reason = `Error calculating new price: ${error.message}. Keeping original price.`;
return result;
}
const newPrice = newPricing.finalPrice;
const priceDifference = newPrice - bookingPrice;
const maxAllowedIncrease = bookingPrice * MAX_PRICE_INCREASE_CAP;
let finalPrice = newPrice;
let additionalCharge = priceDifference;
let capped = false;
if (priceDifference > maxAllowedIncrease) {
finalPrice = bookingPrice + maxAllowedIncrease;
additionalCharge = maxAllowedIncrease;
capped = true;
}
result.tripStartPrice = Math.round(finalPrice);
result.additionalCharge = Math.round(additionalCharge);
result.result = 'Price increase';
result.status = 'WARNING';
result.reason = `Distance increased by ${distanceChangeKm.toFixed(2)} km (${percentageChange.toFixed(2)}%) exceeds ${tolerance.tolerancePercent}% tolerance. `;
result.reason += `New price: ₹${newPrice}. `;
if (capped) {
result.reason += `Adjustment capped at +50% (₹${maxAllowedIncrease.toFixed(2)}) to prevent extreme increases. `;
}
result.reason += `Additional charge: ₹${result.additionalCharge}.`;
return result;
}
function checkTolerance(bookingDistanceKm, tripStartDistanceKm, routeType = 'fastest') {
const normalizedRouteType = routeType.toLowerCase();
const tolerance = TOLERANCE_THRESHOLDS[normalizedRouteType];
if (!tolerance) {
throw new Error(`Invalid route type: ${routeType}`);
}
const distanceChangeKm = tripStartDistanceKm - bookingDistanceKm;
const percentageChange = (distanceChangeKm / bookingDistanceKm) * 100;
const withinTolerance = percentageChange <= tolerance.tolerancePercent;
return {
withinTolerance,
percentageChange: parseFloat(percentageChange.toFixed(2)),
tolerancePercent: tolerance.tolerancePercent,
distanceChangeKm: parseFloat(distanceChangeKm.toFixed(2)),
routeType: normalizedRouteType
};
}
function calculateDriverCompensation(scheduledTime, driverArrivalTime) {
const FREE_BUFFER_MINUTES = 10;
const INTERVAL_MINUTES = 5;
const CHARGE_PER_INTERVAL = 50;
const MINIMUM_CHARGE = 50;
const scheduled = scheduledTime instanceof Date ? scheduledTime : new Date(scheduledTime);
let driverArrival = driverArrivalTime instanceof Date ? driverArrivalTime : new Date(driverArrivalTime);
if (isNaN(scheduled.getTime()) || isNaN(driverArrival.getTime())) {
throw new Error('Invalid date format for scheduled time or driver arrival time');
}
const effectiveServiceTime = new Date(scheduled.getTime() + FREE_BUFFER_MINUTES * 60 * 1000);
if (driverArrival.getTime() < effectiveServiceTime.getTime()) {
driverArrival = new Date(effectiveServiceTime);
}
const delayMs = driverArrival.getTime() - effectiveServiceTime.getTime();
const delayMinutes = Math.max(0, Math.floor(delayMs / (1000 * 60)));
if (delayMinutes <= 0) {
return {
compensation: 0,
delayMinutes: 0,
compensableMinutes: 0,
intervals: 0
};
}
const compensableMinutes = delayMinutes;
const intervals = Math.ceil(compensableMinutes / INTERVAL_MINUTES);
const compensation = Math.max(MINIMUM_CHARGE, intervals * CHARGE_PER_INTERVAL);
return {
compensation: compensation,
delayMinutes: delayMinutes,
compensableMinutes: compensableMinutes,
intervals: intervals
};
}
function calculateCustomerCompensation(scheduledTime, driverArrivalTime) {
const FREE_BUFFER_MINUTES = 10;
const INTERVAL_MINUTES = 5;
const CHARGE_PER_INTERVAL = 50;
const MINIMUM_CHARGE = 50;
const scheduled = scheduledTime instanceof Date ? scheduledTime : new Date(scheduledTime);
let driverArrival = driverArrivalTime instanceof Date ? driverArrivalTime : new Date(driverArrivalTime);
if (isNaN(scheduled.getTime()) || isNaN(driverArrival.getTime())) {
throw new Error('Invalid date format for scheduled time or driver arrival time');
}
const effectiveServiceTime = new Date(scheduled.getTime() + FREE_BUFFER_MINUTES * 60 * 1000);
if (driverArrival.getTime() <= effectiveServiceTime.getTime()) {
return {
promoAmount: 0,
delayMinutes: 0,
compensableMinutes: 0,
intervals: 0
};
}
const delayMs = driverArrival.getTime() - effectiveServiceTime.getTime();
const delayMinutes = Math.max(0, Math.floor(delayMs / (1000 * 60)));
const compensableMinutes = delayMinutes;
const intervals = Math.ceil(compensableMinutes / INTERVAL_MINUTES);
const promoAmount = Math.max(MINIMUM_CHARGE, intervals * CHARGE_PER_INTERVAL);
return {
promoAmount: promoAmount,
delayMinutes: delayMinutes,
compensableMinutes: compensableMinutes,
intervals: intervals
};
}
function calculateCustomerLateFee(scheduledTime, customerArrivalTime, driverArrivalTime = null) {
const FREE_BUFFER_MINUTES = 10;
const INTERVAL_MINUTES = 5;
const CHARGE_PER_INTERVAL = 50;
const MINIMUM_CHARGE = 50;
const scheduled = scheduledTime instanceof Date ? scheduledTime : new Date(scheduledTime);
const customerArrival = customerArrivalTime instanceof Date ? customerArrivalTime : new Date(customerArrivalTime);
if (isNaN(scheduled.getTime()) || isNaN(customerArrival.getTime())) {
throw new Error('Invalid date format for scheduled time or customer arrival time');
}
const bufferEndTime = new Date(scheduled.getTime() + FREE_BUFFER_MINUTES * 60 * 1000);
const lateMs = customerArrival.getTime() - bufferEndTime.getTime();
const lateMinutes = Math.max(0, Math.floor(lateMs / (1000 * 60)));
if (lateMinutes <= 0) {
return {
lateFee: 0,
lateMinutes: 0,
chargeableIntervals: 0,
bufferEndTime: bufferEndTime
};
}
const chargeableIntervals = Math.ceil(lateMinutes / INTERVAL_MINUTES);
const lateFee = Math.max(MINIMUM_CHARGE, chargeableIntervals * CHARGE_PER_INTERVAL);
return {
lateFee: lateFee,
lateMinutes: lateMinutes,
chargeableIntervals: chargeableIntervals,
bufferEndTime: bufferEndTime
};
}
function calculateMiniTripFinalPrice(scheduledTime, baseFinalPrice, driverArrivalTime = null, customerArrivalTime = null) {
let driverCompensation = 0;
let customerLateFee = 0;
let customerCompensation = 0;
let compensationDetails = null;
let lateFeeDetails = null;
let customerCompensationDetails = null;
if (driverArrivalTime) {
try {
compensationDetails = calculateDriverCompensation(scheduledTime, driverArrivalTime);
driverCompensation = compensationDetails.compensation;
customerCompensationDetails = calculateCustomerCompensation(scheduledTime, driverArrivalTime);
customerCompensation = customerCompensationDetails.promoAmount;
} catch (error) {
}
}
if (customerArrivalTime) {
try {
lateFeeDetails = calculateCustomerLateFee(scheduledTime, customerArrivalTime, driverArrivalTime);
customerLateFee = lateFeeDetails.lateFee;
} catch (error) {
}
}
const finalPrice = Math.max(0, baseFinalPrice - driverCompensation + customerLateFee);
return {
baseFinalPrice: baseFinalPrice,
driverCompensation: driverCompensation,
customerLateFee: customerLateFee,
customerCompensation: customerCompensation,
finalPrice: Math.round(finalPrice),
compensationDetails: compensationDetails,
lateFeeDetails: lateFeeDetails,
customerCompensationDetails: customerCompensationDetails
};
}
module.exports = {
calculatePrice,
calculateMiniTravelPrice,
calculateAirportDropPrice,
calculateAirportPickupPrice,
calculateHourlyRentalPrice,
calculateExtensionCharge,
calculateAirportVisitCharge,
calculateHourlyRentalTotalPrice,
calculateDriverCompensation,
calculateCustomerCompensation,
calculateCustomerLateFee,
calculateMiniTripFinalPrice,
isPeakHours,
calculateGST,
calculateTripStartPriceAdjustment,
checkTolerance,
MINI_TRAVEL_PRICING,
AIRPORT_PRICING,
HOURLY_RENTAL_PRICING,
PEAK_HOURS,
TOLERANCE_THRESHOLDS,
MAX_PRICE_INCREASE_CAP
};
