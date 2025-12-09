# SSH Connection Diagnostic Script
# This script helps diagnose why SSH connection to 13.233.48.227 is timing out

param (
    [string]$TargetIP = "13.233.48.227",
    [string]$Region = "ap-south-1"
)

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "SSH Connection Diagnostic Tool" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check if instance exists and get its details
Write-Host "[1/5] Searching for EC2 instance with IP $TargetIP in region $Region..." -ForegroundColor Yellow

$instanceInfo = aws ec2 describe-instances `
    --filters "Name=ip-address,Values=$TargetIP" `
    --query "Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress,SecurityGroups[0].GroupId,KeyName]" `
    --output json `
    --region $Region `
    --no-cli-pager | ConvertFrom-Json

if ($instanceInfo.Count -eq 0 -or $null -eq $instanceInfo) {
    Write-Host "   No instance found with IP $TargetIP in $Region" -ForegroundColor Red
    Write-Host ""
    Write-Host "Checking all regions for this IP..." -ForegroundColor Yellow
    
    $regions = @("us-east-1", "us-west-2", "eu-west-1", "eu-north-1", "ap-south-1", "ap-southeast-1")
    
    foreach ($r in $regions) {
        Write-Host "   Checking $r..." -ForegroundColor Gray
        $found = aws ec2 describe-instances `
            --filters "Name=ip-address,Values=$TargetIP" `
            --query "Reservations[*].Instances[*].[InstanceId,State.Name]" `
            --output text `
            --region $r `
            --no-cli-pager
        
        if ($found) {
            Write-Host "   Found in region: $r" -ForegroundColor Green
            $Region = $r
            $instanceInfo = aws ec2 describe-instances `
                --filters "Name=ip-address,Values=$TargetIP" `
                --query "Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress,SecurityGroups[0].GroupId,KeyName]" `
                --output json `
                --region $r `
                --no-cli-pager | ConvertFrom-Json
            break
        }
    }
    
    if ($instanceInfo.Count -eq 0 -or $null -eq $instanceInfo) {
        Write-Host ""
        Write-Host "==================================================" -ForegroundColor Red
        Write-Host "ERROR: Instance not found in any region!" -ForegroundColor Red
        Write-Host "==================================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "Possible reasons:" -ForegroundColor Yellow
        Write-Host "  1. Instance was terminated"
        Write-Host "  2. IP address is incorrect"
        Write-Host "  3. Instance is in a different AWS account"
        Write-Host ""
        exit 1
    }
}

$instanceId = $instanceInfo[0][0][0]
$state = $instanceInfo[0][0][1]
$publicIp = $instanceInfo[0][0][2]
$sgId = $instanceInfo[0][0][3]
$keyName = $instanceInfo[0][0][4]

Write-Host "   Instance found!" -ForegroundColor Green
Write-Host "     Instance ID: $instanceId" -ForegroundColor Gray
Write-Host "     State: $state" -ForegroundColor Gray
Write-Host "     Public IP: $publicIp" -ForegroundColor Gray
Write-Host "     Security Group: $sgId" -ForegroundColor Gray
Write-Host "     Key Name: $keyName" -ForegroundColor Gray
Write-Host ""

# Step 2: Check instance state
Write-Host "[2/5] Checking instance state..." -ForegroundColor Yellow

if ($state -ne "running") {
    Write-Host "   Instance is not running (current state: $state)" -ForegroundColor Red
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Red
    Write-Host "FIX: Start the instance first!" -ForegroundColor Red
    Write-Host "==================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Run this command to start it:" -ForegroundColor Yellow
    Write-Host "aws ec2 start-instances --instance-ids $instanceId --region $Region" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}
else {
    Write-Host "   Instance is running" -ForegroundColor Green
}
Write-Host ""

# Step 3: Check Security Group rules
Write-Host "[3/5] Checking Security Group rules for SSH access..." -ForegroundColor Yellow

$sgRules = aws ec2 describe-security-groups `
    --group-ids $sgId `
    --query "SecurityGroups[0].IpPermissions[?FromPort==``22``]" `
    --output json `
    --region $Region `
    --no-cli-pager | ConvertFrom-Json

$needsFix = $false

if ($sgRules.Count -eq 0 -or $null -eq $sgRules) {
    Write-Host "   No SSH rule (port 22) found in security group!" -ForegroundColor Red
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Red
    Write-Host "FIX: Add SSH rule to security group" -ForegroundColor Red
    Write-Host "==================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Getting your current IP address..." -ForegroundColor Yellow
    $myIp = (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing).Content.Trim()
    Write-Host "Your IP: $myIp" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Run this command to add SSH access:" -ForegroundColor Yellow
    $fixCmd = "aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 22 --cidr ${myIp}/32 --region $Region"
    Write-Host $fixCmd -ForegroundColor Cyan
    Write-Host ""
    $needsFix = $true
}
else {
    Write-Host "   SSH rule exists" -ForegroundColor Green
    
    # Check if your IP is allowed
    Write-Host "   Checking if your IP is allowed..." -ForegroundColor Gray
    $myIp = (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing).Content.Trim()
    Write-Host "   Your current IP: $myIp" -ForegroundColor Gray
    
    $allowedCidrs = $sgRules[0].IpRanges.CidrIp
    $isAllowed = $false
    
    foreach ($cidr in $allowedCidrs) {
        if ($cidr -eq "0.0.0.0/0" -or $cidr -eq "$myIp/32") {
            $isAllowed = $true
            break
        }
    }
    
    if (-not $isAllowed) {
        Write-Host "   Your IP ($myIp) is NOT in the allowed list" -ForegroundColor Yellow
        Write-Host "   Allowed CIDRs: $($allowedCidrs -join ', ')" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Run this to add your IP:" -ForegroundColor Yellow
        $fixCmd = "aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 22 --cidr ${myIp}/32 --region $Region"
        Write-Host $fixCmd -ForegroundColor Cyan
        Write-Host ""
        $needsFix = $true
    }
    else {
        Write-Host "   Your IP is allowed" -ForegroundColor Green
    }
}
Write-Host ""

# Step 4: Test network connectivity
Write-Host "[4/5] Testing network connectivity..." -ForegroundColor Yellow
$tcpTest = Test-NetConnection -ComputerName $TargetIP -Port 22 -WarningAction SilentlyContinue

if ($tcpTest.TcpTestSucceeded) {
    Write-Host "   Port 22 is reachable!" -ForegroundColor Green
}
else {
    Write-Host "   Port 22 is NOT reachable" -ForegroundColor Red
    Write-Host "   This could be due to:" -ForegroundColor Yellow
    Write-Host "     - Security group rules not yet applied (wait 30 seconds)" -ForegroundColor Gray
    Write-Host "     - Network ACLs blocking traffic" -ForegroundColor Gray
    Write-Host "     - Instance firewall (ufw/iptables) blocking SSH" -ForegroundColor Gray
}
Write-Host ""

# Step 5: Verify SSH key
Write-Host "[5/5] Checking SSH key..." -ForegroundColor Yellow
$keyPath = "C:\Users\yash4\downloads\trevel-key.pem"

if (Test-Path $keyPath) {
    Write-Host "   Key file found: $keyPath" -ForegroundColor Green
    Write-Host "   Expected key name: $keyName" -ForegroundColor Gray
}
else {
    Write-Host "   Key file not found at: $keyPath" -ForegroundColor Red
    Write-Host "   Expected key name: $keyName" -ForegroundColor Gray
}
Write-Host ""

# Summary
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

if ($needsFix) {
    Write-Host "Issues found! See fixes above." -ForegroundColor Red
}
else {
    Write-Host "Configuration looks good!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Try connecting with:" -ForegroundColor Yellow
    $sshCmd = "ssh -i `"$keyPath`" ubuntu@$TargetIP"
    Write-Host $sshCmd -ForegroundColor Cyan
}
Write-Host ""
