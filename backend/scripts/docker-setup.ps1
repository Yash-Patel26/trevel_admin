# Docker Setup Script for Trevel Admin Backend (PowerShell)
# This script helps set up the Docker environment on Windows

Write-Host "🚀 Setting up Trevel Admin Backend with Docker..." -ForegroundColor Cyan

# Check if .env file exists
if (-not (Test-Path .env)) {
    Write-Host "📝 Creating .env file from .env.example..." -ForegroundColor Yellow
    Copy-Item .env.example .env
    Write-Host "⚠️  Please update .env file with your configuration before continuing!" -ForegroundColor Yellow
}

# Create uploads directory if it doesn't exist
if (-not (Test-Path uploads)) {
    Write-Host "📁 Creating uploads directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path uploads | Out-Null
}

# Start database only first
Write-Host "🗄️  Starting PostgreSQL database..." -ForegroundColor Cyan
docker-compose up -d db

# Wait for database to be ready
Write-Host "⏳ Waiting for database to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Check if database is ready
$maxAttempts = 30
$attempt = 0
$dbReady = $false

while ($attempt -lt $maxAttempts -and -not $dbReady) {
    try {
        $result = docker-compose exec -T db pg_isready -U trevel_admin -d trevel_admin 2>&1
        if ($LASTEXITCODE -eq 0) {
            $dbReady = $true
        }
    } catch {
        # Continue waiting
    }
    
    if (-not $dbReady) {
        Write-Host "⏳ Database is not ready yet, waiting... ($attempt/$maxAttempts)" -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        $attempt++
    }
}

if ($dbReady) {
    Write-Host "✅ Database is ready!" -ForegroundColor Green
    
    # Run migrations
    Write-Host "🔄 Running database migrations..." -ForegroundColor Cyan
    docker-compose run --rm backend npx prisma migrate deploy
    
    Write-Host "✅ Setup complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Next steps:" -ForegroundColor Cyan
    Write-Host "1. Update .env file with your configuration"
    Write-Host "2. Start all services: docker-compose up -d"
    Write-Host "3. View logs: docker-compose logs -f"
    Write-Host "4. Stop services: docker-compose down"
} else {
    Write-Host "❌ Database failed to start. Please check the logs: docker-compose logs db" -ForegroundColor Red
    exit 1
}

