import '../state/auth/auth_state.dart';

class PermissionChecker {
  static bool canAccessVehicles(UserInfo? user) {
    if (user == null) return false;
    return user.hasPermission('vehicle:view') ||
        user.hasPermission('vehicle:create') ||
        user.hasPermission('vehicle:review');
  }

  static bool canAccessDrivers(UserInfo? user) {
    if (user == null) return false;
    return user.hasPermission('driver:view') ||
        user.hasPermission('driver:create') ||
        user.hasPermission('driver:verify');
  }

  static bool canAccessTickets(UserInfo? user) {
    if (user == null) return false;
    return user.hasPermission('ticket:view') ||
        user.hasPermission('ticket:create') ||
        user.hasPermission('ticket:update');
  }

  static bool canAccessBookings(UserInfo? user) {
    if (user == null) return false;
    return user.hasPermission('booking:view') ||
        user.hasPermission('booking:assign') ||
        user.hasPermission('booking:update');
  }

  static bool canAccessUsers(UserInfo? user) {
    if (user == null) return false;
    return user.hasPermission('user:view') ||
        user.hasPermission('user:create') ||
        user.hasPermission('user:update');
  }

  static bool canAccessAudit(UserInfo? user) {
    if (user == null) return false;
    return user.hasPermission('audit:view');
  }

  static bool canAccessRides(UserInfo? user) {
    if (user == null) return false;
    return user.hasPermission('ride:view') ||
        user.hasPermission('ride:create') ||
        user.hasPermission('ride:update');
  }

  static bool canAccessDashboard(UserInfo? user) {
    if (user == null) return false;
    return user.hasPermission('dashboard:view');
  }

  /// Get the default dashboard route based on user role/permissions
  static String getDefaultDashboardRoute(UserInfo? user) {
    if (user == null) return '/login';

    // Operational Admin sees everything - go to main dashboard
    if (user.role == 'Operational Admin') {
      return '/dashboard';
    }

    // Fleet Admin - fleet-focused dashboard
    if (user.role == 'Fleet Admin' || canAccessVehicles(user)) {
      return '/dashboard?view=fleet';
    }

    // Driver Admin - driver-focused dashboard
    if (user.role == 'Driver Admin' || canAccessDrivers(user)) {
      return '/dashboard?view=drivers';
    }

    // Driver Individual - show drivers list (their created drivers)
    if (user.role == 'Driver Individual') {
      return '/drivers';
    }

    // Fleet Individual - vehicle creation focused
    if (user.role == 'Fleet Individual') {
      if (canAccessVehicles(user)) return '/vehicles';
      return '/dashboard';
    }

    // Team - collaborative dashboard with bookings/tickets focus
    if (user.role == 'Team') {
      if (canAccessBookings(user)) return '/bookings';
      if (canAccessTickets(user)) return '/tickets';
      return '/dashboard';
    }

    // Default to main dashboard if they have dashboard:view
    if (canAccessDashboard(user)) {
      return '/dashboard';
    }

    // If no dashboard access, redirect to first available section
    if (canAccessVehicles(user)) return '/vehicles';
    if (canAccessDrivers(user)) return '/drivers';
    if (canAccessTickets(user)) return '/tickets';
    if (canAccessBookings(user)) return '/bookings';

    return '/login';
  }
}
