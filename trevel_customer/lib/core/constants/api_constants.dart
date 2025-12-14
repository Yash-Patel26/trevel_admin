class ApiConstants {
  static const String baseUrl = 'http://13.233.48.227:4000/api';
  
  // Auth
  static const String login = '/mobile/auth/login-otp';
  static const String verifyOtp = '/mobile/auth/verify-otp';
  static const String updateProfile = '/mobile/user/me';

  // Trips & Bookings

  static const String myBookings = '/mobile/bookings'; 
  
  static String bookingDetails(String id) => '/mobile/bookings/$id';

  // Hourly Rental
  static const String hourlyRentalInfo = '/mobile/hourly-rental/info';
  static const String hourlyRentalBooking = '/mobile/hourly-rental/bookings';
  
  // Missing constants
  static const String sendOtp = '/mobile/auth/send-otp';
  static const String clearAirports = '/mobile/airport'; // Corrected endpoint
  static const String AirportEstimate = '/mobile/airport/estimate'; 
  static const String locationAutocomplete = '/mobile/location/autocomplete';
  static const String reverseGeocode = '/mobile/location/reverse-geocode';

  // Mini Trip
  static const String miniTripInfo = '/mobile/mini-trip/info';
  static const String miniTripEstimate = '/mobile/mini-trip/estimate-trip';
  static const String miniTripBooking = '/mobile/mini-trip/bookings';
  
  // Directions
  static const String directions = '/mobile/directions/directions';
}