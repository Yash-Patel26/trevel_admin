# CI/CD Setup Guide

This guide will help you set up automated deployments from GitHub to your EC2 instance.

## Prerequisites

- ✅ GitHub account
- ✅ AWS credentials (Access Key ID & Secret Access Key)
- ✅ EC2 instance running and accessible via SSH
- ✅ Backend code in the `backend` directory

---

## Step 1: Create GitHub Repository

### Option A: Create New Repository

1. Go to [GitHub](https://github.com/new)
2. Repository name: `trevel-admin`
3. Visibility: Private (recommended)
4. **Do NOT** initialize with README, .gitignore, or license
5. Click **Create repository**

### Option B: Initialize Locally

```powershell
# Navigate to your project
cd C:\Users\yash4\Desktop\trevel_admin\trevel_admin

# Initialize git (if not already done)
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial commit - Trevel Admin Backend"

# Add remote (replace with your repository URL)
git remote add origin https://github.com/YOUR_USERNAME/trevel-admin.git

# Push to GitHub
git branch -M main
git push -u origin main
```

---

## Step 2: Configure GitHub Secrets

GitHub Actions needs secure access to your EC2 instance. Set up these secrets:

### 2.1 Go to Repository Settings

1. Open your repository on GitHub
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**

### 2.2 Add Required Secrets

Add each of these secrets:

#### `EC2_HOST`
- **Value**: Your EC2 public IP address
- **Example**: `13.233.48.227`

#### `EC2_USER`
- **Value**: `ubuntu`
- (This is the default user for Ubuntu EC2 instances)

#### `EC2_SSH_KEY`
- **Value**: Contents of your `trevel-key.pem` file
- **How to get it**:
  ```powershell
  # On Windows PowerShell
  Get-Content Downloads\trevel-key.pem | clip
  ```
- Paste the entire content including:
  ```
  -----BEGIN RSA PRIVATE KEY-----
  ... (your key content) ...
  -----END RSA PRIVATE KEY-----
  ```

---

## Step 2.5: Configure EC2 Security Group for GitHub Actions

> ⚠️ **IMPORTANT**: GitHub Actions workflows need SSH access to your EC2 instance. You must allow GitHub Actions IP ranges in your EC2 security group.

### Option A: Automated Script (Recommended)

We provide scripts to automatically add all GitHub Actions IP ranges to your security group:

#### On Windows (PowerShell):

```powershell
# 1. Find your security group ID
# Go to EC2 Console → Instances → Select your instance → Security tab
# Copy the Security Group ID (e.g., sg-0123456789abcdef0)

# 2. Run the script
cd C:\Users\yash4\Desktop\trevel_admin\trevel_admin
.\scripts\update_github_actions_sg.ps1 -SecurityGroupId "sg-xxxxxxxxxxxxx" -Region "ap-south-1"
```

#### On Linux/Mac:

```bash
# 1. Find your security group ID
aws ec2 describe-instances --region ap-south-1 \
  --query 'Reservations[*].Instances[*].[InstanceId,SecurityGroups[0].GroupId]' \
  --output table

# 2. Run the script
cd /path/to/trevel_admin
export EC2_SECURITY_GROUP_ID=sg-xxxxxxxxxxxxx
export AWS_REGION=ap-south-1
chmod +x scripts/update_github_actions_sg.sh
./scripts/update_github_actions_sg.sh
```

### Option B: Manual Configuration (Alternative)

If you prefer to configure manually or the script doesn't work:

1. **Get GitHub Actions IP ranges**:
   - Visit: https://api.github.com/meta
   - Copy all IP ranges from the `"actions"` array

2. **Add to Security Group**:
   - Go to [EC2 Console](https://ap-south-1.console.aws.amazon.com/ec2/home?region=ap-south-1#SecurityGroups:)
   - Select your security group
   - Click **Inbound rules** → **Edit inbound rules**
   - Click **Add rule**
   - Configure:
     - **Type**: SSH
     - **Port**: 22
     - **Source**: Paste each GitHub Actions IP range (CIDR format)
     - **Description**: "GitHub Actions"
   - Repeat for all IP ranges (there are many, so this is tedious)

### Option C: Allow All IPs (NOT RECOMMENDED for Production)

⚠️ **Security Warning**: This allows SSH from anywhere on the internet. Only use for testing.

1. Go to EC2 Console → Security Groups
2. Select your security group
3. Edit inbound rules
4. Add rule:
   - **Type**: SSH
   - **Port**: 22
   - **Source**: `0.0.0.0/0`
   - **Description**: "GitHub Actions - Temporary"

### Verify Configuration

After running the script or manual configuration:

```bash
# Check security group rules
aws ec2 describe-security-groups \
  --group-ids sg-xxxxxxxxxxxxx \
  --region ap-south-1 \
  --query "SecurityGroups[0].IpPermissions[?FromPort==\`22\`]" \
  --output table
```

You should see multiple SSH rules with GitHub Actions IP ranges.

---

## Step 3: Prepare EC2 Instance

SSH into your EC2 instance and set up the deployment environment:

```bash
# Connect to EC2
ssh -i trevel-key.pem ubuntu@YOUR_EC2_IP

# Create backend directory
mkdir -p ~/backend

# Install Git (if not already installed)
sudo apt update
sudo apt install -y git

# Configure Git to allow the directory
cd ~/backend
git config --global --add safe.directory ~/backend

# Exit
exit
```

---

## Step 4: Initial Manual Deployment

Before automated deployments work, you need to do one manual deployment:

### 4.1 Upload Current Code

```powershell
# From your local machine
cd C:\Users\yash4\Desktop\trevel_admin\trevel_admin\backend

# Create deployment package
tar -czf deploy.tar.gz --exclude='node_modules' --exclude='.git' --exclude='uploads' .

# Upload to EC2
scp -i Downloads\trevel-key.pem deploy.tar.gz ubuntu@YOUR_EC2_IP:/tmp/
```

### 4.2 Deploy on EC2

```bash
# SSH to EC2
ssh -i trevel-key.pem ubuntu@YOUR_EC2_IP

# Extract code
cd ~/backend
tar -xzf /tmp/deploy.tar.gz
rm /tmp/deploy.tar.gz

# Create .env file
nano .env
```

Paste your environment variables:
```env
NODE_ENV=production
PORT=4000
DATABASE_URL="your-database-url"
JWT_SECRET="your-jwt-secret"
AWS_REGION=ap-south-1
AWS_ACCESS_KEY_ID=your-key
AWS_SECRET_ACCESS_KEY=your-secret
AWS_S3_BUCKET=your-bucket
CORS_ORIGINS=*
```

Save and exit (Ctrl+X, Y, Enter).

### 4.3 Make Scripts Executable

```bash
chmod +x scripts/*.sh

# Run initial deployment
./scripts/deploy.sh
```

---

## Step 5: Test Automated Deployment

Now test the CI/CD pipeline:

### 5.1 Make a Small Change

```powershell
# On your local machine
cd C:\Users\yash4\Desktop\trevel_admin\trevel_admin\backend

# Make a small change (example)
echo "# Updated" >> README.md

# Commit and push
git add .
git commit -m "Test automated deployment"
git push origin main
```

### 5.2 Monitor Deployment

1. Go to your GitHub repository
2. Click **Actions** tab
3. You should see your workflow running
4. Click on it to see live logs

### 5.3 Verify Deployment

```bash
# SSH to EC2
ssh -i trevel-key.pem ubuntu@YOUR_EC2_IP

# Check health
cd ~/backend
./scripts/health-check.sh
```

---

## Step 6: Daily Workflow

From now on, deploying is simple:

```powershell
# Make your changes
# ... edit files ...

# Commit and push
git add .
git commit -m "Your change description"
git push origin main

# That's it! GitHub Actions will:
# ✅ Build your code
# ✅ Run tests
# ✅ Deploy to EC2
# ✅ Run health checks
# ✅ Rollback if anything fails
```

**No need to stop EC2 or manually restart containers!**

---

## Troubleshooting

### Deployment Failed in GitHub Actions

1. Check the **Actions** tab for error logs
2. Common issues:
   - **SSH connection failed**: Check `EC2_HOST` and `EC2_SSH_KEY` secrets
   - **Permission denied**: Ensure scripts are executable on EC2
   - **Health check failed**: Check application logs on EC2

### Manual Rollback

If you need to rollback:

```bash
# SSH to EC2
ssh -i trevel-key.pem ubuntu@YOUR_EC2_IP

# Check if old version exists
ls -la ~/backend_old

# Rollback
cd ~
rm -rf backend
mv backend_old backend
cd backend
./scripts/deploy.sh
```

### View Logs

```bash
# SSH to EC2
ssh -i trevel-key.pem ubuntu@YOUR_EC2_IP

# View container logs
docker logs trevel_admin_backend -f

# View deployment logs
cat ~/backend/deploy.log
```

---

## Advanced: Manual Deployment from EC2

If you need to deploy manually from EC2 (without GitHub):

```bash
# SSH to EC2
ssh -i trevel-key.pem ubuntu@YOUR_EC2_IP

cd ~/backend

# Pull latest code (if using git)
git pull origin main

# Or upload new code via SCP from local machine:
# scp -i trevel-key.pem -r . ubuntu@YOUR_EC2_IP:~/backend/

# Run quick deploy
./scripts/quick-deploy.sh
```

---

## Summary

✅ **GitHub repository** created and code pushed  
✅ **GitHub secrets** configured for EC2 access  
✅ **EC2 instance** prepared with deployment scripts  
✅ **Initial deployment** completed successfully  
✅ **Automated CI/CD** working  

**From now on**: Just `git push` and your changes deploy automatically with zero downtime! 🚀
