#!/bin/bash

# Seed Users in Docker Environment
# This script seeds both admin and customer users in the Docker database

set -e

echo "🚀 Starting Docker PostgreSQL..."
docker-compose up -d postgres

echo "⏳ Waiting for PostgreSQL to be ready..."
sleep 5

# Wait for database to be ready
until docker-compose exec -T postgres pg_isready -U user -d trevel_admin > /dev/null 2>&1; do
    echo "⏳ Database is not ready yet, waiting..."
    sleep 2
done

echo "✅ PostgreSQL is ready!"

echo ""
echo "🔄 Running Prisma migrations..."
npm run prisma:generate
npx prisma migrate deploy

echo ""
echo "👥 Seeding admin users..."
npm run seed

echo ""
echo "📱 Seeding test customer..."
npx ts-node scripts/create-test-customer.ts

echo ""
echo "✅ All users seeded successfully!"
echo ""
echo "📋 Admin Users Created:"
echo "  - admin@trevel.in (password: 112233) - Operational Admin"
echo "  - fleet@trevel.in (password: 112233) - Fleet Admin"
echo "  - driver@trevel.in (password: 112233) - Driver Admin"
echo "  - driver-individual@trevel.in (password: 112233) - Driver Individual"
echo "  - fleet-individual@trevel.in (password: 112233) - Fleet Individual"
echo "  - team@trevel.in (password: 112233) - Team Member"
echo ""
echo "📱 Customer User Created:"
echo "  - Mobile: +919876543210"
echo "  - Name: Test User"
echo "  - Email: testuser@trevel.com"
echo ""
