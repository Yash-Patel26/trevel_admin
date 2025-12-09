import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/audit/presentation/audit_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/bookings/presentation/booking_detail_page.dart';
import '../../features/bookings/presentation/bookings_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/drivers/presentation/create_driver_page.dart';
import '../../features/drivers/presentation/driver_detail_page.dart';
import '../../features/drivers/presentation/drivers_page.dart';
import '../../features/drivers/presentation/onboarding/step1_basic_info_page.dart';
import '../../features/drivers/presentation/onboarding/step2_documents_page.dart';
import '../../features/drivers/presentation/onboarding/step3_contact_preferences_page.dart';
import '../../features/drivers/presentation/onboarding/step4_verification_page.dart';
import '../../features/drivers/presentation/onboarding/step5_vehicle_allocation_page.dart';
import '../../features/drivers/presentation/onboarding/step5_training_page.dart';
import '../../features/drivers/presentation/onboarding/step6_review_page.dart';
import '../../features/rides/presentation/ride_detail_page.dart';
import '../../features/rides/presentation/rides_page.dart';
import '../../features/tickets/presentation/ticket_detail_page.dart';
import '../../features/tickets/presentation/tickets_page.dart';
import '../../features/users/presentation/user_detail_page.dart';
import '../../features/users/presentation/users_page.dart';
import '../../features/vehicles/presentation/assign_driver_to_vehicle_page.dart';
import '../../features/vehicles/presentation/create_vehicle_page.dart';
import '../../features/vehicles/presentation/vehicle_detail_page.dart';
import '../../features/vehicles/presentation/vehicles_page.dart';
import '../state/auth/auth_controller.dart';
import '../utils/permissions.dart';
import '../widgets/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: GoRouterRefreshStream(
        ref.watch(authControllerProvider.notifier).stream),
    redirect: (context, state) {
      if (auth.isLoading) return null;

      final loggedIn = auth.isAuthenticated;
      final goingToLogin = state.fullPath == '/login';

      // If not logged in and not going to login, redirect to login
      if (!loggedIn && !goingToLogin) return '/login';
      
      // If not logged in and going to login, allow it (important for logout)
      if (!loggedIn && goingToLogin) return null;
      
      // If logged in and trying to access login, redirect to dashboard
      if (loggedIn && goingToLogin) {
        // Redirect to role-specific dashboard
        return PermissionChecker.getDefaultDashboardRoute(auth.user);
      }

      // Check if user has permission to access the current route
      if (loggedIn && auth.user != null) {
        final path = state.fullPath ?? '';
        final user = auth.user!;

        // Driver Individual can access onboarding steps 1-3 and view their drivers
        if (user.role == 'Driver Individual') {
          if (path == '/drivers/create') {
            return '/drivers/onboard/step1';
          }
          // Block access to steps 4-7
          if (path.startsWith('/drivers/onboard/step4') ||
              path.startsWith('/drivers/onboard/step5') ||
              path.startsWith('/drivers/onboard/step6') ||
              path.startsWith('/drivers/onboard/step7')) {
            return '/drivers/onboard/step3';
          }
          // Allow access to drivers list and detail pages
          if (path.startsWith('/drivers/') &&
              !path.startsWith('/drivers/onboard/step4') &&
              !path.startsWith('/drivers/onboard/step5') &&
              !path.startsWith('/drivers/onboard/step6') &&
              !path.startsWith('/drivers/onboard/step7')) {
            // Allow /drivers and /drivers/:id
            return null;
          }
          // Block access to dashboard and other routes
          if (path.startsWith('/dashboard') ||
              path.startsWith('/vehicles') ||
              path.startsWith('/tickets') ||
              path.startsWith('/bookings') ||
              path.startsWith('/users') ||
              path.startsWith('/audit') ||
              path.startsWith('/rides')) {
            return '/drivers';
          }
          // Allow onboarding steps 1-3
          return null;
        }

        // Permission checks for each route
        if (path.startsWith('/vehicles') &&
            !PermissionChecker.canAccessVehicles(user)) {
          return PermissionChecker.getDefaultDashboardRoute(user);
        }
        if (path.startsWith('/drivers') &&
            !PermissionChecker.canAccessDrivers(user)) {
          return PermissionChecker.getDefaultDashboardRoute(user);
        }
        if (path.startsWith('/tickets') &&
            !PermissionChecker.canAccessTickets(user)) {
          return PermissionChecker.getDefaultDashboardRoute(user);
        }
        if (path.startsWith('/bookings') &&
            !PermissionChecker.canAccessBookings(user)) {
          return PermissionChecker.getDefaultDashboardRoute(user);
        }
        if (path.startsWith('/users') &&
            !PermissionChecker.canAccessUsers(user)) {
          return PermissionChecker.getDefaultDashboardRoute(user);
        }
        if (path.startsWith('/audit') &&
            !PermissionChecker.canAccessAudit(user)) {
          return PermissionChecker.getDefaultDashboardRoute(user);
        }
        if (path.startsWith('/rides') &&
            !PermissionChecker.canAccessRides(user)) {
          return PermissionChecker.getDefaultDashboardRoute(user);
        }
        if (path.startsWith('/dashboard') &&
            !PermissionChecker.canAccessDashboard(user)) {
          // Redirect to first available section
          if (PermissionChecker.canAccessVehicles(user)) return '/vehicles';
          if (PermissionChecker.canAccessDrivers(user)) return '/drivers';
          if (PermissionChecker.canAccessTickets(user)) return '/tickets';
          if (PermissionChecker.canAccessBookings(user)) return '/bookings';
          return '/login';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) =>
            const MaterialPage(child: LoginPage(), fullscreenDialog: true),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardPage()),
          ),
          GoRoute(
            path: '/vehicles',
            name: 'vehicles',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: VehiclesPage()),
            routes: [
              GoRoute(
                path: 'create',
                name: 'create-vehicle',
                pageBuilder: (context, state) =>
                    const MaterialPage(child: CreateVehiclePage()),
              ),
              GoRoute(
                path: ':id',
                name: 'vehicle-detail',
                pageBuilder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return MaterialPage(child: VehicleDetailPage(vehicleId: id));
                },
                routes: [
                  GoRoute(
                    path: 'assign-driver',
                    name: 'assign-driver-to-vehicle',
                    pageBuilder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return MaterialPage(
                        child: AssignDriverToVehiclePage(vehicleId: id),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/drivers',
            name: 'drivers',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DriversPage()),
            routes: [
              GoRoute(
                path: 'create',
                name: 'create-driver',
                pageBuilder: (context, state) =>
                    const MaterialPage(child: CreateDriverPage()),
              ),
              GoRoute(
                path: ':id',
                name: 'driver-detail',
                pageBuilder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return MaterialPage(child: DriverDetailPage(driverId: id));
                },
                routes: [
                  GoRoute(
                    path: 'assign-vehicle',
                    name: 'assign-vehicle',
                    pageBuilder: (context, state) {
                      // Reuse the vehicle allocation page from onboarding
                      // The page will get driverId from route parameters
                      return MaterialPage(child: Step5VehicleAllocationPage());
                    },
                  ),
                  GoRoute(
                    path: 'training',
                    name: 'driver-training',
                    pageBuilder: (context, state) {
                      // Reuse the training page from onboarding
                      // The page will get driverId from route parameters
                      return MaterialPage(child: Step5TrainingPage());
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'onboard',
                redirect: (context, state) {
                  // Only redirect if the path is exactly '/drivers/onboard'
                  // Don't redirect if we're already on a step route
                  final fullPath = state.fullPath ?? '';
                  if (fullPath == '/drivers/onboard' ||
                      fullPath == '/drivers/onboard/') {
                    return '/drivers/onboard/step1';
                  }
                  return null; // Don't redirect, let child routes handle it
                },
                routes: [
                  GoRoute(
                    path: 'step1',
                    name: 'onboard-step1',
                    pageBuilder: (context, state) =>
                        const MaterialPage(child: Step1BasicInfoPage()),
                  ),
                  GoRoute(
                    path: 'step2',
                    name: 'onboard-step2',
                    pageBuilder: (context, state) =>
                        const MaterialPage(child: Step2DocumentsPage()),
                  ),
                  GoRoute(
                    path: 'step3',
                    name: 'onboard-step3',
                    pageBuilder: (context, state) => const MaterialPage(
                        child: Step3ContactPreferencesPage()),
                  ),
                  GoRoute(
                    path: 'step4',
                    name: 'onboard-step4',
                    pageBuilder: (context, state) =>
                        const MaterialPage(child: Step4VerificationPage()),
                  ),
                  GoRoute(
                    path: 'step5',
                    name: 'onboard-step5',
                    pageBuilder: (context, state) =>
                        const MaterialPage(child: Step5VehicleAllocationPage()),
                  ),
                  GoRoute(
                    path: 'step6',
                    name: 'onboard-step6',
                    pageBuilder: (context, state) =>
                        const MaterialPage(child: Step5TrainingPage()),
                  ),
                  GoRoute(
                    path: 'step7',
                    name: 'onboard-step7',
                    pageBuilder: (context, state) =>
                        const MaterialPage(child: Step6ReviewPage()),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/tickets',
            name: 'tickets',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TicketsPage()),
            routes: [
              GoRoute(
                path: ':id',
                name: 'ticket-detail',
                pageBuilder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return MaterialPage(child: TicketDetailPage(ticketId: id));
                },
              ),
            ],
          ),
          GoRoute(
            path: '/bookings',
            name: 'bookings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BookingsPage()),
            routes: [
              GoRoute(
                path: ':id',
                name: 'booking-detail',
                pageBuilder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return MaterialPage(child: BookingDetailPage(bookingId: id));
                },
              ),
            ],
          ),
          GoRoute(
            path: '/users',
            name: 'users',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: UsersPage()),
            routes: [
              GoRoute(
                path: ':id',
                name: 'user-detail',
                pageBuilder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return MaterialPage(child: UserDetailPage(userId: id));
                },
              ),
            ],
          ),
          GoRoute(
            path: '/audit',
            name: 'audit',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AuditPage()),
          ),
          GoRoute(
            path: '/rides',
            name: 'rides',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: RidesPage()),
            routes: [
              GoRoute(
                path: ':id',
                name: 'ride-detail',
                pageBuilder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return MaterialPage(child: RideDetailPage(rideId: id));
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Simple listenable wrapper for a stream; used to notify GoRouter on auth changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
