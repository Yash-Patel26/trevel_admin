import { Router } from 'express';
import axios from 'axios';
import { googleMapsService } from '../../services/googleMaps';

const router = Router();

// Google Directions API endpoint
router.get('/directions', async (req, res) => {
    try {
        const { origin, destination } = req.query as { origin: string; destination: string };

        if (!origin || !destination) {
            return res.status(400).json({
                success: false,
                error: 'Origin and destination are required'
            });
        }

        // Use the shared service which now supports traffic
        const data = await googleMapsService.getRoutes(origin, destination);

        const route = data.routes[0];
        if (!route) {
            return res.status(404).json({
                success: false,
                error: 'No route found'
            });
        }

        const leg = route.legs[0];

        // Traffic Analysis
        const durationValue = leg.duration?.value || 0;
        const durationInTrafficValue = leg.duration_in_traffic?.value || durationValue;

        // Calculate traffic delay in minutes
        const trafficDelayMinutes = Math.max(0, Math.round((durationInTrafficValue - durationValue) / 60));

        let trafficStatus = 'Normal';
        if (trafficDelayMinutes > 15) {
            trafficStatus = 'Heavy';
        } else if (trafficDelayMinutes > 5) {
            trafficStatus = 'Moderate';
        }

        res.json({
            success: true,
            data: {
                polyline: route.overview_polyline.points,
                distance: leg.distance.text,
                duration: leg.duration.text,
                duration_in_traffic: leg.duration_in_traffic?.text || leg.duration.text,
                traffic_status: trafficStatus,
                traffic_delay_mins: trafficDelayMinutes,
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
