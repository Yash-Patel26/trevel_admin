# Docker Deployment for Testing

## Quick Start

### Windows
```bash
cd backend
deploy-test.bat
```

### Linux/macOS
```bash
cd backend
chmod +x deploy-test.sh
./deploy-test.sh
```

## What Gets Deployed

The deployment includes:
- **PostgreSQL** (port 5432) - Database
- **Redis** (port 6379) - Cache & OTP storage
- **Backend API** (port 4000) - Node.js application

## Flutter App Configuration

After deployment, update your Flutter app's API configuration:

### 1. Open `api_constants.dart`
Location: `trevel_customer/lib/core/constants/api_constants.dart`

### 2. Set the Environment

```dart
static const String _environment = 'docker_android'; // or 'docker_ios' or 'docker_physical'
```

**Options:**
- `docker_android` - For Android Emulator (uses `10.0.2.2:4000`)
- `docker_ios` - For iOS Simulator (uses `localhost:4000`)
- `docker_physical` - For Physical Devices (update IP in code)

### 3. For Physical Devices
If testing on a real device, update the IP address:

1. Find your machine's IP:
   - **Windows**: `ipconfig` (look for IPv4 Address)
   - **macOS**: `ifconfig | grep inet`
   - **Linux**: `hostname -I`

2. Update in `api_constants.dart`:
   ```dart
   case 'docker_physical':
     return "http://YOUR_IP_HERE:4000/api/mobile";
   ```

## Test Credentials

```
Mobile: +919876543210
Email:  testuser@trevel.com
```

The test customer is automatically created during deployment.

## Service URLs

- **Backend API**: http://localhost:4000
- **Health Check**: http://localhost:4000/healthz
- **Admin Panel**: http://localhost:4000 (if configured)

## Useful Commands

### View Logs
```bash
# All services
docker-compose -f docker-compose.test.yml logs -f

# Backend only
docker-compose -f docker-compose.test.yml logs -f backend

# Database only
docker-compose -f docker-compose.test.yml logs -f postgres
```

### Restart Services
```bash
# Restart backend
docker-compose -f docker-compose.test.yml restart backend

# Restart all
docker-compose -f docker-compose.test.yml restart
```

### Stop Services
```bash
docker-compose -f docker-compose.test.yml down
```

### Access Database
```bash
docker-compose -f docker-compose.test.yml exec postgres psql -U trevel -d trevel_db
```

### Access Redis CLI
```bash
docker-compose -f docker-compose.test.yml exec redis redis-cli
```

## Troubleshooting

### Backend won't start
1. Check logs: `docker-compose -f docker-compose.test.yml logs backend`
2. Verify database is ready: `docker-compose -f docker-compose.test.yml ps`
3. Check migrations: `docker-compose -f docker-compose.test.yml exec backend npx prisma migrate status`

### Can't connect from mobile app
1. Verify backend is running: `curl http://localhost:4000/healthz`
2. Check firewall settings (allow port 4000)
3. For physical devices, ensure device and computer are on same network
4. Verify IP address is correct in `api_constants.dart`

### Database connection issues
1. Check PostgreSQL is running: `docker-compose -f docker-compose.test.yml ps postgres`
2. Verify DATABASE_URL in docker-compose.test.yml
3. Check logs: `docker-compose -f docker-compose.test.yml logs postgres`

## Environment Variables

The deployment uses these default values (defined in `docker-compose.test.yml`):

```yaml
DATABASE_URL: postgresql://trevel:trevel_dev_password@postgres:5432/trevel_db
REDIS_URL: redis://redis:6379
JWT_SECRET: your-super-secret-jwt-key-change-in-production
```

⚠️ **Note**: These are development credentials. Change them for production!

## Data Persistence

Data is persisted in Docker volumes:
- `postgres_data` - Database data
- `redis_data` - Redis data
- `uploads_data` - Uploaded files

To reset all data:
```bash
docker-compose -f docker-compose.test.yml down -v
```

## Next Steps

1. Deploy using the script
2. Update Flutter app configuration
3. Run the Flutter app
4. Test login with mobile: `+919876543210`
5. Check backend logs for OTP code
6. Complete login and test booking flow
