# Node.js Backend (Operational Dashboard)

Node.js + TypeScript backend implementing the Operational Dashboard services. Stack: Express, TypeScript, Prisma, JWT (with refresh tokens), bcrypt, Pino, Zod validation.

## Features

✅ **Authentication & Authorization**
- JWT-based authentication with access and refresh tokens
- Role-based access control (RBAC) with permissions
- User management (CRUD operations)
- Password hashing with bcrypt

✅ **Core Modules**
- **Vehicles**: Onboarding, review/approval, driver assignment, logs, metrics
- **Drivers**: Onboarding, background checks, training assignments, approval, vehicle allocation, logs
- **Tickets**: Create, list, update with status tracking
- **Bookings**: Customer booking management with OTP validation, status updates, completion/cancellation
- **Ride Summaries**: Track rides with distance and timing data
- **Dashboards**: Fleet, vehicle, and driver aggregates
- **Audit Logging**: Comprehensive audit trail for all operations
- **Notifications**: Queue system for email/SMS/in-app notifications (stub implementation)

✅ **Data Validation**
- Zod schemas with enum validation for statuses
- Type-safe request/response handling
- Comprehensive error handling

## Setup

```powershell
cd backend
npm install
```

### Environment Variables

Create `.env` file:
```
PORT=4000
DATABASE_URL=postgres://user:pass@localhost:5432/trevel_admin
JWT_SECRET=change-me-to-secure-random-string
CORS_ORIGINS=*
NODE_ENV=development
```

### Database Setup

1. Update `DATABASE_URL` in `.env` with your PostgreSQL connection string
2. Run migrations:
   ```bash
   npm run prisma:migrate -- --name init
   ```
3. Generate Prisma Client:
   ```bash
   npm run prisma:generate
   ```
4. Seed initial data (roles, permissions, admin user):
   ```bash
   npm run prisma:seed
   ```

### Development

```bash
npm run dev   # runs ts-node-dev in watch mode
```

## Scripts

- `npm run dev` — Development server with hot reload
- `npm run build` — Compile TypeScript to `dist/`
- `npm start` — Run compiled production build
- `npm test` — Run Jest tests
- `npm run lint` — Run ESLint
- `npm run prisma:generate` — Generate Prisma Client
- `npm run prisma:migrate` — Run Prisma migrations (dev mode)
- `npm run prisma:seed` — Seed database with initial data

## API Endpoints

### Authentication
- `POST /auth/login` — Login (returns access + refresh tokens)
- `POST /auth/refresh` — Refresh access token
- `POST /auth/logout` — Logout (revoke refresh tokens)
- `POST /auth/logout-all` — Logout from all devices
- `GET /auth/me` — Get current user

### Users
- `POST /users` — Create user (requires `user:create`)
- `GET /users` — List users (requires `user:view`)
- `GET /users/:id` — Get user (requires `user:view`)
- `PATCH /users/:id` — Update user (requires `user:update`)
- `DELETE /users/:id` — Delete user (requires `user:delete`)

### Vehicles
- `POST /vehicles` — Create vehicle (requires `vehicle:create`)
- `GET /vehicles` — List vehicles (requires `vehicle:view`)
- `POST /vehicles/:id/review` — Review vehicle (requires `vehicle:review`)
- `POST /vehicles/:id/assign-driver` — Assign driver (requires `vehicle:assign`)
- `GET /vehicles/:id/logs` — Get vehicle logs (requires `vehicle:logs`)
- `GET /vehicles/:id/metrics` — Get vehicle metrics (requires `vehicle:view`)

### Drivers
- `POST /drivers` — Create driver (requires `driver:create`)
- `GET /drivers` — List drivers (requires `driver:view`)
- `POST /drivers/:id/background` — Background check (requires `driver:verify`)
- `POST /drivers/:id/training` — Assign training (requires `driver:train`)
- `POST /drivers/:id/approve` — Approve driver (requires `driver:approve`)
- `POST /drivers/:id/assign-vehicle` — Assign vehicle (requires `driver:assign`)
- `GET /drivers/:id/logs` — Get driver logs (requires `driver:logs`)

### Tickets
- `POST /tickets` — Create ticket (requires `ticket:create`)
- `GET /tickets` — List tickets (requires `ticket:view`)
- `PATCH /tickets/:id` — Update ticket (requires `ticket:update`)

### Bookings
- `GET /customers/dashboard/summary` — Booking summary stats
- `GET /customers/bookings` — List bookings
- `GET /bookings/:id` — Get booking details
- `POST /bookings/:id/assign` — Assign vehicle/driver to booking
- `POST /bookings/:id/validate-otp` — Validate OTP code
- `PATCH /bookings/:id/status` — Update booking status
- `POST /bookings/:id/complete` — Complete booking
- `POST /bookings/:id/cancel` — Cancel booking

### Rides
- `POST /rides` — Create ride summary (requires `ride:create`)
- `GET /rides` — List rides (requires `ride:view`)
- `GET /rides/:id` — Get ride details (requires `ride:view`)
- `PATCH /rides/:id` — Update ride (requires `ride:update`)

### Dashboards
- `GET /dashboards/fleet` — Fleet overview
- `GET /dashboards/vehicle/:id` — Vehicle dashboard
- `GET /dashboards/drivers` — Drivers overview
- `GET /dashboards/driver/:id` — Driver dashboard

### Audit
- `GET /audit-logs` — List audit logs (requires `audit:view`)

## Test Users

After seeding, the following test users are available:

### Operational Admin
- Email: `admin@example.com`
- Password: `admin123`
- Role: Operational Admin (full permissions)
- Access: All sections

### Fleet Admin
- Email: `fleet@example.com`
- Password: `fleet123`
- Role: Fleet Admin
- Access: Dashboard, Vehicles, Tickets, Bookings

### Driver Admin
- Email: `driver@example.com`
- Password: `driver123`
- Role: Driver Admin
- Access: Dashboard, Drivers, Tickets, Bookings

See [TEST_USERS.md](./TEST_USERS.md) for detailed information about testing different role-based dashboards.

## Testing

Run tests:
```bash
npm test
```

Test files:
- `tests/auth.test.ts` — Authentication tests
- `tests/health.test.ts` — Health check tests
- `tests/users.test.ts` — User management tests

## Code Quality

- **ESLint**: Configured with TypeScript and import ordering rules
- **Prettier**: Code formatting
- **TypeScript**: Strict mode enabled
- **Zod**: Runtime validation for all API inputs

## Architecture

- **Routes**: Modular Express routers (`src/routes/`)
- **Middleware**: Auth and permission guards (`src/middleware/`)
- **Validation**: Zod schemas (`src/validation/`)
- **RBAC**: Roles and permissions (`src/rbac/`)
- **Database**: Prisma ORM (`prisma/schema.prisma`)
- **Utils**: Audit logging, pagination, OTP generation (`src/utils/`)
- **Services**: Notification queue (`src/services/`)

## Migration Guide

See [MIGRATION_GUIDE.md](./MIGRATION_GUIDE.md) for database migration instructions.

