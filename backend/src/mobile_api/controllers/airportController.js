const airportService = require('../services/airportService');
const pricingService = require('../services/pricingService');
const vehicleService = require('../services/vehicleService');
const db = require('../config/postgresClient');

const getAirports = async (req, res) => {
    try {
        const airports = await airportService.getAllAirports();
        res.status(200).json({
            success: true,
            count: airports.length,
            data: airports
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to fetch airports',
            message: error.message
        });
    }
};

const getAirportById = async (req, res) => {
    try {
        const { id } = req.params;
        const airport = await airportService.getAirportById(id);
        if (!airport) {
            return res.status(404).json({
                success: false,
                error: 'Airport not found'
            });
        }
        res.status(200).json({
            success: true,
            data: airport
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to fetch airport',
            message: error.message
        });
    }
};

const getTransferOptions = async (req, res) => {
    try {
        const { airport_id, transfer_type, pickup_date, pickup_time } = req.body;

        // Default to 'to_airport' (drop) if not specified
        const type = transfer_type || 'to_airport';

        // Calculate price based on type
        // Note: pricingService uses fixed pricing for airport transfers currently
        // We pass current time if pickup_time is not provided, though ideally it should be provided
        const pricingTime = pickup_time ? new Date(`2000-01-01T${pickup_time}`) : new Date();

        let pricing;
        if (type === 'from_airport') {
            pricing = pricingService.calculateAirportPickupPrice(pricingTime);
        } else {
            pricing = pricingService.calculateAirportDropPrice(pricingTime);
        }

        // Fetch available vehicle types from DB (or use static fallback)
        // For now, we construct a standard "Sedan" option as that matches the single-tier pricing
        const vehicleOption = {
            id: 'sedan-standard',
            name: 'Sedan',
            seats: 4,
            luggage: 2,
            image: 'https://trevel-assets.s3.ap-south-1.amazonaws.com/sedan.png', // Placeholder URL or from DB
            price: pricing.finalPrice,
            base_price: pricing.basePrice,
            tax: pricing.gstAmount,
            currency: 'INR',
            description: 'Comfortable sedan for airport transfer',
            eta: '5 mins'
        };

        // We can add SUV if we want, with a multiplier?
        // For now, return single option to be safe
        const options = [vehicleOption];

        res.status(200).json({
            success: true,
            data: options
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to fetch transfer options',
            message: error.message
        });
    }
};

module.exports = {
    getAirports,
    getAirportById,
    getTransferOptions
};
