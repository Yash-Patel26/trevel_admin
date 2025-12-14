import prisma from "../prisma/client";
import redisClient from "../config/redis";

// --- Constants (Fallbacks) ---
export const GST_RATE = 0.05;

const MINI_TRAVEL_PRICING_DEFAULT = [
    { minKm: 0.1, maxKm: 5, peakBasePrice: 189.52, nonPeakBasePrice: 189.52 },
    { minKm: 5.1, maxKm: 8, peakBasePrice: 284.76, nonPeakBasePrice: 237.14 },
    { minKm: 8.1, maxKm: 12, peakBasePrice: 380.00, nonPeakBasePrice: 284.76 },
    { minKm: 12.1, maxKm: 15, peakBasePrice: 475.24, nonPeakBasePrice: 380.00 },
    { minKm: 15.1, maxKm: 18, peakBasePrice: 570.48, nonPeakBasePrice: 475.24 },
    { minKm: 18.1, maxKm: 21, peakBasePrice: 665.71, nonPeakBasePrice: 570.48 },
    { minKm: 21.1, maxKm: 25, peakBasePrice: 760.95, nonPeakBasePrice: 665.71 },
    { minKm: 25.5, maxKm: 30, peakBasePrice: 856.19, nonPeakBasePrice: 760.95 }
];

const MINI_TRAVEL_BEYOND_30KM_DEFAULT = {
    peak: { perKmRate: 25, baseCharge: 299 },
    nonPeak: { perKmRate: 20, baseCharge: 299 }
};

const PEAK_HOURS_DEFAULT = {
    miniTravel: [
        { start: 8, end: 11 },
        { start: 17, end: 21 }
    ],
    airport: [
        { start: 8, end: 11 },
        { start: 16, end: 22 }
    ]
};

const AIRPORT_PRICING_DEFAULT = {
    drop: { basePrice: 951.43, totalPrice: 999 },
    pickup: { basePrice: 1189.52, totalPrice: 1249 }
};

