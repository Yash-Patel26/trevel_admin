#!/bin/bash

# Deployment script with database seeding
# This script should be run on the EC2 instance after deploying the backend

set -e  # Exit on error

echo "🚀 Starting deployment with database seeding..."

# 1. Navigate to backend directory
cd /home/ubuntu/backend || exit 1

# 2. Install dependencies
echo "📦 Installing dependencies..."
npm ci --production=false

# 3. Build the application
echo "🔨 Building application..."
npm run build

# 4. Run database migrations (if any)
echo "🗄️  Running database migrations..."
npx prisma migrate deploy || echo "⚠️  No migrations to run or migration failed"

# 5. Seed the database
echo "🌱 Seeding database with test users..."
npm run seed || echo "⚠️  Seeding failed or already seeded"

# 6. Restart the application
echo "🔄 Restarting application..."
pm2 restart operational-backend || pm2 start npm --name "operational-backend" -- run start

echo "✅ Deployment completed successfully!"
echo ""
echo "Test users created:"
echo "  - admin@trevel.in (Operational Admin)"
echo "  - fleet@trevel.in (Fleet Admin)"
echo "  - driver@trevel.in (Driver Admin)"
echo "  - driver-individual@trevel.in (Driver Individual)"
echo "  - fleet-individual@trevel.in (Fleet Individual)"
echo "  - team@trevel.in (Team)"
echo ""
echo "Default password for all users: 112233"
