# AWS EC2 Deployment Guide

## Overview
This guide covers deploying the Trevel backend to AWS EC2 with Prisma migrations.

## Prerequisites

1. **EC2 Instance** with:
   - Docker installed
   - Node.js 20+ (if running migrations outside Docker)
   - `.env` file configured with database credentials

2. **Database** (PostgreSQL):
   - Accessible from EC2 instance
   - `DATABASE_URL` configured in `.env`

3. **Prisma Migrations**:
   - All migrations in `prisma/migrations/` directory
   - Migrations are committed to version control

---

## Deployment Scripts

### 1. AWS Deploy Script (Recommended)
**File:** `scripts/aws-deploy.sh`

**Features:**
- ✅ Runs Prisma migrations automatically
- ✅ Cleans up Docker to free space
- ✅ Health checks
- ✅ Error handling
- ✅ Optimized for AWS EC2

**Usage:**
```bash
cd /path/to/trevel_admin/backend
./scripts/aws-deploy.sh
```

**What it does:**
1. Checks prerequisites (Docker, .env file)
2. Cleans up Docker to free space
3. Builds Docker image
4. Stops old container
5. **Runs Prisma migrations** (`prisma migrate deploy`)
6. Verifies Prisma setup
7. Starts new container
8. Health check
9. Cleanup old images

---

### 2. Manual Deploy Script
**File:** `scripts/manual-deploy.sh`

**Usage:**
```bash
cd /path/to/trevel_admin/backend
./scripts/manual-deploy.sh
```

**Features:**
- Same as AWS deploy but with more verbose output
- Good for troubleshooting

---

### 3. Quick Deploy Script
**File:** `scripts/quick-deploy.sh`

**Usage:**
```bash
cd /path/to/trevel_admin/backend
./scripts/quick-deploy.sh
```

**Features:**
- Pulls latest code from git
- Only installs dependencies if package.json changed
- Only regenerates Prisma if schema changed
- Calls main deploy script

---

## Prisma Migrations

### Migration Commands Used

**In Deployment Scripts:**
```bash
npx prisma migrate deploy
```

This command:
- ✅ Applies all pending migrations from `prisma/migrations/`
- ✅ Safe for production (doesn't modify schema)
- ✅ Idempotent (safe to run multiple times)
- ✅ Records migration history in database

**NOT Used:**
- ❌ `prisma db push` - Not safe for production, can lose data
- ❌ `prisma migrate dev` - Only for development

### Creating New Migrations

**On Local Machine:**
```bash
# After changing schema.prisma
npx prisma migrate dev --name your_migration_name

# This creates a new migration file in prisma/migrations/
```

**Commit migrations to git:**
```bash
git add prisma/migrations/
git commit -m "Add migration: your_migration_name"
git push
```

**On AWS (after deployment):**
- Migrations are automatically applied by deployment script
- No manual steps needed

---

## Dockerfile Updates

### Development Dockerfile (`Dockerfile`)
- Uses `start.sh` script which runs migrations on startup
- Command: `./start.sh node dist/server.js`

### Production Dockerfile (`Dockerfile.production`)
- Uses `start.sh` script which runs migrations on startup
- Command: `./start.sh node dist/server.js`

### Startup Script (`scripts/start.sh`)
- Runs `prisma migrate deploy` on container startup
- Generates Prisma client
- Starts the application

---

## Deployment Process

### Step-by-Step (AWS EC2)

1. **SSH into EC2 instance:**
   ```bash
   ssh -i /path/to/key.pem ubuntu@13.233.48.227
   ```

2. **Navigate to backend directory:**
   ```bash
   cd /path/to/trevel_admin/backend
   ```

3. **Pull latest code (if using git):**
   ```bash
   git pull origin main
   ```

4. **Run deployment script:**
   ```bash
   ./scripts/aws-deploy.sh
   ```

5. **Verify deployment:**
   ```bash
   # Check container status
   sudo docker ps

   # Check logs
   sudo docker logs trevel_admin_backend -f

   # Test health endpoint
   curl http://localhost:4000/healthz
   ```

---

## Migration Verification

### Check Migration Status
```bash
# Inside container
sudo docker exec trevel_admin_backend npx prisma migrate status

# Or run directly
sudo docker run --rm --env-file .env trevel_backend:latest npx prisma migrate status
```

### View Applied Migrations
```bash
# Connect to database and check
SELECT * FROM "_prisma_migrations" ORDER BY finished_at DESC;
```

---

## Troubleshooting

### Migration Fails

**Error: "Migration failed"**
```bash
# Check migration status
sudo docker exec trevel_admin_backend npx prisma migrate status

# View migration logs
sudo docker logs trevel_admin_backend | grep -i migration

# Manually run migration
sudo docker exec trevel_admin_backend npx prisma migrate deploy
```

### Container Won't Start

**Check logs:**
```bash
sudo docker logs trevel_admin_backend --tail 100
```

**Common issues:**
- Database connection failed (check `.env` DATABASE_URL)
- Migration failed (check database permissions)
- Port already in use (check if old container is running)

### Database Connection Issues

**Verify DATABASE_URL in .env:**
```bash
# Should be in format:
# DATABASE_URL="postgresql://user:password@host:5432/database?schema=public"
```

**Test connection:**
```bash
sudo docker run --rm --env-file .env trevel_backend:latest npx prisma db execute --stdin <<< "SELECT 1"
```

---

## Environment Variables

**Required in `.env`:**
```bash
DATABASE_URL="postgresql://user:password@host:5432/database"
NODE_ENV="production"
PORT=4000
JWT_SECRET="your-secret-key"
# ... other variables
```

---

## Rollback

### Rollback Container
```bash
# Stop current container
sudo docker stop trevel_admin_backend

# Start previous version (if tagged)
sudo docker run -d \
  --name trevel_admin_backend \
  --env-file .env \
  -p 4000:4000 \
  trevel_backend:previous_version
```

### Rollback Migration
```bash
# Prisma doesn't support automatic rollback
# You need to create a new migration to undo changes
# Or manually restore database from backup
```

---

## Best Practices

1. **Always backup database before migrations:**
   ```bash
   pg_dump -h host -U user -d database > backup.sql
   ```

2. **Test migrations locally first:**
   ```bash
   npx prisma migrate dev
   ```

3. **Commit migrations to git:**
   - Never skip committing migration files
   - Migrations are part of your codebase

4. **Monitor deployment logs:**
   ```bash
   sudo docker logs trevel_admin_backend -f
   ```

5. **Use health checks:**
   - Deployment script includes health check
   - Monitor `/healthz` endpoint

---

## Quick Reference

```bash
# Deploy to AWS
./scripts/aws-deploy.sh

# Check migration status
sudo docker exec trevel_admin_backend npx prisma migrate status

# View logs
sudo docker logs trevel_admin_backend -f

# Restart container
sudo docker restart trevel_admin_backend

# Stop container
sudo docker stop trevel_admin_backend

# Check container status
sudo docker ps -a | grep trevel_admin_backend
```

---

## Summary

✅ **All deployment scripts now use `prisma migrate deploy`**  
✅ **Migrations run automatically during deployment**  
✅ **Startup script runs migrations on container start**  
✅ **AWS-optimized deployment script created**  
✅ **Error handling and health checks included**

The deployment process is now fully automated with Prisma migrations integrated!

