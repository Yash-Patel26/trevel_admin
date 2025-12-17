#!/bin/bash

# Quick deployment script for manual use
# This is a simplified version for quick updates

set -e

echo "🚀 Quick Deploy Script"
echo "====================="

# Check if we're in the backend directory
if [ ! -f "package.json" ]; then
  echo "❌ Error: Must be run from backend directory"
  exit 1
fi

# Pull latest code
echo "📥 Pulling latest code..."
git pull origin main

# Install dependencies if package.json changed
if git diff HEAD@{1} --name-only | grep -q "package.json"; then
  echo "📦 Installing dependencies..."
  npm ci
fi

# Generate Prisma client if schema changed
if git diff HEAD@{1} --name-only | grep -q "prisma/schema.prisma"; then
  echo "🔄 Regenerating Prisma client..."
  npx prisma generate
fi

# Build TypeScript
echo "🔨 Building..."
npm run build

# Run deployment
echo "🚢 Deploying..."
./scripts/deploy.sh

echo "✅ Quick deploy completed!"
