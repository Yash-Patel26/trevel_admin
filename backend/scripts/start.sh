#!/bin/sh
set -e

echo "Starting deployment script..."

# Run migrations
echo "Runnning migrations..."
npx prisma migrate deploy

# Compile seed script
echo "Compiling seed script..."
npx tsc prisma/seed.ts --esModuleInterop --skipLibCheck

# Run seed
echo "Seeding database..."
npx prisma db seed

# Start application
echo "Starting application..."
exec "$@"
