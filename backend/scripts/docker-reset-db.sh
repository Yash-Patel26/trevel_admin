#!/bin/sh
# Database Reset and Seed Script for Docker
# This script truncates all data and reseeds the database

echo "🗑️  Resetting database..."
echo ""

# Run the reset and seed script
node /app/scripts/reset-and-seed.js

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Database reset and seeded successfully!"
    echo ""
    echo "📝 You can now log in with:"
    echo "   Email: admin@trevel.in"
    echo "   Password: 112233"
    echo ""
else
    echo ""
    echo "❌ Database reset failed!"
    echo ""
    exit 1
fi
