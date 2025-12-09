# Deploy to EC2 with Docker (Complete Guide)

This guide will help you deploy your entire backend + database to a single EC2 instance using Docker Compose.

---

## Part 1: Launch EC2 Instance

### Step 1: Go to EC2 Console

Click: [Launch EC2 Instance (Mumbai)](https://ap-south-1.console.aws.amazon.com/ec2/home?region=ap-south-1#LaunchInstances:)

### Step 2: Configure Instance

**Name and tags**
- Name: `trevel-backend-server`

**Application and OS Images**
- **Quick Start**: Ubuntu
- **AMI**: Ubuntu Server 24.04 LTS (Free tier eligible)

**Instance type**
- Select: **t2.micro** (Free tier eligible)

**Key pair**
- Click **"Create new key pair"**
- Name: `trevel-key`
- Type: RSA
- Format: `.pem`
- Click **Create** (it will download the file - **save it safely!**)

**Network settings**
- Click **"Edit"**
- **Auto-assign public IP**: **Enable**
- **Firewall (security groups)**: Create new
  - Name: `trevel-backend-sg`
  - Add these rules:
    1. **SSH** (port 22) - Source: My IP
    2. **Custom TCP** (port 4000) - Source: Anywhere (0.0.0.0/0)
    3. **HTTP** (port 80) - Source: Anywhere (0.0.0.0/0)

**Storage**
- Keep default: 8 GB gp3

### Step 3: Launch

- Click **"Launch instance"**
- Wait 1-2 minutes for it to start
- Click **"View all instances"**
- Copy the **Public IPv4 address** (e.g., `13.234.56.78`)

---

## Part 2: Connect to EC2 and Install Docker

### Step 1: Connect via SSH

**On Windows (PowerShell):**
```powershell
# Navigate to where you saved the key
cd Downloads

# Set permissions (if needed)
icacls trevel-key.pem /inheritance:r
icacls trevel-key.pem /grant:r "$($env:USERNAME):(R)"

# Connect (replace with YOUR IP)
ssh -i trevel-key.pem ubuntu@YOUR_EC2_PUBLIC_IP
```

**Example:**
```powershell
ssh -i trevel-key.pem ubuntu@13.234.56.78
```

Type `yes` when asked about fingerprint.

### Step 2: Install Docker

Once connected to EC2, run these commands **one by one**:

```bash
# Update system
sudo apt update

# Install Docker
sudo apt install -y docker.io

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group (so you don't need sudo)
sudo usermod -aG docker ubuntu

# Install Docker Compose
sudo apt install -y docker-compose

# Verify installation
docker --version
docker-compose --version
```

**Log out and log back in** for group changes to take effect:
```bash
exit
```

Then reconnect:
```bash
ssh -i trevel-key.pem ubuntu@YOUR_EC2_PUBLIC_IP
```

---

## Part 3: Deploy Your Application

### Step 1: Upload Your Code

**On your local machine** (new PowerShell window):

```powershell
# Navigate to your backend folder
cd C:\Users\yash4\Desktop\trevel_admin\trevel_admin\backend

# Copy files to EC2 (replace with YOUR IP)
scp -i Downloads\trevel-key.pem -r . ubuntu@YOUR_EC2_PUBLIC_IP:~/backend
```

This will take 1-2 minutes to upload all files.

### Step 2: Start the Application

**Back on EC2 (SSH session):**

```bash
# Go to backend folder
cd ~/backend

# Start everything with Docker Compose
docker-compose up -d

# Check if containers are running
docker-compose ps

# View logs
docker-compose logs -f backend
```

Press `Ctrl+C` to stop viewing logs.

### Step 3: Run Database Migration

```bash
# Run migration inside the backend container
docker-compose exec backend npx prisma migrate deploy

# Verify database connection
docker-compose exec backend npx prisma db push
```

---

## Part 4: Test Your API

Your API is now live at: `http://13.233.48.227 :4000`

**Test it:**
```bash
curl http://13.233.48.227 :4000
```

Or open in browser: `http://YOUR_EC2_PUBLIC_IP:4000`

---

## Part 5: Make it Production-Ready (Optional)

### Add Domain Name (Optional)

1. Point your domain to the EC2 IP
2. Install Nginx as reverse proxy
3. Get free SSL certificate with Let's Encrypt

### Auto-start on Reboot

```bash
# Create systemd service
sudo nano /etc/systemd/system/trevel-backend.service
```

Paste this:
```ini
[Unit]
Description=Trevel Backend
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/ubuntu/backend
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
User=ubuntu

[Install]
WantedBy=multi-user.target
```

Save and enable:
```bash
sudo systemctl enable trevel-backend
sudo systemctl start trevel-backend
```

---

## Troubleshooting

### If containers won't start:
```bash
docker-compose logs
```

### If port 4000 is not accessible:
- Check EC2 Security Group has port 4000 open
- Check if container is running: `docker-compose ps`

### To restart everything:
```bash
docker-compose down
docker-compose up -d
```

### To update code:
```bash
# On local machine, upload new code
scp -i Downloads\trevel-key.pem -r . ubuntu@YOUR_EC2_IP:~/backend

# On EC2, rebuild and restart
cd ~/backend
docker-compose down
docker-compose up -d --build
```

---

## Summary

✅ **EC2 instance** running Ubuntu  
✅ **Docker + Docker Compose** installed  
✅ **Backend + Database** running in containers  
✅ **API accessible** at `http://YOUR_EC2_IP:4000`  

**Your backend is now live!** 🎉
