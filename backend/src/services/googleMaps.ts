import axios from "axios";

// GOOGLE_MAPS_API_KEY from .env

const BASE_URL = 'https://maps.googleapis.com/maps/api';

const getClient = () => axios.create({ baseURL: BASE_URL });

export const googleMapsService = {
    getRoutes: async (origin: string, destination: string, options: any = {}) => {
        const apiKey = process.env.GOOGLE_MAPS_API_KEY;
        if (!apiKey) throw new Error("GOOGLE_MAPS_API_KEY missing");

        const params = {
            origin,
            destination,
            key: apiKey,
            mode: 'driving',
            alternatives: true,
            ...options
        };

        const { data } = await getClient().get('/directions/json', { params });
        if (data.status !== 'OK') {
            throw new Error(`Google Maps API error: ${data.status} - ${data.error_message || 'Unknown error'}`);
        }
        return data; // Raw response, caller parses it
    },

    // Simplification: Porting logic helper
    getDistanceWithTraffic: async (origin: string, destination: string, departureTime?: any) => {
        const apiKey = process.env.GOOGLE_MAPS_API_KEY;
        const params: any = {
            origins: origin,
            destinations: destination,
            key: apiKey,
            mode: 'driving',
            departure_time: departureTime ? Math.floor(new Date(departureTime).getTime() / 1000) : 'now',
            traffic_model: 'best_guess'
        };

        const { data } = await getClient().get('/distancematrix/json', { params });
        if (data.status !== 'OK') throw new Error(`Distance Matrix error: ${data.status}`);

        const element = data.rows[0]?.elements[0];
        if (!element || element.status !== 'OK') throw new Error("No route found or API error");

        return {
            distance_km: element.distance.value / 1000,
            duration_minutes: Math.round(element.duration.value / 60),
            duration_in_traffic_minutes: element.duration_in_traffic ? Math.round(element.duration_in_traffic.value / 60) : Math.round(element.duration.value / 60)
        };
    },

    geocodeAddress: async (address: string) => {
        const apiKey = process.env.GOOGLE_MAPS_API_KEY;
        const { data } = await getClient().get('/geocode/json', {
            params: { address, key: apiKey }
        });
        if (data.status !== 'OK' || !data.results.length) throw new Error("Geocoding failed");
        return data.results[0];
    },

    reverseGeocode: async (lat: number, lng: number) => {
        const apiKey = process.env.GOOGLE_MAPS_API_KEY;
        const { data } = await getClient().get('/geocode/json', {
            params: { latlng: `${lat},${lng}`, key: apiKey }
        });
        if (data.status !== 'OK' || !data.results.length) throw new Error("Reverse geocoding failed");
        return data.results[0];
    },

    getPlaceAutocomplete: async (input: string, options: any = {}) => {
        const apiKey = process.env.GOOGLE_MAPS_API_KEY;
        const params = { input, key: apiKey, ...options };
        const { data } = await getClient().get('/place/autocomplete/json', { params });
        if (data.status !== 'OK' && data.status !== 'ZERO_RESULTS') throw new Error("Autocomplete failed");
        return data.predictions || [];
    },

    getPlaceDetails: async (placeId: string) => {
        const apiKey = process.env.GOOGLE_MAPS_API_KEY;
        const { data } = await getClient().get('/place/details/json', {
            params: { place_id: placeId, key: apiKey }
        });
        if (data.status !== 'OK') throw new Error("Place details failed");
        return data.result;
    }
};
