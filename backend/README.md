# Unified Trevel Backend

This project is the **Unified Backend** for the Trevel platform, serving both the **Admin Panel** and the **Customer Mobile App**.

It combines the legacy customer backend (migrated to TypeScript/Node.js) and the modern Admin backend into a single server instance.

## Architecture

- **Root:** `src/server.ts` - Main entry point, mounts both routers.
- **Admin API:** `src/routes/` - TypeScript-based routes for the Admin Dashboard.
  - Prefix: `/api` (e.g., `/api/admin`, `/api/bookings`)
- **Mobile API:** `src/mobile_api/` - Migrated legacy code (JS/TS mixture) for the Customer App.
  - Prefix: `/api/v1` (e.g., `/api/v1/auth`, `/api/v1/mini-trips`)

## Prerequisites

- Node.js 20+
- PostgreSQL
- Redis (optional, for caching)
- Docker (optional, for containerized deployment)

## Setup & Run (Local)

1.  **Install Dependencies:**
    ```bash
    npm install
    ```

2.  **Environment Variables:**
    - Copy `.env.example` to `.env`
    - Ensure you have database credentials and third-party keys (AWS, Firebase, Zaakpay, Google Maps).

3.  **Run Migrations:**
    ```bash
    npx prisma migrate dev
    ```

4.  **Start Development Server:**
    ```bash
    npm run dev
    ```
    - Server runs on `http://localhost:4000`

5.  **Build for Production:**
    ```bash
    npm run build
    npm start
    ```

## Setup & Run (Docker)

The project includes a `docker-compose.yml` that spins up the Backend, PostgreSQL, and Redis.

1.  **Start Services:**
    ```bash
    docker-compose up --build -d
    ```

2.  **View Logs:**
    ```bash
    docker-compose logs -f backend
    ```

3.  **Stop Services:**
    ```bash
    docker-compose down
    ```

## API Documentation

A Postman collection is available in the root directory: `Unified_Trevel_API.postman_collection.json`.
Import this into Postman to test both Admin and Mobile endpoints.

## Database

- The schema is defined in `prisma/schema.prisma`.
- Admin `Customer` model is mapped to the `users` table to share data with the Mobile App.
- Bookings are synced from specific tables (`mini_trip_bookings`, etc.) to the central `Booking` table for Admin visibility.
