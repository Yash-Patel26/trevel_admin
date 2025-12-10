# PowerShell script to update EC2 Security Group with GitHub Actions IP ranges
# This allows GitHub Actions workflows to SSH into EC2 for deployment

param(
    [Parameter(Mandatory=$true)]
    [string]$SecurityGroupId,
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "ap-south-1"
)

$ErrorActionPreference = "Stop"

Write-Host "GitHub Actions Security Group Updater" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""

# Check if AWS CLI is installed
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Host "❌ AWS CLI is not installed" -ForegroundColor Red
    Write-Host "Install it from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    exit 1
}

# Verify security group exists
Write-Host "[1/4] Verifying security group..." -ForegroundColor Yellow
try {
    $sgInfo = aws ec2 describe-security-groups --group-ids $SecurityGroupId --region $Region 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Security group $SecurityGroupId not found in region $Region" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Security group verified" -ForegroundColor Green
} catch {
    Write-Host "❌ Error verifying security group: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Fetch GitHub Actions IP ranges
Write-Host "[2/4] Fetching GitHub Actions IP ranges..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "https://api.github.com/meta" -Method Get
    $githubIps = $response.actions | Where-Object { $_ -ne "" }
    
    if ($null -eq $githubIps -or $githubIps.Count -eq 0) {
        Write-Host "❌ Failed to fetch GitHub Actions IP ranges" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ Fetched $($githubIps.Count) IP ranges" -ForegroundColor Green
} catch {
    Write-Host "❌ Error fetching GitHub IP ranges: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Check existing rules
Write-Host "[3/4] Checking existing SSH rules..." -ForegroundColor Yellow
try {
    $existingRulesJson = aws ec2 describe-security-groups `
        --group-ids $SecurityGroupId `
        --region $Region `
        --query "SecurityGroups[0].IpPermissions[?FromPort==``22`` && IpProtocol==``tcp``].IpRanges[].CidrIp" `
        --output json 2>&1
    
    $existingRules = ($existingRulesJson | ConvertFrom-Json) | Where-Object { $_ -ne $null }
    
    if ($existingRules.Count -gt 0) {
        Write-Host "Existing SSH rules found:" -ForegroundColor Gray
        foreach ($rule in $existingRules) {
            if ($rule -like "*github*" -or $githubIps -contains $rule) {
                Write-Host "  - $rule (GitHub Actions)" -ForegroundColor Gray
            } else {
                Write-Host "  - $rule" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "No existing SSH rules found" -ForegroundColor Gray
    }
} catch {
    Write-Host "Warning: Could not check existing rules: $_" -ForegroundColor Yellow
    $existingRules = @()
}
Write-Host ""

# Add GitHub Actions IP ranges
Write-Host "[4/4] Adding GitHub Actions IP ranges to security group..." -ForegroundColor Yellow
Write-Host "This may take a few minutes due to the large number of IP ranges..." -ForegroundColor Gray
Write-Host ""

$successCount = 0
$failedCount = 0
$skippedCount = 0
$total = $githubIps.Count
$current = 0

foreach ($cidr in $githubIps) {
    $current++
    
    if ([string]::IsNullOrWhiteSpace($cidr)) {
        continue
    }
    
    # Check if rule already exists
    if ($existingRules -contains $cidr) {
        $skippedCount++
        continue
    }
    
    # Add the rule
    try {
        $result = aws ec2 authorize-security-group-ingress `
            --group-id $SecurityGroupId `
            --protocol tcp `
            --port 22 `
            --cidr $cidr `
            --region $Region `
            --description "GitHub Actions - Auto-added $(Get-Date -Format 'yyyy-MM-dd')" `
            2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $successCount++
            if ($successCount % 50 -eq 0) {
                Write-Host "  Added $successCount rules... ($current/$total)" -ForegroundColor Gray
            }
        } else {
            # Rule might already exist (duplicate)
            if ($result -like "*already exists*" -or $result -like "*Duplicate*") {
                $skippedCount++
            } else {
                $failedCount++
                Write-Host "  Failed to add: $cidr - $result" -ForegroundColor Red
            }
        }
    } catch {
        $failedCount++
        Write-Host "  Error adding $cidr : $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "✅ Update complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  - Successfully added: $successCount rules" -ForegroundColor Green
Write-Host "  - Already existed: $skippedCount rules" -ForegroundColor Yellow
Write-Host "  - Failed: $failedCount rules" -ForegroundColor $(if ($failedCount -gt 0) { "Red" } else { "Green" })
Write-Host ""
Write-Host "Your EC2 security group now allows SSH from GitHub Actions IP ranges." -ForegroundColor Green
Write-Host "You can test the deployment workflow now." -ForegroundColor Green

