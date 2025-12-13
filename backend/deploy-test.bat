@echo off
REM Trevel Backend - Docker Deployment Script for Testing (Windows)

echo.
echo ========================================
echo   Trevel Backend - Test Deployment
echo ========================================
echo.

REM Stop and remove existing containers
echo [1/5] Stopping existing containers...
docker-compose -f docker-compose.test.yml down

REM Build the backend image
echo.
echo [2/5] Building backend Docker image...
docker-compose -f docker-compose.test.yml build --no-cache

REM Start all services
echo.
echo [3/5] Starting services...
docker-compose -f docker-compose.test.yml up -d

REM Wait for services
echo.
echo [4/5] Waiting for services to be ready...
timeout /t 15 /nobreak > nul

REM Check service health
echo.
echo [5/5] Checking service health...
docker-compose -f docker-compose.test.yml ps

REM Get local IP (Windows)
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    set LOCAL_IP=%%a
    goto :found_ip
)
:found_ip
set LOCAL_IP=%LOCAL_IP:~1%

REM Create test customer
echo.
echo Creating test customer...
docker-compose -f docker-compose.test.yml exec -T postgres psql -U trevel -d trevel_db -c "INSERT INTO \"Customer\" (id, name, mobile, email, status) VALUES (gen_random_uuid(), 'Test User', '+919876543210', 'testuser@trevel.com', 'active') ON CONFLICT (mobile) DO NOTHING;"

REM Display information
echo.
echo ========================================
echo   Deployment Complete!
echo ========================================
echo.
echo Mobile App Configuration:
echo.
echo For Android Emulator:
echo   baseUrl: http://10.0.2.2:4000/api/mobile
echo.
echo For iOS Simulator:
echo   baseUrl: http://localhost:4000/api/mobile
echo.
echo For Physical Devices:
echo   baseUrl: http://%LOCAL_IP%:4000/api/mobile
echo.
echo ========================================
echo Test Credentials:
echo ========================================
echo.
echo   Mobile: +919876543210
echo   Email:  testuser@trevel.com
echo.
echo ========================================
echo Service URLs:
echo ========================================
echo.
echo   Backend:  http://localhost:4000
echo   Health:   http://localhost:4000/healthz
echo   Database: localhost:5432
echo   Redis:    localhost:6379
echo.
echo ========================================
echo Useful Commands:
echo ========================================
echo.
echo   View logs:     docker-compose -f docker-compose.test.yml logs -f
echo   Stop:          docker-compose -f docker-compose.test.yml down
echo   Restart:       docker-compose -f docker-compose.test.yml restart backend
echo.
pause
