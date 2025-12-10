#!/bin/bash

# Script to update EC2 Security Group with GitHub Actions IP ranges
# This allows GitHub Actions workflows to SSH into EC2 for deployment

set -e

# Configuration
REGION="${AWS_REGION:-ap-south-1}"
SECURITY_GROUP_ID="${EC2_SECURITY_GROUP_ID}"
GITHUB_API_URL="https://api.github.com/meta"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}GitHub Actions Security Group Updater${NC}"
echo "=========================================="
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed${NC}"
    echo "Install it from: https://aws.amazon.com/cli/"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ jq is not installed${NC}"
    echo "Install it: sudo apt-get install jq (Linux) or brew install jq (Mac)"
    exit 1
fi

# Validate security group ID
if [ -z "$SECURITY_GROUP_ID" ]; then
    echo -e "${RED}❌ EC2_SECURITY_GROUP_ID environment variable is not set${NC}"
    echo ""
    echo "Usage:"
    echo "  export EC2_SECURITY_GROUP_ID=sg-xxxxxxxxxxxxx"
    echo "  export AWS_REGION=ap-south-1  # Optional, defaults to ap-south-1"
    echo "  ./scripts/update_github_actions_sg.sh"
    echo ""
    echo "Or find your security group ID:"
    echo "  aws ec2 describe-instances --region $REGION --query 'Reservations[*].Instances[*].[InstanceId,SecurityGroups[0].GroupId]' --output table"
    exit 1
fi

# Verify security group exists
echo -e "${YELLOW}[1/4] Verifying security group...${NC}"
if ! aws ec2 describe-security-groups --group-ids "$SECURITY_GROUP_ID" --region "$REGION" &> /dev/null; then
    echo -e "${RED}❌ Security group $SECURITY_GROUP_ID not found in region $REGION${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Security group verified${NC}"
echo ""

# Fetch GitHub Actions IP ranges
echo -e "${YELLOW}[2/4] Fetching GitHub Actions IP ranges...${NC}"
GITHUB_IPS=$(curl -s "$GITHUB_API_URL" | jq -r '.actions[]' | grep -v '^$' || echo "")

if [ -z "$GITHUB_IPS" ]; then
    echo -e "${RED}❌ Failed to fetch GitHub Actions IP ranges${NC}"
    exit 1
fi

IP_COUNT=$(echo "$GITHUB_IPS" | wc -l)
echo -e "${GREEN}✅ Fetched $IP_COUNT IP ranges${NC}"
echo ""

# Check existing rules
echo -e "${YELLOW}[3/4] Checking existing SSH rules...${NC}"
EXISTING_RULES=$(aws ec2 describe-security-groups \
    --group-ids "$SECURITY_GROUP_ID" \
    --region "$REGION" \
    --query "SecurityGroups[0].IpPermissions[?FromPort==\`22\` && IpProtocol==\`tcp\`].IpRanges[].CidrIp" \
    --output text 2>/dev/null || echo "")

if [ -n "$EXISTING_RULES" ]; then
    echo "Existing SSH rules found:"
    echo "$EXISTING_RULES" | tr '\t' '\n' | while read -r rule; do
        if [[ "$rule" == *"github"* ]] || [[ "$GITHUB_IPS" == *"$rule"* ]]; then
            echo "  - $rule (GitHub Actions)"
        else
            echo "  - $rule"
        fi
    done
else
    echo "No existing SSH rules found"
fi
echo ""

# Add GitHub Actions IP ranges
echo -e "${YELLOW}[4/4] Adding GitHub Actions IP ranges to security group...${NC}"
echo "This may take a few minutes due to the large number of IP ranges..."
echo ""

SUCCESS_COUNT=0
FAILED_COUNT=0
SKIPPED_COUNT=0

while IFS= read -r cidr; do
    if [ -z "$cidr" ]; then
        continue
    fi
    
    # Check if rule already exists
    if echo "$EXISTING_RULES" | grep -q "^$cidr$"; then
        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
        continue
    fi
    
    # Add the rule
    if aws ec2 authorize-security-group-ingress \
        --group-id "$SECURITY_GROUP_ID" \
        --protocol tcp \
        --port 22 \
        --cidr "$cidr" \
        --region "$REGION" \
        --description "GitHub Actions - Auto-added $(date +%Y-%m-%d)" \
        &> /dev/null; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        if [ $((SUCCESS_COUNT % 50)) -eq 0 ]; then
            echo "  Added $SUCCESS_COUNT rules..."
        fi
    else
        FAILED_COUNT=$((FAILED_COUNT + 1))
        echo -e "${RED}  Failed to add: $cidr${NC}"
    fi
done <<< "$GITHUB_IPS"

echo ""
echo "=========================================="
echo -e "${GREEN}✅ Update complete!${NC}"
echo ""
echo "Summary:"
echo "  - Successfully added: $SUCCESS_COUNT rules"
echo "  - Already existed: $SKIPPED_COUNT rules"
echo "  - Failed: $FAILED_COUNT rules"
echo ""
echo "Your EC2 security group now allows SSH from GitHub Actions IP ranges."
echo "You can test the deployment workflow now."

