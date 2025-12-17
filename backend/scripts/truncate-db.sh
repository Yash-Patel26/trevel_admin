#!/bin/bash

# RDS Database Truncate Script
# WARNING: This will DELETE ALL DATA from all tables!

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${RED}⚠️  DATABASE TRUNCATE SCRIPT ⚠️${NC}"
echo "===================================="
echo ""
echo -e "${RED}WARNING: This will DELETE ALL DATA from your database!${NC}"
echo ""
echo "This will:"
echo "  ❌ Delete all records from all tables"
echo "  ❌ Reset all sequences/auto-increment counters"
echo "  ✅ Keep the database structure (tables, columns)"
echo ""

read -p "Are you ABSOLUTELY sure? Type 'DELETE ALL DATA' to continue: " -r
echo ""

if [[ ! $REPLY == "DELETE ALL DATA" ]]; then
    echo -e "${YELLOW}Truncate cancelled${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}🗄️  Truncating database...${NC}"
echo ""

# Use Prisma to reset the database
echo -e "${YELLOW}1. Resetting database with Prisma...${NC}"
npx prisma migrate reset --force --skip-seed

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Database truncated successfully!${NC}"
    echo ""
    
    # Optional: Run seed if you want to add initial data
    read -p "Do you want to seed the database with initial data? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}2. Seeding database...${NC}"
        npm run seed
        echo -e "${GREEN}✅ Database seeded!${NC}"
    fi
else
    echo -e "${RED}❌ Failed to truncate database!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 Database operations completed!${NC}"
