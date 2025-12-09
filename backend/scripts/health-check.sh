#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

CONTAINER_NAME="trevel_admin_backend"
API_URL="http://localhost:4000"

echo -e "${YELLOW}🏥 Running health checks...${NC}\n"

# Check 1: Container is running
echo -n "1. Container status... "
if docker ps -q -f name=^/${CONTAINER_NAME}$ | grep -q .; then
  echo -e "${GREEN}✅ Running${NC}"
else
  echo -e "${RED}❌ Not running${NC}"
  exit 1
fi

# Check 2: Health endpoint
echo -n "2. Health endpoint... "
HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" ${API_URL}/healthz)
if [ "$HEALTH_RESPONSE" = "200" ]; then
  echo -e "${GREEN}✅ OK (200)${NC}"
else
  echo -e "${RED}❌ Failed (${HEALTH_RESPONSE})${NC}"
  exit 1
fi

# Check 3: API is responding
echo -n "3. API response... "
API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" ${API_URL})
if [ "$API_RESPONSE" = "200" ] || [ "$API_RESPONSE" = "404" ]; then
  echo -e "${GREEN}✅ OK (${API_RESPONSE})${NC}"
else
  echo -e "${RED}❌ Failed (${API_RESPONSE})${NC}"
  exit 1
fi

# Check 4: Database connection
echo -n "4. Database connection... "
DB_CHECK=$(docker exec ${CONTAINER_NAME} npx prisma db execute --stdin <<< "SELECT 1" 2>&1)
if echo "$DB_CHECK" | grep -q "error"; then
  echo -e "${RED}❌ Failed${NC}"
  echo -e "${YELLOW}   Error: ${DB_CHECK}${NC}"
  exit 1
else
  echo -e "${GREEN}✅ OK${NC}"
fi

# Check 5: Container logs (check for errors)
echo -n "5. Container logs... "
ERROR_COUNT=$(docker logs ${CONTAINER_NAME} --tail 100 2>&1 | grep -i "error" | wc -l)
if [ "$ERROR_COUNT" -gt 5 ]; then
  echo -e "${YELLOW}⚠️  Warning: ${ERROR_COUNT} errors in recent logs${NC}"
else
  echo -e "${GREEN}✅ OK (${ERROR_COUNT} errors)${NC}"
fi

# Check 6: Memory usage
echo -n "6. Memory usage... "
MEMORY_USAGE=$(docker stats ${CONTAINER_NAME} --no-stream --format "{{.MemPerc}}" | sed 's/%//')
if (( $(echo "$MEMORY_USAGE > 90" | bc -l) )); then
  echo -e "${YELLOW}⚠️  High (${MEMORY_USAGE}%)${NC}"
else
  echo -e "${GREEN}✅ OK (${MEMORY_USAGE}%)${NC}"
fi

# Check 7: Disk space
echo -n "7. Disk space... "
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 85 ]; then
  echo -e "${YELLOW}⚠️  High (${DISK_USAGE}%)${NC}"
else
  echo -e "${GREEN}✅ OK (${DISK_USAGE}%)${NC}"
fi

echo -e "\n${GREEN}🎉 All health checks passed!${NC}"

# Display container info
echo -e "\n${YELLOW}📊 Container Information:${NC}"
docker ps -f name=${CONTAINER_NAME} --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Display recent logs
echo -e "\n${YELLOW}📋 Recent Logs (last 10 lines):${NC}"
docker logs ${CONTAINER_NAME} --tail 10

exit 0
