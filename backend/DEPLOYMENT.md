# Deployment & Login Guide

## Test User Credentials

After deployment, the following test users are automatically created:

| Email | Role | Password |
|-------|------|----------|
| `driver-individual@trevel.in` | Driver Individual | `112233` |
| `admin@trevel.in` | Operational Admin | `112233` |
| `driver@trevel.in` | Driver Admin | `112233` |
| `fleet@trevel.in` | Fleet Admin | `112233` |
| `fleet-individual@trevel.in` | Fleet Individual | `112233` |
| `team@trevel.in` | Team | `112233` |

## Deployment Process

### Automatic Deployment (GitHub Actions)

When you push to the `main` branch, the GitHub Actions workflow automatically:

1. ✅ Builds the backend
2. ✅ Deploys to EC2
3. ✅ Runs database migrations
4. ✅ **Seeds test users** (including `driver-individual@trevel.in`)
5. ✅ Starts the application

### Manual Deployment on EC2

If you need to manually deploy and seed:

```bash
# SSH into EC2
ssh -i your-key.pem ubuntu@your-ec2-host

# Navigate to backend directory
cd ~/backend

# Run deployment with seeding
chmod +x scripts/deploy-with-seed.sh
./scripts/deploy-with-seed.sh
```

### Seed Database Only

If you just need to seed the database without full deployment:

```bash
# On EC2
cd ~/backend
npm run seed
```

## Troubleshooting Login Issues

### Issue: "Invalid credentials" for driver-individual@trevel.in

**Cause:** Database not seeded or user not created

**Solution:**
1. SSH into EC2
2. Run: `cd ~/backend && npm run seed`
3. Check output for successful user creation
4. Try login again

### Issue: Cannot connect to backend

**Cause:** Backend server not running or database connection failed

**Solution:**
1. Check backend is running: `sudo docker ps | grep trevel_admin_backend`
2. Check logs: `sudo docker logs trevel_admin_backend --tail 100`
3. Verify .env file exists with correct DATABASE_URL

### Issue: Database connection timeout

**Cause:** AWS RDS not accessible from current location

**Solution:**
- For local development: Use local PostgreSQL or VPN to access RDS
- For production: Ensure EC2 security group allows RDS access

## Database Configuration

The backend connects to AWS RDS PostgreSQL database. Configuration is in `.env`:

```env
DATABASE_URL=postgresql://postgres:password@host:5432/database
```

## Next Deployment

The next time you push to `main`, the deployment will:
- ✅ Automatically seed the database
- ✅ Create all test users if they don't exist
- ✅ Update existing users if they already exist

**Note:** The seeding is idempotent - it's safe to run multiple times.
