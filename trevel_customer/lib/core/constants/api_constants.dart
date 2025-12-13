class ApiConstants {
  // Environment-based base URL configuration
  // Change this based on your testing environment
  
  // DOCKER DEPLOYMENT (Default for testing)
  // Android Emulator: Use 10.0.2.2 to access host machine
  // iOS Simulator: Use localhost
  // Physical Device: Use your machine's IP address (e.g., 192.168.1.100)
  
  static const String _environment = 'local'; // Changed to physical device for testing
  
  static String get baseUrl {
    switch (_environment) {
      case 'docker_android':
        return "http://10.0.2.2:4000/api/mobile";
      case 'docker_ios':
        return "http://localhost:4000/api/mobile";
      case 'docker_physical':
        // Replace with your machine's IP address
        return "http://192.168.1.107:4000/api/mobile";
      case 'local':
        return "http://localhost:4000/api/mobile";
      default:
        return "http://10.0.2.2:4000/api/mobile";
    }
  }
  
  // Auth Routes
  static const String sendOtp = "/auth/send-otp";
  static const String verifyOtp = "/auth/verify-otp";
  static const String resendOtp = "/auth/resend-otp";
  
  // Mini Trip Routes
  static const String miniTripEstimate = "/mini-trip/estimate";
  static const String miniTripBook = "/mini-trip/bookings";
  
  // Booking Routes
  static String bookingDetails(String bookingId) => "/bookings/$bookingId";
  static const String myBookings = "/bookings";
  
  // Airport Routes
  static const String airports = "/airport";
  static const String airportEstimate = "/airport/estimate";
}
