/**
 * Validates pickup time for bookings
 * Ensures pickup time is at least 2 hours from current time
 * Supports both 24-hour format (HH:MM:SS) and 12-hour format with AM/PM
 */

/**
 * Parses time string in various formats to 24-hour format (HH:MM:SS)
 * Supports:
 * - 24-hour: "08:16", "08:16:30"
 * - 12-hour: "08:16 AM", "08:16:30 PM", "8:16 AM"
 * @param {string} timeStr - Time string to parse
 * @returns {string|null} - Time in HH:MM:SS format or null if invalid
 */
function parseTimeTo24Hour(timeStr) {
  if (!timeStr) return null;
  
  const trimmed = String(timeStr).trim();
  
  // Try AM/PM format first
  const amPmMatch = /^(\d{1,2}):(\d{2})(?::(\d{2}))?\s?(AM|PM)$/i.exec(trimmed);
  if (amPmMatch) {
    let [, hourStr, minuteStr, secondStr = '00', suffix] = amPmMatch;
    let hour = Number(hourStr);
    const minutes = Number(minuteStr);
    const seconds = Number(secondStr);
    const isPm = suffix.toUpperCase() === 'PM';
    
    // Validate hour, minutes, seconds
    if (hour < 1 || hour > 12 || minutes < 0 || minutes > 59 || seconds < 0 || seconds > 59) {
      return null;
    }
    
    // Convert to 24-hour format
    if (hour === 12) {
      hour = isPm ? 12 : 0;
    } else if (isPm) {
      hour += 12;
    }
    
    return `${String(hour).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
  }
  
  // Try 24-hour format
  const time24Match = /^(\d{2}):(\d{2})(?::(\d{2}))?$/.exec(trimmed);
  if (time24Match) {
    const [, hourStr, minuteStr, secondStr = '00'] = time24Match;
    const hour = Number(hourStr);
    const minutes = Number(minuteStr);
    const seconds = Number(secondStr);
    
    // Validate hour, minutes, seconds
    if (hour < 0 || hour > 23 || minutes < 0 || minutes > 59 || seconds < 0 || seconds > 59) {
      return null;
    }
    
    return `${String(hour).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
  }
  
  return null;
}

/**
 * Validates pickup date and time
 * Ensures pickup datetime is at least 2 hours from current time
 * @param {string} pickupDate - Date in YYYY-MM-DD format
 * @param {string} pickupTime - Time in HH:MM:SS format (24-hour) or with AM/PM
 * @param {number} minHoursAhead - Minimum hours ahead required (default: 2)
 * @returns {Object} - { valid: boolean, error: string|null, pickupDateTime: Date|null }
 */
function validatePickupTime(pickupDate, pickupTime, minHoursAhead = 2) {
  // Parse time to 24-hour format (ignore seconds, work with hours and minutes only)
  const time24Hour = parseTimeTo24Hour(pickupTime);
  
  if (!time24Hour) {
    return {
      valid: false,
      error: `Invalid pickup time format. Use HH:MM (24-hour) or HH:MM AM/PM (12-hour). Received: ${pickupTime}`,
      pickupDateTime: null
    };
  }
  
  if (!pickupDate) {
    return {
      valid: false,
      error: 'Pickup date is required',
      pickupDateTime: null
    };
  }
  
  // Parse date
  const dateMatch = /^(\d{4})-(\d{2})-(\d{2})$/.exec(pickupDate);
  if (!dateMatch) {
    return {
      valid: false,
      error: `Invalid pickup date format. Use YYYY-MM-DD. Received: ${pickupDate}`,
      pickupDateTime: null
    };
  }
  
  // Get current time (ignore seconds, work with hours and minutes only)
  const now = new Date();
  const nowYear = now.getFullYear();
  const nowMonth = now.getMonth();
  const nowDay = now.getDate();
  const nowHour = now.getHours();
  const nowMinute = now.getMinutes();
  
  // Parse pickup time (ignore seconds)
  const [year, month, day] = dateMatch.slice(1).map(Number);
  const [hour, minute] = time24Hour.split(':').map(Number);
  
  // Create pickup datetime (set seconds to 0)
  let pickupDateTime = new Date(year, month - 1, day, hour, minute, 0);
  
  // Handle date rollover: If selected time is earlier than current time on the same day,
  // or if time crosses midnight (e.g., 11:48 PM -> 1:49 AM), adjust to next day
  const selectedDate = new Date(year, month - 1, day);
  const today = new Date(nowYear, nowMonth, nowDay);
  const isToday = selectedDate.getTime() === today.getTime();
  
  if (isToday) {
    // If today, check if selected time is earlier than current time
    // If so, or if it's less than 2 hours away, it should be tomorrow
    const selectedMinutes = (hour * 60) + minute;
    const currentMinutes = (nowHour * 60) + nowMinute;
    
    // If selected time is earlier than current time, or less than 2 hours away, move to next day
    if (selectedMinutes < currentMinutes || (selectedMinutes - currentMinutes) < (minHoursAhead * 60)) {
      // Move to next day
      pickupDateTime = new Date(nowYear, nowMonth, nowDay + 1, hour, minute, 0);
    }
  }
  
  // Validate date (check if date was adjusted correctly)
  // No need to validate here as we've already handled date rollover
  
  // Calculate time difference in minutes (ignore seconds)
  const pickupMinutes = (pickupDateTime.getHours() * 60) + pickupDateTime.getMinutes();
  const currentMinutes = (now.getHours() * 60) + now.getMinutes();
  const pickupDateOnly = new Date(pickupDateTime.getFullYear(), pickupDateTime.getMonth(), pickupDateTime.getDate());
  const currentDateOnly = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  
  // Calculate total minutes difference (accounting for date change)
  let totalMinutesDiff;
  if (pickupDateOnly.getTime() === currentDateOnly.getTime()) {
    // Same day
    totalMinutesDiff = pickupMinutes - currentMinutes;
  } else {
    // Different day - calculate minutes from now to midnight, then add pickup minutes
    const minutesToMidnight = (24 * 60) - currentMinutes;
    const daysDiff = Math.floor((pickupDateOnly.getTime() - currentDateOnly.getTime()) / (1000 * 60 * 60 * 24));
    totalMinutesDiff = minutesToMidnight + (daysDiff - 1) * (24 * 60) + pickupMinutes;
  }
  
  const requiredMinutes = minHoursAhead * 60;
  
  // Check if time difference is at least 2 hours (120 minutes)
  if (totalMinutesDiff < requiredMinutes) {
    // Calculate minimum allowed time
    const minAllowedDateTime = new Date(now.getTime() + (requiredMinutes * 60 * 1000));
    const minAllowedDate = new Date(minAllowedDateTime.getFullYear(), minAllowedDateTime.getMonth(), minAllowedDateTime.getDate());
    const minAllowedHour = minAllowedDateTime.getHours();
    const minAllowedMinute = minAllowedDateTime.getMinutes();
    
    // Format minimum allowed time
    const minAllowedTimeStr = minAllowedDateTime.toLocaleString('en-US', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      hour12: true
    });
    
    const pickupTimeStr = pickupDateTime.toLocaleString('en-US', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      hour12: true
    });
    
    const currentTimeStr = now.toLocaleString('en-US', {
      hour: '2-digit',
      minute: '2-digit',
      hour12: true
    });
    
    return {
      valid: false,
      error: `Pickup time must be at least ${minHoursAhead} hours from now. Current time: ${currentTimeStr}, Minimum allowed: ${minAllowedTimeStr}, Selected: ${pickupTimeStr}`,
      pickupDateTime: pickupDateTime
    };
  }
  
  return {
    valid: true,
    error: null,
    pickupDateTime: pickupDateTime
  };
}

module.exports = {
  parseTimeTo24Hour,
  validatePickupTime
};

