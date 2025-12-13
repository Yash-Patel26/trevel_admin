# Seed Users in Docker Environment
# This script seeds both admin and customer users in the Docker database

Write-Host "Starting Docker PostgreSQL..." -ForegroundColor Cyan
docker-compose up -d postgres

Write-Host "Waiting for PostgreSQL to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Wait for database to be ready
$maxAttempts = 30
$attempt = 0
while ($attempt -lt $maxAttempts) {
    $result = docker-compose exec -T postgres pg_isready -U user -d trevel_admin 2>&1
    if ($LASTEXITCODE -eq 0) {
        break
    }
    Write-Host "Database is not ready yet, waiting..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    $attempt++
}

if ($attempt -eq $maxAttempts) {
    Write-Host "Database failed to start after $maxAttempts attempts" -ForegroundColor Red
    exit 1
}

Write-Host "PostgreSQL is ready!" -ForegroundColor Green

Write-Host ""
Write-Host "Running Prisma migrations..." -ForegroundColor Cyan
npm run prisma:generate
npx prisma migrate deploy

Write-Host ""
Write-Host "Seeding admin users..." -ForegroundColor Cyan
npm run seed

Write-Host ""
Write-Host "Seeding test customer..." -ForegroundColor Cyan
npx ts-node scripts/create-test-customer.ts

Write-Host ""
Write-Host "All users seeded successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Admin Users Created:" -ForegroundColor Cyan
Write-Host '  - admin@trevel.in (password: 112233) - Operational Admin'
Write-Host '  - fleet@trevel.in (password: 112233) - Fleet Admin'
Write-Host '  - driver@trevel.in (password: 112233) - Driver Admin'
Write-Host '  - driver-individual@trevel.in (password: 112233) - Driver Individual'
Write-Host '  - fleet-individual@trevel.in (password: 112233) - Fleet Individual'
Write-Host '  - team@trevel.in (password: 112233) - Team Member'
Write-Host ""
Write-Host "Customer User Created:" -ForegroundColor Cyan
Write-Host '  - Mobile: +919876543210'
Write-Host '  - Name: Test User'
Write-Host '  - Email: testuser@trevel.com'
Write-Host ""
