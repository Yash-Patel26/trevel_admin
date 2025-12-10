# Deployment Scripts

This directory contains scripts to help with EC2 deployment and GitHub Actions configuration.

## Scripts

### `update_github_actions_sg.sh` / `update_github_actions_sg.ps1`

Automatically updates your EC2 security group to allow SSH access from GitHub Actions IP ranges.

**Why this is needed:**
- GitHub Actions workflows need to SSH into your EC2 instance to deploy code
- GitHub Actions uses dynamic IP addresses from a large set of ranges
- These IP ranges change over time and are too numerous to add manually

**Usage:**

**Linux/Mac:**
```bash
export EC2_SECURITY_GROUP_ID=sg-xxxxxxxxxxxxx
export AWS_REGION=ap-south-1
./scripts/update_github_actions_sg.sh
```

**Windows (PowerShell):**
```powershell
.\scripts\update_github_actions_sg.ps1 -SecurityGroupId "sg-xxxxxxxxxxxxx" -Region "ap-south-1"
```

**Prerequisites:**
- AWS CLI installed and configured
- `jq` installed (for bash script)
- Security group ID from your EC2 instance

**What it does:**
1. Fetches the latest GitHub Actions IP ranges from GitHub's API
2. Checks existing SSH rules in your security group
3. Adds all GitHub Actions IP ranges as SSH (port 22) rules
4. Skips IP ranges that already exist

**Note:** This script adds many rules (hundreds). It may take a few minutes to complete.

## Finding Your Security Group ID

### Via AWS Console:
1. Go to [EC2 Console](https://ap-south-1.console.aws.amazon.com/ec2/home?region=ap-south-1#Instances:)
2. Select your EC2 instance
3. Click the **Security** tab
4. Copy the **Security Group ID** (e.g., `sg-0123456789abcdef0`)

### Via AWS CLI:
```bash
aws ec2 describe-instances \
  --region ap-south-1 \
  --query 'Reservations[*].Instances[*].[InstanceId,SecurityGroups[0].GroupId]' \
  --output table
```

## Troubleshooting

### Script fails with "Security group not found"
- Verify the security group ID is correct
- Check that you're using the correct AWS region
- Ensure your AWS credentials have permissions to modify security groups

### Script fails with "jq: command not found"
- Install jq: `sudo apt-get install jq` (Linux) or `brew install jq` (Mac)
- Or use the PowerShell script on Windows (doesn't require jq)

### Some IP ranges fail to add
- This is normal - some rules may already exist or have conflicts
- The script will report how many succeeded/failed
- As long as most rules are added, GitHub Actions should be able to connect

### AWS CLI not configured
```bash
aws configure
# Enter your:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region (e.g., ap-south-1)
# - Default output format (json)
```

