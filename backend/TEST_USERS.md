# Test Users for Frontend Testing

This document lists all test users available for testing different role-based dashboards in the Flutter admin panel.

## Test Users

### 1. Operational Admin
- **Email**: `admin@example.com`
- **Password**: `admin123`
- **Role**: Operational Admin
- **Dashboard**: Full operational overview with all metrics
- **Access**: All sections (Dashboard, Vehicles, Drivers, Tickets, Bookings, Users, Audit)
- **Use Case**: Test complete admin functionality

### 2. Fleet Admin
- **Email**: `fleet@example.com`
- **Password**: `fleet123`
- **Role**: Fleet Admin
- **Dashboard**: Fleet management focused dashboard
- **Access**: Dashboard, Vehicles, Tickets, Bookings
- **Restricted**: Drivers, Users, Audit (unless has specific permissions)
- **Use Case**: Test fleet management workflows

### 3. Driver Admin
- **Email**: `driver@example.com`
- **Password**: `driver123`
- **Role**: Driver Admin
- **Dashboard**: Driver management focused dashboard
- **Access**: Dashboard, Drivers, Tickets, Bookings
- **Restricted**: Vehicles, Users, Audit (unless has specific permissions)
- **Use Case**: Test driver management workflows

### 4. Driver Individual
- **Email**: `driver-individual@example.com`
- **Password**: `driver123`
- **Role**: Driver Individual
- **Dashboard**: Individual driver dashboard
- **Access**: Dashboard, Assigned Tasks/Tickets, Profile
- **Use Case**: Test individual driver views and task completion

### 5. Fleet Individual
- **Email**: `fleet-individual@example.com`
- **Password**: `fleet123`
- **Role**: Fleet Individual
- **Dashboard**: Individual fleet owner dashboard
- **Access**: Dashboard, My Vehicles
- **Use Case**: Test individual fleet owner views

### 6. Team Member
- **Email**: `team@example.com`
- **Password**: `team123`
- **Role**: Team
- **Dashboard**: Team collaboration dashboard
- **Access**: Dashboard, Tickets, Bookings, Rides, Customers, Drivers, Vehicles (View/Review)
- **Use Case**: Test support and operations tasks

## How to Use

1. **Run the seed script** to create/update test users:
   ```bash
   cd backend
   npm run prisma:seed
   ```

2. **Start the backend server**:
   ```bash
   npm run dev
   ```

3. **Start the Flutter app**:
   ```bash
   flutter run -d chrome
   ```

4. **Login with different users** to see different dashboards:
   - Login as `admin@example.com` → See full admin dashboard
   - Login as `fleet@example.com` → See fleet-focused dashboard
   - Login as `driver@example.com` → See driver-focused dashboard
   - Login as `driver-individual@example.com` → See individual driver dashboard

## Expected Behavior

### Operational Admin Dashboard
- Shows all navigation items
- Displays: Total Vehicles, Total Drivers, Active Tickets, Total Bookings
- Can access all sections

### Fleet Admin Dashboard
- Shows: Dashboard, Vehicles, Tickets, Bookings in navigation
- Displays: Total Vehicles, Active Vehicles, Pending Reviews, Open Tickets
- Quick actions: Add Vehicle, Review Vehicles, View Tickets
- Cannot access: Drivers, Users, Audit sections

### Driver Admin Dashboard
- Shows: Dashboard, Drivers, Tickets, Bookings in navigation
- Displays: Total Drivers, Pending Approval, In Training, Active Drivers
- Quick actions: Add Driver, Verify Background, Assign Training
- Cannot access: Vehicles, Users, Audit sections

### Driver Individual Dashboard
- Shows: Dashboard, My Profile, My Tasks/Tickets
- Displays: Assigned Vehicle, Performance Metrics
- Cannot access: Admin management sections

## Resetting Users

To reset all test users to their default state, run:
```bash
npm run prisma:seed
```

This will update existing users or create them if they don't exist.

## Notes

- All passwords are simple (`*123`) for easy testing
- Users are set to `isActive: true` by default
- Roles are automatically assigned based on the role name
- If you modify roles in `src/rbac/roles.ts`, run the seed script again to update permissions
