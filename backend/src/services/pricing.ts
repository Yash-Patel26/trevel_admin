
// Constants
export const GST_RATE = 0.05;

interface PricingTier {
    minKm: number;
    maxKm: number;
    peakBasePrice: number;
    nonPeakBasePrice: number;
}

const MINI_TRAVEL_PRICING: PricingTier[] = [
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

export const TOLERANCE_THRESHOLDS: Record<string, { tolerancePercent: number; mandatory: boolean; reason: string }> = {
    fastest: { tolerancePercent: 30, mandatory: true, reason: 'Protects customers from traffic variations' },
    shortest: { tolerancePercent: 20, mandatory: true, reason: 'Shorter routes are more predictable' },
    balanced: { tolerancePercent: 15, mandatory: true, reason: 'Most strict for balanced routes' }
};

export const MAX_PRICE_INCREASE_CAP = 0.50;

const AIRPORT_PRICING = {
    drop: { basePrice: 951.43, totalPrice: 999 },
    pickup: { basePrice: 1189.52, totalPrice: 1249 }
};

export const HOURLY_RENTAL_PRICING: Record<number, { basePrice: number; totalPrice: number }> = {
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

// Functions

export function isPeakHours(time: string | Date, serviceType: "miniTravel" | "airport" = 'miniTravel'): boolean {
    let hour: number;
    if (typeof time === 'string') {
        const timeMatch = time.match(/^(\d{2}):(\d{2})/);
        if (!timeMatch) return false;
        hour = parseInt(timeMatch[1], 10);
    } else if (time instanceof Date) {
        hour = time.getUTCHours(); // Use UTC or Local? Mobile backend was using getHours() which depends on env timezone. Usually UTC in cloud.
        // TODO: Verify timezone handling. Assuming UTC for now if Date object.
    } else {
        return false;
    }

    if (hour < 0 || hour > 23) return false;
    const peakHoursRanges = PEAK_HOURS[serviceType] || PEAK_HOURS.miniTravel;
    return peakHoursRanges.some(range => {
        return (range.start <= range.end)
            ? (hour >= range.start && hour < range.end)
            : (hour >= range.start || hour < range.end);
    });
}

function calculateGST(basePrice: number): number {
    return Math.round((basePrice * GST_RATE) * 100) / 100;
}

export function calculateMiniTravelPrice(distanceKm: number, pickupTime: Date | string) {
    if (!distanceKm || distanceKm <= 0) throw new Error('Distance must be greater than 0');

    const isPeak = isPeakHours(pickupTime, 'miniTravel');
    let basePrice = 0;
    let gstAmount = 0;
    let finalPrice = 0;

    if (distanceKm <= 30) {
        const pricingTier = MINI_TRAVEL_PRICING.find(tier => distanceKm >= tier.minKm && distanceKm <= tier.maxKm);
        if (!pricingTier) throw new Error(`No pricing tier found for distance: ${distanceKm} km`);

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

// ... Additional exports for Airport/Hourly if needed ...
export function calculateAirportDropPrice(pickupTime: Date | string) {
    const isPeak = isPeakHours(pickupTime, 'airport');
    // Mobile backend apparently used flat rates for airport but we have structure.
    // Based on AIRPORT_PRICING constant:
    const { basePrice, totalPrice } = AIRPORT_PRICING.drop;
    const gstAmount = Math.round((totalPrice - basePrice) * 100) / 100;

    return {
        basePrice,
        gstAmount,
        finalPrice: totalPrice,
        isPeakHours: isPeak
    };
}

export function calculateAirportPickupPrice(pickupTime: Date | string) {
    const isPeak = isPeakHours(pickupTime, 'airport');
    const { basePrice, totalPrice } = AIRPORT_PRICING.pickup;
    const gstAmount = Math.round((totalPrice - basePrice) * 100) / 100;

    return {
        basePrice,
        gstAmount,
        finalPrice: totalPrice,
        isPeakHours: isPeak
    };
}

export function calculateHourlyRentalPrice(hours: number) {
    // Round up to nearest hour or handle half hours? Mobile backend key is explicit integer.
    const hourKey = Math.ceil(hours);
    const pricing = HOURLY_RENTAL_PRICING[hourKey]; // What if > 12?

    if (!pricing) {
        // Fallback or error? Logic from mobile backend implies explicit keys.
        // If not found, maybe max out or throw. 
        // For now, defaulting to max or throwing.
        throw new Error(`Pricing not available for ${hours} hours`);
    }

    const { basePrice, totalPrice } = pricing;
    const gstAmount = Math.round((totalPrice - basePrice) * 100) / 100;

    return {
        basePrice,
        gstAmount,
        finalPrice: totalPrice
    };
}

export const pricingService = {
    calculateMiniTravelPrice,
    calculateAirportDropPrice,
    calculateAirportPickupPrice,
    calculateHourlyRentalPrice,
    TOLERANCE_THRESHOLDS,
    MAX_PRICE_INCREASE_CAP
};
