#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║      EC2 Server Cleanup Script        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Configuration
CONTAINER_NAME="trevel_backend"
REDIS_CONTAINER="trevel_redis"
IMAGE_NAME="trevel-backend"

# Step 1: Stop all containers
echo -e "${YELLOW}🛑 Stopping all containers...${NC}"
sudo docker stop ${CONTAINER_NAME} ${REDIS_CONTAINER} 2>/dev/null || true
echo -e "${GREEN}✅ Containers stopped${NC}"
echo ""

# Step 2: Remove all containers
echo -e "${YELLOW}🗑️  Removing all containers...${NC}"
sudo docker rm -f ${CONTAINER_NAME} ${REDIS_CONTAINER} 2>/dev/null || true
sudo docker container prune -f 2>/dev/null || true
echo -e "${GREEN}✅ Containers removed${NC}"
echo ""

# Step 3: Remove old/dangling images
echo -e "${YELLOW}🗑️  Removing old Docker images...${NC}"
sudo docker rmi ${IMAGE_NAME}:latest 2>/dev/null || true
sudo docker image prune -af 2>/dev/null || true
echo -e "${GREEN}✅ Old images removed${NC}"
echo ""

# Step 4: Clean up build cache
echo -e "${YELLOW}🧹 Cleaning Docker build cache...${NC}"
sudo docker builder prune -af 2>/dev/null || true
echo -e "${GREEN}✅ Build cache cleaned${NC}"
echo ""

# Step 5: Clean up unused volumes (be careful - this removes unused volumes)
echo -e "${YELLOW}🧹 Cleaning unused volumes...${NC}"
echo -e "${YELLOW}⚠️  Note: Only unused volumes will be removed${NC}"
sudo docker volume prune -f 2>/dev/null || true
echo -e "${GREEN}✅ Unused volumes cleaned${NC}"
echo ""

# Step 6: System-wide cleanup
echo -e "${YELLOW}🧹 Running system-wide cleanup...${NC}"
sudo docker system prune -af --volumes 2>/dev/null || true
echo -e "${GREEN}✅ System cleanup complete${NC}"
echo ""

# Step 7: Show final status
echo -e "${BLUE}📊 Final Docker Status:${NC}"
echo ""
echo -e "${YELLOW}Containers:${NC}"
sudo docker ps -a
echo ""
echo -e "${YELLOW}Images:${NC}"
sudo docker images
echo ""
echo -e "${YELLOW}Disk Usage:${NC}"
sudo docker system df
echo ""

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ Cleanup Complete! ✅             ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"

