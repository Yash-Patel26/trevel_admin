#!/bin/bash

set -e
set -x  # Verbose output for debugging

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting simplified deployment...${NC}"

# Configuration
CONTAINER_NAME="trevel_admin_backend"
IMAGE_NAME="trevel_backend"
VERSION=$(date +%Y%m%d_%H%M%S)

echo -e "${YELLOW}📦 Version: ${VERSION}${NC}"

# Step 0: Free space before build
echo -e "${YELLOW}🧹 Pruning unused Docker data before build...${NC}"
sudo docker system prune -af 2>/dev/null || true

# Step 1: Build new Docker image
echo -e "${YELLOW}🔨 Building Docker image...${NC}"
sudo docker build -t ${IMAGE_NAME}:${VERSION} -t ${IMAGE_NAME}:latest .

if [ $? -ne 0 ]; then
  echo -e "${RED}❌ Docker build failed!${NC}"
  exit 1
fi

# Step 2: Stop and remove old container if it exists
echo -e "${YELLOW}� Stopping old container...${NC}"
sudo docker stop ${CONTAINER_NAME} 2>/dev/null || true
sudo docker rm ${CONTAINER_NAME} 2>/dev/null || true

# Step 3: Run database migrations
echo -e "${YELLOW}🗄️  Running database migrations...${NC}"
sudo docker run --rm \
  --env-file .env \
  -e NODE_ENV=production \
  ${IMAGE_NAME}:${VERSION} \
  npx prisma migrate deploy

if [ $? -ne 0 ]; then
  echo -e "${RED}❌ Database migration failed!${NC}"
  exit 1
fi

# Step 4: Start new container
echo -e "${YELLOW}� Starting new container...${NC}"
sudo docker run -d \
  --name ${CONTAINER_NAME} \
  --env-file .env \
  -e NODE_ENV=production \
  -e PORT=4000 \
  -p 4000:4000 \
  -v $(pwd)/uploads:/app/uploads \
  --restart unless-stopped \
  ${IMAGE_NAME}:${VERSION}

if [ $? -ne 0 ]; then
  echo -e "${RED}❌ Failed to start container!${NC}"
  exit 1
fi

# Step 5: Wait for container to be ready
echo -e "${YELLOW}⏳ Waiting for container to start...${NC}"
sleep 10

# Step 6: Health check
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

if [ "$HEALTHY" = false ]; then
  echo -e "\n${RED}❌ Health check failed!${NC}"
  echo -e "${YELLOW}📋 Container logs:${NC}"
  sudo docker logs ${CONTAINER_NAME} --tail 50
  exit 1
fi

# Step 7: Cleanup old images and stopped containers
echo -e "${YELLOW}🧹 Cleaning up old images and containers...${NC}"
sudo docker image prune -f 2>/dev/null || true
sudo docker container prune -f 2>/dev/null || true

echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo -e "${GREEN}📊 Container status:${NC}"
sudo docker ps -f name=${CONTAINER_NAME}
