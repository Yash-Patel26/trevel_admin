# Manual Deployment Guide

This guide explains how to manually deploy the backend to your EC2 instance when GitHub Actions deployment is not working.

## Prerequisites

1. **SSH Access to EC2**: You need to be able to SSH into your EC2 instance
2. **Docker Installed**: Docker must be installed and running on EC2
3. **Environment File**: A `.env` file must exist at `~/backend/.env` on EC2

## Deployment Steps

### 1. Connect to EC2

```bash
ssh -i your-key.pem ubuntu@your-ec2-ip
```

### 2. Create Backend Directory (First Time Only)

```bash
mkdir -p ~/backend
cd ~/backend
```

### 3. Upload Your Code to EC2

**Option A: Using Git (Recommended)**

```bash
cd ~/backend

# If first time, clone the repository
git clone https://github.com/Yash-Patel26/trevel_admin.git .

# If already cloned, pull latest changes
git pull origin main

# Navigate to backend directory
cd backend
```

**Option B: Using SCP from Your Local Machine**

From your local machine (not on EC2):

```bash
# Navigate to your project directory
cd c:\Users\yash4\Desktop\trevel_admin\trevel_admin

# Create a deployment package
cd backend
tar -czf deploy.tar.gz \
  --exclude='node_modules' \
  --exclude='.git' \
  --exclude='uploads' \
  --exclude='*.log' \
  .

# Upload to EC2
scp -i path/to/your-key.pem deploy.tar.gz ubuntu@your-ec2-ip:~/

# Then on EC2, extract it
ssh -i path/to/your-key.pem ubuntu@your-ec2-ip
mkdir -p ~/backend
tar -xzf ~/deploy.tar.gz -C ~/backend
rm ~/deploy.tar.gz
```

### 4. Create Environment File (First Time Only)

```bash
cd ~/backend
nano .env
```

Add your environment variables:

```env
# Database
DATABASE_URL="your-database-url"

# JWT
JWT_SECRET="your-jwt-secret"
JWT_EXPIRES_IN="7d"

# AWS S3
AWS_REGION="your-region"
AWS_ACCESS_KEY_ID="your-access-key"
AWS_SECRET_ACCESS_KEY="your-secret-key"
AWS_S3_BUCKET="your-bucket-name"

# Server
PORT=4000
NODE_ENV=production

# Add any other environment variables your app needs
```

Save and exit (Ctrl+X, then Y, then Enter)

### 5. Run the Manual Deployment Script

```bash
cd ~/backend
chmod +x scripts/manual-deploy.sh
./scripts/manual-deploy.sh
```

The script will:
- ✅ Check prerequisites (Docker, .env file)
- 🔨 Build the Docker image
- 🛑 Stop the old container
- 🗄️ Run database migrations
- 🚢 Start the new container
- 🏥 Perform health checks
- 🧹 Clean up old images

### 6. Verify Deployment

```bash
# Check if container is running
sudo docker ps

# Check container logs
sudo docker logs trevel_admin_backend -f

# Test the health endpoint
curl http://localhost:4000/healthz
```

## Troubleshooting

### Container Won't Start

```bash
# Check container logs
sudo docker logs trevel_admin_backend

# Check if port 4000 is already in use
sudo lsof -i :4000

# Try running the container interactively to see errors
sudo docker run --rm -it \
  --env-file ~/backend/.env \
  -e NODE_ENV=production \
  -e PORT=4000 \
  -p 4000:4000 \
  trevel_backend:latest
```

### Database Connection Issues

```bash
# Test database connection from EC2
# Install psql if needed
sudo apt-get install postgresql-client

# Test connection (replace with your DATABASE_URL details)
psql "your-database-url"
```

### Permission Issues with Docker

```bash
# Add your user to docker group
sudo usermod -aG docker $USER

# Log out and back in for changes to take effect
exit
# SSH back in
ssh -i your-key.pem ubuntu@your-ec2-ip

# Now you can run docker without sudo
docker ps
```

## Useful Commands

### View Logs
```bash
sudo docker logs trevel_admin_backend -f
```

### Restart Container
```bash
sudo docker restart trevel_admin_backend
```

### Stop Container
```bash
sudo docker stop trevel_admin_backend
```

### Access Container Shell
```bash
sudo docker exec -it trevel_admin_backend /bin/sh
```

### Remove Container
```bash
sudo docker stop trevel_admin_backend
sudo docker rm trevel_admin_backend
```

### View Docker Images
```bash
sudo docker images
```

### Clean Up Old Images
```bash
sudo docker image prune -a
```

## Next Steps

Once you've successfully deployed manually, you should:

1. **Fix GitHub Actions SSH Issues** to enable automated deployments
   - Check EC2 Security Group allows SSH from GitHub Actions IPs
   - Verify GitHub Secrets are correctly configured
   - Test SSH connection from GitHub Actions

2. **Set Up Monitoring**
   - Configure CloudWatch logs
   - Set up health check monitoring
   - Configure alerts for container failures

3. **Implement Backup Strategy**
   - Regular database backups
   - Backup environment files
   - Document recovery procedures
