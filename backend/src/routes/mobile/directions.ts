import { Router } from 'express';
import axios from 'axios';

const router = Router();

// Google Directions API endpoint
router.get('/directions', async (req, res) => {
    try {
        const { origin, destination } = req.query;

        if (!origin || !destination) {
            return res.status(400).json({
                success: false,
                error: 'Origin and destination are required'
            });
        }

        const GOOGLE_MAPS_API_KEY = process.env.GOOGLE_MAPS_API_KEY || 'AIzaSyDfhpRHmEWEoxr0Opgu84Pm3Ob9ecLJUHg';

        // Call Google Directions API
        const response = await axios.get('https://maps.googleapis.com/maps/api/directions/json', {
            params: {
                origin,
                destination,
                key: GOOGLE_MAPS_API_KEY,
                mode: 'driving'
            }
        });

        if (response.data.status !== 'OK') {
            return res.status(400).json({
                success: false,
                error: `Directions API error: ${response.data.status}`,
                message: response.data.error_message
            });
        }

        const route = response.data.routes[0];
        const leg = route.legs[0];

        res.json({
            success: true,
            data: {
                polyline: route.overview_polyline.points,
                distance: leg.distance.text,
                duration: leg.duration.text,
                startLocation: leg.start_location,
                endLocation: leg.end_location
            }
        });
    } catch (error: any) {
        console.error('Directions API error:', error.message);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch directions',
            message: error.message
        });
    }
});

export default router;
