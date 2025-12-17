#!/bin/bash

# Docker Setup Script for Trevel Admin Backend
# This script helps set up the Docker environment

set -e

echo "🚀 Setting up Trevel Admin Backend with Docker..."

# Check if .env file exists
if [ ! -f .env ]; then
    echo "📝 Creating .env file from .env.example..."
    cp .env.example .env
    echo "⚠️  Please update .env file with your configuration before continuing!"
fi

# Create uploads directory if it doesn't exist
if [ ! -d "uploads" ]; then
    echo "📁 Creating uploads directory..."
    mkdir -p uploads
    chmod 755 uploads
fi

# Start database only first
echo "🗄️  Starting PostgreSQL database..."
docker-compose up -d db

# Wait for database to be ready
echo "⏳ Waiting for database to be ready..."
sleep 5

# Check if database is ready
until docker-compose exec -T db pg_isready -U trevel_admin -d trevel_admin > /dev/null 2>&1; do
    echo "⏳ Database is not ready yet, waiting..."
    sleep 2
done

echo "✅ Database is ready!"

# Run migrations
echo "🔄 Running database migrations..."
docker-compose run --rm backend npx prisma migrate deploy

# Or for development:
# docker-compose run --rm backend npm run prisma:migrate

echo "✅ Setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Update .env file with your configuration"
echo "2. Start all services: docker-compose up -d"
echo "3. View logs: docker-compose logs -f"
echo "4. Stop services: docker-compose down"

