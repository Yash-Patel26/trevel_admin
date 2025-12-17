#!/bin/sh
# Database initialization script
# This runs inside the Docker container

set -e

echo "🔄 Waiting for database to be ready..."

# Wait for database
until npx prisma db push --skip-generate > /dev/null 2>&1; do
  echo "⏳ Database is not ready yet, waiting..."
  sleep 2
done

echo "✅ Database is ready!"
echo "🔄 Running migrations..."

# Run migrations
npx prisma migrate deploy || npx prisma db push --skip-generate

echo "✅ Migrations complete!"

