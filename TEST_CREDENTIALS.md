# Quick Test Credentials Reference

Use these credentials to test different role-based dashboards in the Flutter admin panel.

## 🎯 Quick Login Credentials

### Operational Admin (Full Access)
```
Email: admin@example.com
Password: admin123
```
**See**: All sections, full dashboard

### Fleet Admin (Fleet Focus)
```
Email: fleet@example.com
Password: fleet123
```
**See**: Dashboard, Vehicles, Tickets, Bookings

### Driver Admin (Driver Focus)
```
Email: driver@example.com
Password: driver123
```
**See**: Dashboard, Drivers, Tickets, Bookings

## 🚀 Setup Steps

1. **Seed the database** (if not already done):
   ```bash
   cd backend
   npm run prisma:seed
   ```

2. **Start backend**:
   ```bash
   cd backend
   npm run dev
   ```

3. **Run Flutter app**:
   ```bash
   flutter run -d chrome
   ```

4. **Login** with any of the credentials above to see different dashboards!

## 📋 What Each Role Sees

### Operational Admin Dashboard
- ✅ All navigation items visible
- ✅ Full operational overview
- ✅ All metrics: Vehicles, Drivers, Tickets, Bookings
- ✅ Can access all sections

### Fleet Admin Dashboard
- ✅ Navigation: Dashboard, Vehicles, Tickets, Bookings
- ❌ Hidden: Drivers, Users, Audit
- ✅ Fleet-focused metrics
- ✅ Quick actions: Add Vehicle, Review Vehicles

### Driver Admin Dashboard
- ✅ Navigation: Dashboard, Drivers, Tickets, Bookings
- ❌ Hidden: Vehicles, Users, Audit
- ✅ Driver-focused metrics
- ✅ Quick actions: Add Driver, Verify Background, Assign Training

## 💡 Tips

- All passwords follow the pattern: `{role}123`
- Users are automatically created/updated when you run `npm run prisma:seed`
- Logout and login with different users to compare dashboards
- Check the navigation sidebar to see which sections are visible for each role

