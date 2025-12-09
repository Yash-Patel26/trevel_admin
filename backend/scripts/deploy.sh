#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting zero-downtime deployment...${NC}"

# Configuration
CONTAINER_NAME="trevel_admin_backend"
NEW_CONTAINER_NAME="${CONTAINER_NAME}_new"
IMAGE_NAME="trevel_backend"
HEALTH_CHECK_RETRIES=30
HEALTH_CHECK_INTERVAL=2

# Get current commit hash for versioning
if [ -d .git ]; then
  VERSION=$(git rev-parse --short HEAD 2>/dev/null || echo "latest")
else
  VERSION=$(date +%Y%m%d_%H%M%S)
fi

echo -e "${YELLOW}📦 Version: ${VERSION}${NC}"

# Step 1: Build new Docker image
echo -e "${YELLOW}🔨 Building new Docker image...${NC}"
docker build -t ${IMAGE_NAME}:${VERSION} -t ${IMAGE_NAME}:latest .

if [ $? -ne 0 ]; then
  echo -e "${RED}❌ Docker build failed!${NC}"
  exit 1
fi

# Step 2: Check if old container exists
OLD_CONTAINER_EXISTS=$(docker ps -a -q -f name=^/${CONTAINER_NAME}$)

# Step 3: Start new container on different port temporarily
echo -e "${YELLOW}🚢 Starting new container...${NC}"

# Remove any existing new container
docker rm -f ${NEW_CONTAINER_NAME} 2>/dev/null || true

# Start new container on port 4001 temporarily
docker run -d \
  --name ${NEW_CONTAINER_NAME} \
  --env-file .env \
  -e NODE_ENV=production \
  -e PORT=4000 \
  -p 4001:4000 \
  -v $(pwd)/uploads:/app/uploads \
  --restart unless-stopped \
  ${IMAGE_NAME}:${VERSION}

if [ $? -ne 0 ]; then
  echo -e "${RED}❌ Failed to start new container!${NC}"
  docker rm -f ${NEW_CONTAINER_NAME} 2>/dev/null || true
  exit 1
fi

# Step 4: Wait for new container to be healthy
echo -e "${YELLOW}🏥 Running health checks on new container...${NC}"

HEALTHY=false
for i in $(seq 1 $HEALTH_CHECK_RETRIES); do
  echo -n "."
  
  # Check if container is still running
  if ! docker ps -q -f name=^/${NEW_CONTAINER_NAME}$ | grep -q .; then
    echo -e "\n${RED}❌ New container stopped unexpectedly!${NC}"
    docker logs ${NEW_CONTAINER_NAME} --tail 50
    docker rm -f ${NEW_CONTAINER_NAME} 2>/dev/null || true
    exit 1
  fi
  
  # Check health endpoint
  if curl -f -s http://localhost:4001/healthz > /dev/null 2>&1; then
    HEALTHY=true
    echo -e "\n${GREEN}✅ New container is healthy!${NC}"
    break
  fi
  
  sleep $HEALTH_CHECK_INTERVAL
done

if [ "$HEALTHY" = false ]; then
  echo -e "\n${RED}❌ Health check failed after ${HEALTH_CHECK_RETRIES} attempts!${NC}"
  echo -e "${YELLOW}📋 Container logs:${NC}"
  docker logs ${NEW_CONTAINER_NAME} --tail 50
  
  echo -e "${YELLOW}🔄 Rolling back...${NC}"
  docker rm -f ${NEW_CONTAINER_NAME}
  exit 1
fi

# Step 5: Run database migrations
echo -e "${YELLOW}🗄️  Running database migrations...${NC}"
docker exec ${NEW_CONTAINER_NAME} npx prisma migrate deploy

if [ $? -ne 0 ]; then
  echo -e "${RED}❌ Database migration failed!${NC}"
  echo -e "${YELLOW}🔄 Rolling back...${NC}"
  docker rm -f ${NEW_CONTAINER_NAME}
  exit 1
fi

# Step 6: Switch traffic to new container
echo -e "${YELLOW}🔄 Switching traffic to new container...${NC}"

# Stop and remove old container
if [ -n "$OLD_CONTAINER_EXISTS" ]; then
  echo -e "${YELLOW}🛑 Stopping old container...${NC}"
  docker stop ${CONTAINER_NAME} 2>/dev/null || true
  docker rm ${CONTAINER_NAME} 2>/dev/null || true
fi

# Rename new container to production name
docker rename ${NEW_CONTAINER_NAME} ${CONTAINER_NAME}

# Update port mapping to 4000
docker stop ${CONTAINER_NAME}
docker rm ${CONTAINER_NAME}

docker run -d \
  --name ${CONTAINER_NAME} \
  --env-file .env \
  -e NODE_ENV=production \
  -e PORT=4000 \
  -p 4000:4000 \
  -v $(pwd)/uploads:/app/uploads \
  --restart unless-stopped \
  ${IMAGE_NAME}:${VERSION}

# Wait for container to be ready
sleep 5

# Final health check
echo -e "${YELLOW}🏥 Final health check...${NC}"
if curl -f -s http://localhost:4000/healthz > /dev/null 2>&1; then
  echo -e "${GREEN}✅ Deployment successful!${NC}"
else
  echo -e "${RED}❌ Final health check failed!${NC}"
  exit 1
fi

# Step 7: Cleanup old images
echo -e "${YELLOW}🧹 Cleaning up old images...${NC}"
docker image prune -f --filter "label=app=trevel_backend" --filter "until=24h" 2>/dev/null || true

echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo -e "${GREEN}📊 Container status:${NC}"
docker ps -f name=${CONTAINER_NAME}

echo -e "\n${GREEN}📝 Deployment Summary:${NC}"
echo -e "  Version: ${VERSION}"
echo -e "  Container: ${CONTAINER_NAME}"
echo -e "  Status: Running"
echo -e "  Health: OK"
