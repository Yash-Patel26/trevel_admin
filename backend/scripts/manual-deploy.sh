#!/bin/bash

# Manual Deployment Script for EC2
# Run this script directly on your EC2 instance after uploading your code

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Manual Backend Deployment Script    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Configuration
CONTAINER_NAME="trevel_admin_backend"
IMAGE_NAME="trevel_backend"
VERSION=$(date +%Y%m%d_%H%M%S)
BACKEND_DIR="$HOME/backend"

echo -e "${YELLOW}📋 Deployment Configuration:${NC}"
echo "  Container Name: $CONTAINER_NAME"
echo "  Image Name: $IMAGE_NAME"
echo "  Version: $VERSION"
echo "  Backend Directory: $BACKEND_DIR"
echo ""

# Step 1: Check prerequisites
echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed!${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker is installed: $(docker --version)${NC}"

if ! sudo docker ps &> /dev/null; then
    echo -e "${RED}❌ Docker daemon is not running!${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker daemon is running${NC}"

if [ ! -f "$BACKEND_DIR/.env" ]; then
    echo -e "${RED}❌ .env file not found at $BACKEND_DIR/.env${NC}"
    echo -e "${YELLOW}Please create the .env file before deploying${NC}"
    exit 1
fi
echo -e "${GREEN}✅ .env file exists${NC}"

echo ""

# Step 2: Navigate to backend directory
echo -e "${YELLOW}📂 Navigating to backend directory...${NC}"
cd "$BACKEND_DIR" || {
    echo -e "${RED}❌ Failed to navigate to $BACKEND_DIR${NC}"
    exit 1
}
echo -e "${GREEN}✅ Current directory: $(pwd)${NC}"
echo ""

# Step 3: Build Docker image
echo -e "${YELLOW}🔨 Building Docker image...${NC}"
sudo docker build -t ${IMAGE_NAME}:${VERSION} -t ${IMAGE_NAME}:latest . || {
    echo -e "${RED}❌ Docker build failed!${NC}"
    exit 1
}
echo -e "${GREEN}✅ Docker image built successfully${NC}"
echo ""

# Step 4: Stop and remove old container
echo -e "${YELLOW}🛑 Stopping old container (if exists)...${NC}"
if sudo docker ps -a | grep -q ${CONTAINER_NAME}; then
    sudo docker stop ${CONTAINER_NAME} 2>/dev/null || true
    sudo docker rm ${CONTAINER_NAME} 2>/dev/null || true
    echo -e "${GREEN}✅ Old container stopped and removed${NC}"
else
    echo -e "${BLUE}ℹ️  No existing container found${NC}"
fi
echo ""

# Step 5: Run database migrations
echo -e "${YELLOW}🗄️  Running database migrations...${NC}"
sudo docker run --rm \
  --env-file .env \
  -e NODE_ENV=production \
  ${IMAGE_NAME}:${VERSION} \
  npx prisma migrate deploy || {
    echo -e "${RED}❌ Database migration failed!${NC}"
    echo -e "${YELLOW}Continuing anyway... (migrations might already be applied)${NC}"
}
echo -e "${GREEN}✅ Database migrations completed${NC}"
echo ""

# Step 6: Start new container
echo -e "${YELLOW}🚢 Starting new container...${NC}"
sudo docker run -d \
  --name ${CONTAINER_NAME} \
  --env-file .env \
  -e NODE_ENV=production \
  -e PORT=4000 \
  -p 4000:4000 \
  -v $(pwd)/uploads:/app/uploads \
  --restart unless-stopped \
  ${IMAGE_NAME}:${VERSION} || {
    echo -e "${RED}❌ Failed to start container!${NC}"
    exit 1
}
echo -e "${GREEN}✅ Container started${NC}"
echo ""

# Step 7: Wait for container to be ready
echo -e "${YELLOW}⏳ Waiting for container to start (10 seconds)...${NC}"
sleep 10

# Step 8: Health check
echo -e "${YELLOW}🏥 Running health check...${NC}"
HEALTHY=false
for i in $(seq 1 15); do
  if curl -f -s http://localhost:4000/healthz > /dev/null 2>&1; then
    HEALTHY=true
    echo -e "${GREEN}✅ Container is healthy!${NC}"
    break
  fi
  echo -n "."
  sleep 2
done
echo ""

if [ "$HEALTHY" = false ]; then
  echo -e "${RED}❌ Health check failed!${NC}"
  echo -e "${YELLOW}📋 Container logs:${NC}"
  sudo docker logs ${CONTAINER_NAME} --tail 50
  exit 1
fi

# Step 9: Cleanup old images
echo -e "${YELLOW}🧹 Cleaning up old Docker images...${NC}"
sudo docker image prune -f 2>/dev/null || true
echo -e "${GREEN}✅ Cleanup completed${NC}"
echo ""

# Step 10: Show deployment summary
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   🎉 Deployment Successful! 🎉        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📊 Deployment Summary:${NC}"
echo "  Version: $VERSION"
echo "  Container: $CONTAINER_NAME"
echo "  Port: 4000"
echo "  Health Endpoint: http://localhost:4000/healthz"
echo ""
echo -e "${BLUE}📋 Container Status:${NC}"
sudo docker ps -f name=${CONTAINER_NAME} --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo -e "${YELLOW}💡 Useful Commands:${NC}"
echo "  View logs:    sudo docker logs ${CONTAINER_NAME} -f"
echo "  Stop:         sudo docker stop ${CONTAINER_NAME}"
echo "  Restart:      sudo docker restart ${CONTAINER_NAME}"
echo "  Shell access: sudo docker exec -it ${CONTAINER_NAME} /bin/sh"
echo ""
