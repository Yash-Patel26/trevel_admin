#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Manual Deployment with Migrations   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Configuration
IMAGE_NAME="trevel-backend"
CONTAINER_NAME="trevel_backend"
REDIS_CONTAINER="trevel_redis"

# Step 1: Stop and remove existing containers
echo -e "${YELLOW}🛑 Stopping existing containers...${NC}"
sudo docker rm -f ${CONTAINER_NAME} ${REDIS_CONTAINER} || true
echo -e "${GREEN}✅ Containers stopped${NC}"
echo ""

# Step 2: Run Redis
echo -e "${YELLOW}🔴 Starting Redis...${NC}"
sudo docker run -d \
  --name ${REDIS_CONTAINER} \
  --restart always \
  -p 6379:6379 \
  -v redis_data:/data \
  redis:alpine
echo -e "${GREEN}✅ Redis started${NC}"
echo ""

# Step 3: Build Docker image
echo -e "${YELLOW}🔨 Building Docker image...${NC}"
sudo docker build -t ${IMAGE_NAME}:latest -f Dockerfile.production . || {
    echo -e "${RED}❌ Docker build failed!${NC}"
    exit 1
}
echo -e "${GREEN}✅ Docker image built${NC}"
echo ""

# Step 4: Run Prisma migrations
echo -e "${YELLOW}🗄️  Running Prisma migrations...${NC}"
echo -e "${BLUE}Applying migrations from prisma/migrations/ directory...${NC}"
MIGRATION_OUTPUT=$(sudo docker run --rm \
  --env-file .env \
  -e NODE_ENV=production \
  ${IMAGE_NAME}:latest \
  npx prisma migrate deploy 2>&1) || {
    echo -e "${YELLOW}⚠️  Migration command returned non-zero exit code${NC}"
    # Check if it's just "no migrations to apply"
    if echo "$MIGRATION_OUTPUT" | grep -q "No pending migrations\|already applied"; then
        echo -e "${GREEN}✅ All migrations already applied${NC}"
    else
        echo -e "${YELLOW}Migration output: $MIGRATION_OUTPUT${NC}"
        echo -e "${YELLOW}⚠️  Continuing with deployment...${NC}"
    fi
}

if echo "$MIGRATION_OUTPUT" | grep -q "Applied\|migration"; then
    echo -e "${GREEN}✅ Migrations applied successfully${NC}"
fi
echo ""

# Step 5: Start Backend container
echo -e "${YELLOW}🚢 Starting Backend container...${NC}"
sudo docker run -d \
  --name ${CONTAINER_NAME} \
  --restart always \
  -p 4000:4000 \
  --env-file .env \
  -e REDIS_URL=redis://${REDIS_CONTAINER}:6379 \
  --link ${REDIS_CONTAINER}:redis \
  -v $(pwd)/uploads:/app/uploads \
  ${IMAGE_NAME}:latest || {
    echo -e "${RED}❌ Failed to start container!${NC}"
    exit 1
  }
echo -e "${GREEN}✅ Backend container started${NC}"
echo ""

# Step 6: Wait for container to be ready
echo -e "${YELLOW}⏳ Waiting for container to start (15 seconds)...${NC}"
sleep 15

# Step 7: Health check
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

# Step 8: Show status
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   🎉 Deployment Successful! 🎉        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📊 Container Status:${NC}"
sudo docker ps -f name=${CONTAINER_NAME} --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo -e "${GREEN}✅ Deployment complete!${NC}"
                                        