const HOURLY_RENTAL_PRICING_DEFAULT: Record<number, { basePrice: number; totalPrice: number }> = {
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

export const TOLERANCE_THRESHOLDS: Record<string, { tolerancePercent: number; mandatory: boolean; reason: string }> = {
    fastest: { tolerancePercent: 30, mandatory: true, reason: 'Protects customers from traffic variations' },
    shortest: { tolerancePercent: 20, mandatory: true, reason: 'Shorter routes are more predictable' },
    balanced: { tolerancePercent: 15, mandatory: true, reason: 'Most strict for balanced routes' }
};

export const MAX_PRICE_INCREASE_CAP = 0.50;

// --- Helper Functions ---

async function getServicePricing(serviceType: string): Promise<any> {
    const cacheKey = `pricing:${serviceType}`;
    try {
        const cached = await redisClient.get(cacheKey);
        if (cached) return JSON.parse(cached);
    } catch (e) {
        // Redis error, proceed to DB
    }

    try {
        const configRecord = await prisma.pricingConfig.findUnique({
            where: { serviceType }
        });

        if (configRecord && configRecord.config) {
            const config = configRecord.config;
            // Cache for 10 minutes
            try { await redisClient.setEx(cacheKey, 600, JSON.stringify(config)); } catch { }
            return config;
        }
    } catch (e) {
        console.error(`DB Error fetching pricing for ${serviceType}`, e);
    }

    // Fallbacks
    if (serviceType === 'mini-travel') return {
        tiers: MINI_TRAVEL_PRICING_DEFAULT,
        beyond30Km: MINI_TRAVEL_BEYOND_30KM_DEFAULT,
        gstRate: GST_RATE,
        peakHours: PEAK_HOURS_DEFAULT.miniTravel
    };
    if (serviceType === 'airport-drop') return { pricing: AIRPORT_PRICING_DEFAULT.drop, gstRate: GST_RATE, peakHours: PEAK_HOURS_DEFAULT.airport };
    if (serviceType === 'airport-pickup') return { pricing: AIRPORT_PRICING_DEFAULT.pickup, gstRate: GST_RATE, peakHours: PEAK_HOURS_DEFAULT.airport };
    if (serviceType === 'hourly-rental') return { packages: HOURLY_RENTAL_PRICING_DEFAULT, gstRate: GST_RATE };

    return null;
}

function getISTHour(time: Date | string): number {
    if (typeof time === 'string') {
        const timeMatch = time.match(/^(\d{2}):(\d{2})/);
        if (!timeMatch) return -1;
        return parseInt(timeMatch[1], 10);
    } else if (time instanceof Date) {
        // IST is UTC+5:30
        const istOffset = 5.5 * 60 * 60 * 1000;
        const istTime = new Date(time.getTime() + istOffset);
        return istTime.getUTCHours();
    }
    return -1;
}

function isPeak(hour: number, ranges: any[]): boolean {
    if (!ranges) return false;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    return ranges.some((range: any) => {
        return (range.start <= range.end)
            ? (hour >= range.start && hour < range.end)
            : (hour >= range.start || hour < range.end);
    });
}

/**
 * Check if the given time is within peak hours.
 * Uses cached config from DB.
 */
export async function isPeakHours(time: string | Date, serviceType: "miniTravel" | "airport" = 'miniTravel'): Promise<boolean> {
    // Map serviceType to simplified keys used in DB config
    const dbKey = serviceType === 'airport' ? 'airport-drop' : 'mini-travel';
    // Note: airport-drop/pickup share peak hours in our default seed, so airport-drop is fine.

    const config = await getServicePricing(dbKey);
    const peakRanges = config.peakHours || (serviceType === 'airport' ? PEAK_HOURS_DEFAULT.airport : PEAK_HOURS_DEFAULT.miniTravel);

    const hour = getISTHour(time);
    return isPeak(hour, peakRanges);
}

function calculateGST(basePrice: number, rate: number = GST_RATE): number {
    return Math.round((basePrice * rate) * 100) / 100;
}

// --- Main Pricing Functions (ASYNC) ---

export async function calculateMiniTravelPrice(distanceKm: number, pickupTime: Date | string) {
    if (!distanceKm || distanceKm <= 0) throw new Error('Distance must be greater than 0');

    const config = await getServicePricing('mini-travel');
    const tiers = config.tiers || MINI_TRAVEL_PRICING_DEFAULT;
    const beyond30 = config.beyond30Km || MINI_TRAVEL_BEYOND_30KM_DEFAULT;
    const peakRanges = config.peakHours || PEAK_HOURS_DEFAULT.miniTravel;
    const gstRate = config.gstRate ?? GST_RATE;

    const hour = getISTHour(pickupTime);
    const isPeakTime = isPeak(hour, peakRanges);

    let basePrice = 0;
    let gstAmount = 0;
    let finalPrice = 0;

    if (distanceKm <= 30) {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const pricingTier = tiers.find((tier: any) => distanceKm >= tier.minKm && distanceKm <= tier.maxKm);
        if (!pricingTier) throw new Error(`No pricing tier found for distance: ${distanceKm} km`);

        basePrice = isPeakTime ? pricingTier.peakBasePrice : pricingTier.nonPeakBasePrice;
        gstAmount = calculateGST(basePrice, gstRate);
        finalPrice = Math.round(basePrice + gstAmount);
    } else {
        const settings = isPeakTime ? beyond30.peak : beyond30.nonPeak;
        const billableKm = Math.ceil(distanceKm);

        const rate = settings.perKmRate;
        const charge = settings.baseCharge;

        const finalBeforeTax = billableKm * rate + charge;
        const baseRaw = finalBeforeTax / (1 + gstRate);
        basePrice = Math.round(baseRaw * 100) / 100;
        gstAmount = Math.round((finalBeforeTax - basePrice) * 100) / 100;
        finalPrice = Math.round(finalBeforeTax);
    }

    return {
        basePrice,
        gstAmount,
        finalPrice,
        isPeakHours: isPeakTime,
        distanceKm: Math.round(distanceKm * 100) / 100
    };
}

export async function calculateAirportDropPrice(pickupTime: Date | string) {
    const config = await getServicePricing('airport-drop');
    const pricing = config.pricing || AIRPORT_PRICING_DEFAULT.drop;
    const peakRanges = config.peakHours || PEAK_HOURS_DEFAULT.airport;
    const gstRate = config.gstRate ?? GST_RATE;

    // Fallback logic if DB config is partial
    // assuming pricing has basePrice/totalPrice

    const hour = getISTHour(pickupTime);
    const isPeakTime = isPeak(hour, peakRanges);

    const { basePrice, totalPrice } = pricing;
    const calculatedGst = Math.round((totalPrice - basePrice) * 100) / 100;

    return {
        basePrice,
        gstAmount: calculatedGst,
        finalPrice: totalPrice,
        isPeakHours: isPeakTime
    };
}

export async function calculateAirportPickupPrice(pickupTime: Date | string) {
    const config = await getServicePricing('airport-pickup');
    const pricing = config.pricing || AIRPORT_PRICING_DEFAULT.pickup;
    const peakRanges = config.peakHours || PEAK_HOURS_DEFAULT.airport;

    const hour = getISTHour(pickupTime);
    const isPeakTime = isPeak(hour, peakRanges);

    const { basePrice, totalPrice } = pricing;
    const calculatedGst = Math.round((totalPrice - basePrice) * 100) / 100;

    return {
        basePrice,
        gstAmount: calculatedGst,
        finalPrice: totalPrice,
        isPeakHours: isPeakTime
    };
}

export async function calculateHourlyRentalPrice(hours: number) {
    const config = await getServicePricing('hourly-rental');
    const packages = config.packages || HOURLY_RENTAL_PRICING_DEFAULT;

    // Round up to nearest hour
    const hourKey = Math.ceil(hours);
    const pricing = packages[hourKey]; // packages is Record<string, ...> in JSON

    if (!pricing) {
        throw new Error(`Pricing not available for ${hours} hours`);
    }

    const { basePrice, totalPrice } = pricing;
    const calculatedGst = Math.round((totalPrice - basePrice) * 100) / 100;

    return {
        basePrice,
        gstAmount: calculatedGst,
        finalPrice: totalPrice
    };
}

export async function getHourlyRentalPackages() {
    const config = await getServicePricing('hourly-rental');
    return config.packages || HOURLY_RENTAL_PRICING_DEFAULT;
}

export const pricingService = {
    calculateMiniTravelPrice,
    calculateAirportDropPrice,
    calculateAirportPickupPrice,
    calculateHourlyRentalPrice,
    isPeakHours,
    getHourlyRentalPackages,
    TOLERANCE_THRESHOLDS,
    MAX_PRICE_INCREASE_CAP
};
