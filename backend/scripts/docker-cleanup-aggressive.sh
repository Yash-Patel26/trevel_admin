#!/bin/bash

# AGGRESSIVE Docker Cleanup Script
# WARNING: This will remove EVERYTHING including running containers!
# Use only when you want to completely reset Docker

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${RED}⚠️  AGGRESSIVE DOCKER CLEANUP ⚠️${NC}"
echo "=================================="
echo ""
echo -e "${RED}WARNING: This will remove:${NC}"
echo "  ❌ ALL containers (including running ones)"
echo "  ❌ ALL images"
echo "  ❌ ALL networks (except default)"
echo "  ❌ ALL build cache"
echo "  ⚠️  Volumes will be PRESERVED (use --volumes flag to remove)"
echo ""
echo -e "${YELLOW}This is useful when you want to start fresh.${NC}"
echo ""

read -p "Are you ABSOLUTELY sure? Type 'yes' to continue: " -r
echo ""

if [[ ! $REPLY == "yes" ]]; then
    echo -e "${YELLOW}Cleanup cancelled${NC}"
    exit 0
fi

echo ""
echo -e "${RED}🚀 Starting aggressive cleanup...${NC}"
echo ""

# Stop all running containers
echo -e "${YELLOW}1. Stopping all containers...${NC}"
RUNNING_CONTAINERS=$(docker ps -q)
if [ -n "$RUNNING_CONTAINERS" ]; then
    docker stop $RUNNING_CONTAINERS
    echo -e "${GREEN}✅ Stopped all containers${NC}"
else
    echo -e "${GREEN}✅ No running containers${NC}"
fi
echo ""

# Remove all containers
echo -e "${YELLOW}2. Removing all containers...${NC}"
ALL_CONTAINERS=$(docker ps -aq)
if [ -n "$ALL_CONTAINERS" ]; then
    docker rm -f $ALL_CONTAINERS
    echo -e "${GREEN}✅ Removed all containers${NC}"
else
    echo -e "${GREEN}✅ No containers to remove${NC}"
fi
echo ""

# Remove all images
echo -e "${YELLOW}3. Removing all images...${NC}"
ALL_IMAGES=$(docker images -q)
if [ -n "$ALL_IMAGES" ]; then
    docker rmi -f $ALL_IMAGES
    echo -e "${GREEN}✅ Removed all images${NC}"
else
    echo -e "${GREEN}✅ No images to remove${NC}"
fi
echo ""

# Remove all networks
echo -e "${YELLOW}4. Removing all custom networks...${NC}"
docker network prune -f
echo -e "${GREEN}✅ Removed all custom networks${NC}"
echo ""

# Remove build cache
echo -e "${YELLOW}5. Removing all build cache...${NC}"
docker builder prune -af
echo -e "${GREEN}✅ Removed all build cache${NC}"
echo ""

# Optional: Remove volumes (commented out for safety)
if [[ "$1" == "--volumes" ]]; then
    echo -e "${RED}6. Removing all volumes...${NC}"
    docker volume prune -f
    echo -e "${GREEN}✅ Removed all volumes${NC}"
    echo ""
else
    echo -e "${YELLOW}6. Volumes preserved (use --volumes flag to remove)${NC}"
    echo ""
fi

# Show final state
echo -e "${GREEN}🎉 Aggressive cleanup completed!${NC}"
echo ""

echo -e "${YELLOW}📊 Final State:${NC}"
docker system df
echo ""

echo -e "${GREEN}✅ Docker is now clean!${NC}"
echo -e "${YELLOW}💡 To also remove volumes, run: ./scripts/docker-cleanup-aggressive.sh --volumes${NC}"
