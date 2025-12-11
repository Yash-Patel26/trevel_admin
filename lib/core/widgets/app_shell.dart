import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/auth/auth_controller.dart';
import '../utils/permissions.dart';
import '../../features/drivers/data/drivers_repository.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  /// Get the appropriate icon for a user role
  static IconData _getRoleIcon(String? role) {
    switch (role) {
      case 'Operational Admin':
        return Icons.admin_panel_settings;
      case 'Fleet Admin':
        return Icons.directions_car;
      case 'Driver Admin':
        return Icons.person;
      case 'Driver Individual':
        return Icons.person_outline;
      case 'Fleet Individual':
        return Icons.directions_car_outlined;
      case 'Team':
        return Icons.group;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;

    // Driver Individual should see minimal navigation - drivers list and onboarding
    if (user?.role == 'Driver Individual') {
      final current = GoRouterState.of(context).uri.toString();
      final isOnboarding = current.startsWith('/drivers/onboard');
      final isDriversList = current == '/drivers' || current == '/drivers/';

      if (isOnboarding) {
        // When onboarding, the pages have their own Scaffold/AppBar
        return SafeArea(child: child);
      }

      return Scaffold(
        appBar: AppBar(
          title: const Text('My Drivers'),
          automaticallyImplyLeading: false,
          actions: [
            if (isDriversList)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  // Refresh drivers list by invalidating the repository
                  // This will cause all providers watching it to refetch
                  ref.invalidate(driversRepositoryProvider);
                },
                tooltip: 'Refresh',
              ),
            if (isDriversList)
              FilledButton.icon(
                onPressed: () => context.go('/drivers/onboard/step1'),
                icon: const Icon(Icons.person_add),
                label: const Text('Onboard Driver'),
              ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.account_circle),
              tooltip: 'Account',
              onSelected: (value) async {
                if (value == 'logout') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    // Perform logout
                    await ref.read(authControllerProvider.notifier).logout();
                    if (context.mounted) {
                      await Future.delayed(const Duration(milliseconds: 50));
                      if (context.mounted) {
                        context.go('/login');
                      }
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? user?.email ?? 'User',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        user?.role ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: child,
      );
    }

    // Build navigation items based on permissions
    final allLocations = <_NavItem>[
      _NavItem(
        '/dashboard',
        'Dashboard',
        Icons.dashboard_outlined,
        requiredPermission: 'dashboard:view',
      ),
      _NavItem(
        '/vehicles',
        'Vehicles',
        Icons.directions_car_outlined,
        checkAccess: () => PermissionChecker.canAccessVehicles(user),
      ),
      _NavItem(
        '/drivers',
        'Drivers',
        Icons.person_outline,
        checkAccess: () => PermissionChecker.canAccessDrivers(user),
      ),
      _NavItem(
        '/tickets',
        'Tickets',
        Icons.confirmation_num_outlined,
        checkAccess: () => PermissionChecker.canAccessTickets(user),
      ),
      _NavItem(
        '/bookings',
        'Bookings',
        Icons.event_note_outlined,
        checkAccess: () => PermissionChecker.canAccessBookings(user),
      ),
      _NavItem(
        '/users',
        'Users',
        Icons.people_outline,
        checkAccess: () => PermissionChecker.canAccessUsers(user),
      ),
      _NavItem(
        '/audit',
        'Audit',
        Icons.history_toggle_off,
        checkAccess: () => PermissionChecker.canAccessAudit(user),
      ),
      _NavItem(
        '/rides',
        'Rides',
        Icons.route_outlined,
        checkAccess: () => PermissionChecker.canAccessRides(user),
      ),
    ];

    // Filter locations based on permissions
    final locations = allLocations.where((item) {
      if (item.requiredPermission != null) {
        return user?.hasPermission(item.requiredPermission!) ?? false;
      }
      if (item.checkAccess != null) {
        return item.checkAccess!();
      }
      return true;
    }).toList();

    final current = GoRouterState.of(context).uri.toString();
    final selectedIndex =
        locations.indexWhere((e) => current.startsWith(e.path));

    // Ensure selectedIndex is valid
    final validSelectedIndex = locations.isEmpty ||
            selectedIndex < 0 ||
            selectedIndex >= locations.length
        ? (locations.isEmpty ? 0 : 0)
        : selectedIndex;

    // Determine if we should use rail (web/desktop) or bottom bar (mobile)
    final isWebOrDesktop = kIsWeb || MediaQuery.of(context).size.width >= 600;

    // Build navigation destinations (without labels for mobile)
    final navigationDestinations = [
      for (final item in locations)
        NavigationDestination(
          icon: Icon(item.icon),
          selectedIcon: Icon(item.icon),
          label: '', // Remove text labels
        ),
    ];

    // Build navigation rail destinations for web/desktop
    final navigationRailDestinations = [
      for (final item in locations)
        NavigationRailDestination(
          icon: Icon(item.icon),
          selectedIcon: Icon(item.icon),
          label: Text(item.label),
        ),
    ];

    if (isWebOrDesktop && locations.length >= 2) {
      // Web/Desktop layout: NavigationRail on the left
      return Scaffold(
        appBar: AppBar(
          title: const Text('Trevel Admin'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Chip(
                avatar: Icon(
                  _getRoleIcon(user?.role),
                  size: 18,
                ),
                label: Text(user?.role ?? 'User'),
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.account_circle),
              tooltip: 'Account',
              onSelected: (value) async {
                if (value == 'logout') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    // Perform logout - this will update state and trigger router redirect
                    await ref.read(authControllerProvider.notifier).logout();
                    // Router's redirect logic should automatically navigate to /login
                    // But add a small delay and manual navigation as fallback
                    if (context.mounted) {
                      await Future.delayed(const Duration(milliseconds: 50));
                      if (context.mounted) {
                        // Force navigation to login page
                        context.go('/login');
                      }
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? user?.email ?? 'User',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        user?.role ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: validSelectedIndex,
              onDestinationSelected: (index) {
                if (index >= 0 && index < locations.length) {
                  context.go(locations[index].path);
                }
              },
              labelType: NavigationRailLabelType.all,
              destinations: navigationRailDestinations,
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: Container(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.2),
                child: SafeArea(
                  top: false,
                  child: child,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Mobile layout: NavigationBar at the bottom
      return Scaffold(
        appBar: AppBar(
          title: const Text('Trevel Admin'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Chip(
                avatar: Icon(
                  _getRoleIcon(user?.role),
                  size: 18,
                ),
                label: Text(user?.role ?? 'User'),
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.account_circle),
              tooltip: 'Account',
              onSelected: (value) async {
                if (value == 'logout') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    // Perform logout - this will update state and trigger router redirect
                    await ref.read(authControllerProvider.notifier).logout();
                    // Router's redirect logic should automatically navigate to /login
                    // But add a small delay and manual navigation as fallback
                    if (context.mounted) {
                      await Future.delayed(const Duration(milliseconds: 50));
                      if (context.mounted) {
                        // Force navigation to login page
                        context.go('/login');
                      }
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? user?.email ?? 'User',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        user?.role ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Container(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.2),
          child: SafeArea(
            top: false,
            child: child,
          ),
        ),
        bottomNavigationBar: locations.length >= 2
            ? NavigationBar(
                selectedIndex: validSelectedIndex,
                onDestinationSelected: (index) {
                  if (index >= 0 && index < locations.length) {
                    context.go(locations[index].path);
                  }
                },
                destinations: navigationDestinations,
              )
            : null,
      );
    }
  }
}

class _NavItem {
  final String path;
  final String label;
  final IconData icon;
  final String? requiredPermission;
  final bool Function()? checkAccess;

  const _NavItem(
    this.path,
    this.label,
    this.icon, {
    this.requiredPermission,
    this.checkAccess,
  });
}
