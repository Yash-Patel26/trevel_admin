#!/bin/sh
# Don't use set -e here, we want to continue even if migrations fail

echo "=========================================="
echo "🚀 Starting Trevel Backend Application..."
echo "=========================================="
echo ""

# Check if DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
  echo "⚠️  WARNING: DATABASE_URL environment variable is not set!"
  echo "⚠️  Migrations will be skipped."
  echo ""
else
  echo "✅ DATABASE_URL is configured"
  echo ""
fi

# Run Prisma migrations (for production deployments)
echo "🗄️  Running Prisma migrations..."
echo "Command: npx prisma migrate deploy"
echo ""

MIGRATION_OUTPUT=$(npx prisma migrate deploy 2>&1)
MIGRATION_EXIT_CODE=$?

if [ $MIGRATION_EXIT_CODE -eq 0 ]; then
  echo "✅ Prisma migrations completed successfully"
  echo "$MIGRATION_OUTPUT" | grep -E "Applied|migration|No pending" || echo "$MIGRATION_OUTPUT"
else
  echo "⚠️  Migration command exited with code: $MIGRATION_EXIT_CODE"
  echo "Migration output:"
  echo "$MIGRATION_OUTPUT"
  echo ""
  
  # Check migration status
  echo "📊 Checking migration status..."
  STATUS_OUTPUT=$(npx prisma migrate status 2>&1)
  echo "$STATUS_OUTPUT"
  
  if echo "$STATUS_OUTPUT" | grep -qE "Database schema is up to date|No pending migrations|All migrations have been applied"; then
    echo "✅ Database schema is up to date (migrations already applied)"
  else
    echo "⚠️  Migration may have failed, but continuing with startup..."
    echo "⚠️  Check database connection and logs if you encounter errors"
  fi
fi
echo ""

# Generate Prisma client if needed (should already be generated in Dockerfile, but ensure it exists)
echo "🔧 Ensuring Prisma client is generated..."
if npx prisma generate 2>&1; then
  echo "✅ Prisma client ready"
else
  echo "⚠️  Prisma generate warning (client may already exist)"
fi
echo ""

# Start application
echo "=========================================="
echo "🚀 Starting application server..."
echo "=========================================="
echo ""
exec "$@"
