# Role-Based Access Control (RBAC) Implementation

## Overview

The Flutter admin panel now implements comprehensive role-based access control that restricts navigation and dashboard views based on user roles and permissions received from the backend.

## Implementation Details

### 1. User Information Storage

**File**: `lib/core/state/auth/auth_state.dart`

- Extended `AuthState` to include `UserInfo` with:
  - User ID, email, full name
  - Role name
  - List of permissions
- Added helper methods:
  - `hasPermission(String permission)` - Check single permission
  - `hasAnyPermission(List<String>)` - Check if user has any of the permissions
  - `hasAllPermissions(List<String>)` - Check if user has all permissions

### 2. Authentication Flow

**Files**: 
- `lib/features/auth/data/auth_repository.dart`
- `lib/core/state/auth/auth_controller.dart`
- `lib/features/auth/presentation/login_page.dart`

- Updated login to parse and store user information from backend response
- On app initialization, fetches current user info if token exists
- Login redirects to role-specific dashboard based on permissions

### 3. Permission Checking Utility

**File**: `lib/core/utils/permissions.dart`

Created `PermissionChecker` class with methods:
- `canAccessVehicles(UserInfo?)` - Check vehicle access
- `canAccessDrivers(UserInfo?)` - Check driver access
- `canAccessTickets(UserInfo?)` - Check ticket access
- `canAccessBookings(UserInfo?)` - Check booking access
- `canAccessUsers(UserInfo?)` - Check user management access
- `canAccessAudit(UserInfo?)` - Check audit log access
- `canAccessDashboard(UserInfo?)` - Check dashboard access
- `getDefaultDashboardRoute(UserInfo?)` - Get role-specific default route

### 4. Navigation Filtering

**File**: `lib/core/widgets/app_shell.dart`

- Navigation items are dynamically filtered based on user permissions
- Only shows menu items the user has access to
- Each navigation item can specify:
  - `requiredPermission` - Single permission check
  - `checkAccess` - Custom permission check function

### 5. Route Protection

**File**: `lib/core/routes/app_router.dart`

- Added permission checks in router redirect logic
- Users attempting to access unauthorized routes are redirected to their default dashboard
- Dashboard access is also protected - redirects to first available section if no dashboard permission

### 6. Role-Specific Dashboards

**File**: `lib/features/dashboard/presentation/dashboard_page.dart`

Dashboard displays different content based on role:

#### Operational Admin
- Full overview with all metrics
- Access to all sections
- Shows: Total Vehicles, Drivers, Tickets, Bookings

#### Fleet Admin
- Fleet-focused dashboard
- Shows: Total Vehicles, Active Vehicles, Pending Reviews, Open Tickets
- Quick actions: Add Vehicle, Review Vehicles, View Tickets
- Access to: Vehicles, Tickets, Bookings, Dashboard

#### Driver Admin
- Driver-focused dashboard
- Shows: Total Drivers, Pending Approval, In Training, Active Drivers
- Quick actions: Add Driver, Verify Background, Assign Training
- Access to: Drivers, Tickets, Bookings, Dashboard

## Role Permissions Matrix

Based on backend roles (`backend/src/rbac/roles.ts`):

### Operational Admin
- **Full Access**: All permissions
- **Dashboard**: Complete operational overview
- **Navigation**: All menu items visible

### Fleet Admin
- **Permissions**: 
  - `vehicle:*` (create, review, approve, view, assign, logs)
  - `dashboard:view`
  - `ticket:*` (create, view, update)
  - `booking:*` (view, assign, update)
  - `customer:view`
  - `ride:view`
- **Dashboard**: Fleet management focus
- **Navigation**: Dashboard, Vehicles, Tickets, Bookings

### Driver Admin
- **Permissions**:
  - `driver:*` (create, verify, train, approve, view, assign, logs)
  - `dashboard:view`
  - `ticket:*` (create, view, update)
  - `booking:*` (view, assign, update)
  - `customer:view`
  - `ride:*` (create, view, update)
- **Dashboard**: Driver management focus
- **Navigation**: Dashboard, Drivers, Tickets, Bookings

## Security Features

1. **Route Protection**: Unauthorized routes redirect to default dashboard
2. **Navigation Filtering**: Only accessible sections shown in menu
3. **Permission Checks**: All access controlled by backend permissions
4. **Token Validation**: User info fetched on app init to validate token

## Testing Roles

### Operational Admin
- Email: `admin@example.com`
- Password: `admin123`
- Should see: All navigation items, full dashboard

### Fleet Admin
- Create user with Fleet Admin role
- Should see: Dashboard, Vehicles, Tickets, Bookings
- Should NOT see: Drivers, Users, Audit (unless has permissions)

### Driver Admin
- Create user with Driver Admin role
- Should see: Dashboard, Drivers, Tickets, Bookings
- Should NOT see: Vehicles, Users, Audit (unless has permissions)

## Future Enhancements

1. **Granular Permissions**: More specific permission checks within pages
2. **Action-Level RBAC**: Hide/show buttons based on permissions
3. **Data Filtering**: Filter data based on user's team/scope
4. **Audit Trail**: Log all permission checks and access attempts
5. **Permission Override**: Admin override for testing

