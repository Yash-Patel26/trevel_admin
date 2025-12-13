#!/bin/bash

# Trevel Backend - Docker Deployment Script for Testing
# This script builds and deploys the backend with PostgreSQL and Redis

set -e

echo "🚀 Starting Trevel Backend Deployment for Testing..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the local IP address
get_local_ip() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        LOCAL_IP=$(ipconfig getifaddr en0 || ipconfig getifaddr en1)
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        LOCAL_IP=$(hostname -I | awk '{print $1}')
    else
        # Windows (WSL or Git Bash)
        LOCAL_IP=$(ipconfig.exe | grep 'IPv4' | grep -oP '(\d+\.){3}\d+' | head -1)
    fi
    echo "$LOCAL_IP"
}

# Stop and remove existing containers
echo -e "${BLUE}📦 Stopping existing containers...${NC}"
docker-compose -f docker-compose.test.yml down

# Build the backend image
echo -e "${BLUE}🔨 Building backend Docker image...${NC}"
docker-compose -f docker-compose.test.yml build --no-cache

# Start all services
echo -e "${BLUE}🚀 Starting services (PostgreSQL, Redis, Backend)...${NC}"
docker-compose -f docker-compose.test.yml up -d

# Wait for services to be healthy
echo -e "${YELLOW}⏳ Waiting for services to be ready...${NC}"
sleep 10

# Check service health
echo -e "${BLUE}🏥 Checking service health...${NC}"
docker-compose -f docker-compose.test.yml ps

# Get local IP
LOCAL_IP=$(get_local_ip)

# Create test customer
echo -e "${BLUE}👤 Creating test customer...${NC}"
docker-compose -f docker-compose.test.yml exec -T postgres psql -U trevel -d trevel_db << 'EOF'
DO $$
DECLARE
    customer_exists BOOLEAN;
    customer_id TEXT;
BEGIN
    SELECT EXISTS(SELECT 1 FROM "Customer" WHERE mobile = '+919876543210') INTO customer_exists;
    
    IF NOT customer_exists THEN
        INSERT INTO "Customer" (id, name, mobile, email, status)
        VALUES (
            gen_random_uuid(),
            'Test User',
            '+919876543210',
            'testuser@trevel.com',
            'active'
        )
        RETURNING id INTO customer_id;
        RAISE NOTICE 'Test customer created with ID: %', customer_id;
    ELSE
        RAISE NOTICE 'Test customer already exists';
    END IF;
END $$;
EOF

# Display deployment information
echo ""
echo -e "${GREEN}✅ Deployment Complete!${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}📱 Mobile App Configuration${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Update your Flutter app's API constants:"
echo ""
echo -e "${YELLOW}For Android Emulator:${NC}"
echo "  baseUrl: http://10.0.2.2:4000/api/mobile"
echo ""
echo -e "${YELLOW}For iOS Simulator:${NC}"
echo "  baseUrl: http://localhost:4000/api/mobile"
echo ""
echo -e "${YELLOW}For Physical Devices:${NC}"
echo "  baseUrl: http://${LOCAL_IP}:4000/api/mobile"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}🧪 Test Credentials${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Mobile: +919876543210"
echo "  Email:  testuser@trevel.com"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}🔗 Service URLs${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Backend API:  http://localhost:4000"
echo "  Health Check: http://localhost:4000/healthz"
echo "  PostgreSQL:   localhost:5432"
echo "  Redis:        localhost:6379"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}📋 Useful Commands${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  View logs:        docker-compose -f docker-compose.test.yml logs -f"
echo "  View backend logs: docker-compose -f docker-compose.test.yml logs -f backend"
echo "  Stop services:    docker-compose -f docker-compose.test.yml down"
echo "  Restart backend:  docker-compose -f docker-compose.test.yml restart backend"
echo "  Access DB:        docker-compose -f docker-compose.test.yml exec postgres psql -U trevel -d trevel_db"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
