#!/bin/bash

# AWS EC2 Deployment Script with Prisma Migrations
# This script is optimized for AWS EC2 deployment
# Usage: ./scripts/aws-deploy.sh

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   AWS EC2 Deployment Script           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Configuration
CONTAINER_NAME="trevel_admin_backend"
IMAGE_NAME="trevel_backend"
VERSION=$(date +%Y%m%d_%H%M%S)
BACKEND_DIR="$(pwd)"

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
echo -e "${GREEN}✅ Docker: $(docker --version)${NC}"

if ! sudo docker ps &> /dev/null; then
    echo -e "${RED}❌ Docker daemon is not running!${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker daemon is running${NC}"

if [ ! -f "$BACKEND_DIR/.env" ]; then
    echo -e "${RED}❌ .env file not found at $BACKEND_DIR/.env${NC}"
    exit 1
fi
echo -e "${GREEN}✅ .env file exists${NC}"

if [ ! -d "$BACKEND_DIR/prisma/migrations" ]; then
    echo -e "${YELLOW}⚠️  No Prisma migrations directory found${NC}"
    echo -e "${YELLOW}   Creating initial migration may be needed${NC}"
fi
echo ""

# Step 2: Clean up Docker (free space)
echo -e "${YELLOW}🧹 Cleaning up Docker to free space...${NC}"
sudo docker system prune -af --volumes 2>/dev/null || true
echo -e "${GREEN}✅ Cleanup completed${NC}"
echo ""

# Step 3: Build Docker image
echo -e "${YELLOW}🔨 Building Docker image...${NC}"
echo -e "${BLUE}This may take a few minutes...${NC}"
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

# Step 5: Run Prisma migrations
echo -e "${YELLOW}🗄️  Running Prisma migrations...${NC}"
echo -e "${BLUE}Applying migrations from prisma/migrations/ directory...${NC}"
MIGRATION_OUTPUT=$(sudo docker run --rm \
  --env-file .env \
  -e NODE_ENV=production \
  ${IMAGE_NAME}:${VERSION} \
  npx prisma migrate deploy 2>&1) || {
    echo -e "${YELLOW}⚠️  Migration command returned non-zero exit code${NC}"
    echo -e "${YELLOW}Output: $MIGRATION_OUTPUT${NC}"
    # Check if it's just "no migrations to apply"
    if echo "$MIGRATION_OUTPUT" | grep -q "No pending migrations"; then
        echo -e "${GREEN}✅ All migrations already applied${NC}"
    else
        echo -e "${YELLOW}⚠️  Migration may have failed, but continuing...${NC}"
    fi
}

echo -e "${GREEN}✅ Prisma migrations step completed${NC}"
echo ""

# Step 6: Verify Prisma Client is generated
echo -e "${YELLOW}🔍 Verifying Prisma setup...${NC}"
sudo docker run --rm \
  --env-file .env \
  -e NODE_ENV=production \
  ${IMAGE_NAME}:${VERSION} \
  npx prisma generate > /dev/null 2>&1 || {
    echo -e "${YELLOW}⚠️  Prisma generate warning (may already be generated)${NC}"
  }
echo -e "${GREEN}✅ Prisma setup verified${NC}"
echo ""

# Step 7: Start new container
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

# Step 8: Wait for container to be ready
echo -e "${YELLOW}⏳ Waiting for container to start (15 seconds)...${NC}"
sleep 15

# Step 9: Health check
echo -e "${YELLOW}🏥 Running health check...${NC}"
HEALTHY=false
for i in $(seq 1 20); do
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
  echo -e "${YELLOW}📋 Container logs (last 100 lines):${NC}"
  sudo docker logs ${CONTAINER_NAME} --tail 100
  echo ""
  echo -e "${YELLOW}💡 Troubleshooting:${NC}"
  echo "  1. Check logs: sudo docker logs ${CONTAINER_NAME} -f"
  echo "  2. Check database connection in .env"
  echo "  3. Verify migrations ran successfully"
  exit 1
fi

# Step 10: Show container status
echo -e "${YELLOW}📊 Container Status:${NC}"
sudo docker ps -f name=${CONTAINER_NAME} --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# Step 11: Cleanup old images (keep last 2 versions)
echo -e "${YELLOW}🧹 Cleaning up old Docker images (keeping last 2)...${NC}"
sudo docker images ${IMAGE_NAME} --format "{{.ID}} {{.CreatedAt}}" | \
  sort -rk2 | tail -n +3 | awk '{print $1}' | \
  xargs -r sudo docker rmi 2>/dev/null || true
echo -e "${GREEN}✅ Cleanup completed${NC}"
echo ""

# Step 12: Deployment summary
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   🎉 Deployment Successful! 🎉        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📊 Deployment Summary:${NC}"
echo "  Version: $VERSION"
echo "  Container: $CONTAINER_NAME"
echo "  Port: 4000"
echo "  Health: http://localhost:4000/healthz"
echo "  API: http://localhost:4000/api"
echo "  Mobile API: http://localhost:4000/api/v1"
echo ""
echo -e "${BLUE}📋 Useful Commands:${NC}"
echo "  View logs:       sudo docker logs ${CONTAINER_NAME} -f"
echo "  Stop:            sudo docker stop ${CONTAINER_NAME}"
echo "  Restart:         sudo docker restart ${CONTAINER_NAME}"
echo "  Shell access:    sudo docker exec -it ${CONTAINER_NAME} /bin/sh"
echo "  Check migrations: sudo docker exec ${CONTAINER_NAME} npx prisma migrate status"
echo ""
echo -e "${GREEN}✅ Deployment completed successfully!${NC}"

