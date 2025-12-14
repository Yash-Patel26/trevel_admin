/**
 * Utility functions for time calculations
 */

/**
 * Calculate estimated travel time based on distance
 * @param distanceKm - Distance in kilometers
 * @param isPeakHours - Whether it's peak hours (affects average speed)
 * @returns Estimated time in minutes
 */
export function calculateEstimatedTimeMinutes(distanceKm: number, isPeakHours: boolean = false): number {
    // Average speed: 30 km/h in peak hours, 40 km/h off-peak
    const avgSpeed = isPeakHours ? 30 : 40;
    return Math.ceil((distanceKm / avgSpeed) * 60); // minutes
}

/**
 * Convert minutes to a Time object (for Prisma @db.Time fields)
 * @param minutes - Number of minutes
 * @returns Date object representing time (1970-01-01T HH:mm:ss Z)
 */
export function minutesToTimeObject(minutes: number): Date {
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;
    const timeString = `1970-01-01T${String(hours).padStart(2, '0')}:${String(mins).padStart(2, '0')}:00Z`;
    return new Date(timeString);
}

/**
 * Parse time string (HH:mm or HH:mm:ss) to minutes
 * @param timeString - Time string in HH:mm or HH:mm:ss format
 * @returns Total minutes
 */
export function parseTimeToMinutes(timeString: string): number {
    const match = timeString.match(/^(\d{1,2}):(\d{2})(?::(\d{2}))?$/);
    if (!match) {
        throw new Error(`Invalid time format: ${timeString}. Expected HH:mm or HH:mm:ss`);
    }

    const hours = parseInt(match[1], 10);
    const minutes = parseInt(match[2], 10);

    if (hours < 0 || hours > 23 || minutes < 0 || minutes > 59) {
        throw new Error(`Invalid time values: ${timeString}`);
    }

    return hours * 60 + minutes;
}
