#!/bin/bash

# Docker Cleanup Script
# Safely removes unused Docker resources

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧹 Docker Cleanup Script${NC}"
echo "========================="
echo ""

# Function to show disk usage
show_disk_usage() {
    echo -e "${YELLOW}📊 Current Disk Usage:${NC}"
    df -h / | awk 'NR==1 || /\/$/'
    echo ""
    echo -e "${YELLOW}🐳 Docker Disk Usage:${NC}"
    docker system df
    echo ""
}

# Show initial disk usage
echo -e "${BLUE}Before Cleanup:${NC}"
show_disk_usage

# Confirm cleanup
echo -e "${YELLOW}⚠️  This will remove:${NC}"
echo "  - Stopped containers"
echo "  - Unused networks"
echo "  - Dangling images"
echo "  - Build cache"
echo ""
echo -e "${RED}Active containers and volumes will NOT be removed${NC}"
echo ""

read -p "Continue with cleanup? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Cleanup cancelled${NC}"
    exit 0
fi

echo ""
echo -e "${GREEN}🚀 Starting cleanup...${NC}"
echo ""

# 1. Remove stopped containers
echo -e "${YELLOW}1. Removing stopped containers...${NC}"
STOPPED_CONTAINERS=$(docker ps -aq -f status=exited)
if [ -n "$STOPPED_CONTAINERS" ]; then
    docker rm $STOPPED_CONTAINERS
    echo -e "${GREEN}✅ Removed stopped containers${NC}"
else
    echo -e "${GREEN}✅ No stopped containers to remove${NC}"
fi
echo ""

# 2. Remove dangling images
echo -e "${YELLOW}2. Removing dangling images...${NC}"
DANGLING_IMAGES=$(docker images -f "dangling=true" -q)
if [ -n "$DANGLING_IMAGES" ]; then
    docker rmi $DANGLING_IMAGES
    echo -e "${GREEN}✅ Removed dangling images${NC}"
else
    echo -e "${GREEN}✅ No dangling images to remove${NC}"
fi
echo ""

# 3. Remove unused networks
echo -e "${YELLOW}3. Removing unused networks...${NC}"
docker network prune -f
echo -e "${GREEN}✅ Removed unused networks${NC}"
echo ""

# 4. Remove build cache
echo -e "${YELLOW}4. Removing build cache...${NC}"
docker builder prune -f
echo -e "${GREEN}✅ Removed build cache${NC}"
echo ""

# 5. Remove old images (keep last 3 versions)
echo -e "${YELLOW}5. Removing old trevel_backend images (keeping last 3)...${NC}"
OLD_IMAGES=$(docker images trevel_backend --format "{{.ID}}" | tail -n +4)
if [ -n "$OLD_IMAGES" ]; then
    docker rmi $OLD_IMAGES 2>/dev/null || echo "Some images are in use, skipping..."
    echo -e "${GREEN}✅ Removed old images${NC}"
else
    echo -e "${GREEN}✅ No old images to remove${NC}"
fi
echo ""

# Show final disk usage
echo -e "${BLUE}After Cleanup:${NC}"
show_disk_usage

echo -e "${GREEN}🎉 Cleanup completed!${NC}"
echo ""

# Show what's still running
echo -e "${YELLOW}📋 Active Containers:${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
echo ""

echo -e "${YELLOW}💾 Volumes (preserved):${NC}"
docker volume ls
echo ""

echo -e "${GREEN}✅ Your running containers and data are safe!${NC}"
