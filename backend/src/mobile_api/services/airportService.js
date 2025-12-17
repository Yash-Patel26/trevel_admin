const prisma = require('../../prisma/client').default;

const STATIC_AIRPORTS = [
    {
        id: 'DEL-T1',
        airport_code: 'DEL-T1',
        airport_name: 'Terminal 1',
        city: 'New Delhi',
        country: 'India',
        latitude: 28.5615,
        longitude: 77.1121
    },
    {
        id: 'DEL-T2',
        airport_code: 'DEL-T2',
        airport_name: 'Terminal 2',
        city: 'New Delhi',
        country: 'India',
        latitude: 28.5565,
        longitude: 77.0863
    },
    {
        id: 'DEL-T3',
        airport_code: 'DEL-T3',
        airport_name: 'Terminal 3',
        city: 'New Delhi',
        country: 'India',
        latitude: 28.5555,
        longitude: 77.0843
    }
];

const getAllAirports = async () => {
    // User requested fixed list: Terminal 1, 2, 3 (New Delhi)
    return STATIC_AIRPORTS;
};

const getAirportById = async (id) => {
    const airport = STATIC_AIRPORTS.find(a => a.id === id);
    if (airport) return airport;

    // Fallback to DB if not found in static list (optional)
    try {
        return await prisma.airport.findUnique({
            where: { id: id }
        });
    } catch (error) {
        return null;
    }
};

module.exports = {
    getAllAirports,
    getAirportById
};
