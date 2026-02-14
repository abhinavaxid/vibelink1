#!/usr/bin/env pwsh
<#
.SYNOPSIS
Diagnose and fix VibeLink backend connectivity issues
.DESCRIPTION
Checks if backend services are running and accessible, provides fixes
#>

param(
    [switch]$Fix,
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"

Write-Host "`n=== VibeLink Backend Diagnostic ===" -ForegroundColor Cyan

# Check Docker
Write-Host "`n[1] Checking Docker..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "  [OK] $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "  [FAIL] Docker not found or not running" -ForegroundColor Red
    exit 1
}

# Check Docker Compose
Write-Host "`n[2] Checking Docker Compose..." -ForegroundColor Yellow
try {
    $composeVersion = docker-compose --version
    Write-Host "  [OK] $composeVersion" -ForegroundColor Green
} catch {
    Write-Host "  [FAIL] Docker Compose not found" -ForegroundColor Red
    exit 1
}

# Check container status
Write-Host "`n[3] Checking containers..." -ForegroundColor Yellow
Set-Location "$PSScriptRoot\backend"

$containers = docker-compose ps --format json | ConvertFrom-Json
$postgresRunning = $containers | Where-Object { $_.Service -eq "postgres" -and $_.State -like "Up*" }
$redisRunning = $containers | Where-Object { $_.Service -eq "redis" -and $_.State -like "Up*" }
$backendRunning = $containers | Where-Object { $_.Service -eq "backend" -and $_.State -like "Up*" }

if ($postgresRunning) {
    Write-Host "  [OK] PostgreSQL running" -ForegroundColor Green
} else {
    Write-Host "  [FAIL] PostgreSQL not running" -ForegroundColor Red
}

if ($redisRunning) {
    Write-Host "  [OK] Redis running" -ForegroundColor Green
} else {
    Write-Host "  [FAIL] Redis not running" -ForegroundColor Red
}

if ($backendRunning) {
    Write-Host "  [OK] Backend running" -ForegroundColor Green
} else {
    Write-Host "  [FAIL] Backend not running" -ForegroundColor Red
}

# Check backend health
Write-Host "`n[4] Checking backend health..." -ForegroundColor Yellow
try {
    $health = Invoke-WebRequest -Uri "http://localhost:5000/health" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
    Write-Host "  [OK] Backend health: $($health.Content)" -ForegroundColor Green
} catch {
    Write-Host "  [FAIL] Backend not responding" -ForegroundColor Red
    Write-Host "       Error: $_" -ForegroundColor Yellow
}

# Check database connectivity
Write-Host "`n[5] Checking database..." -ForegroundColor Yellow
try {
    docker-compose exec -T postgres pg_isready -U vibelink 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] PostgreSQL responding" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] PostgreSQL not responding" -ForegroundColor Red
    }
} catch {
    Write-Host "  [FAIL] Could not check PostgreSQL" -ForegroundColor Red
}

# Check Redis
Write-Host "`n[6] Checking Redis..." -ForegroundColor Yellow
try {
    docker-compose exec -T redis redis-cli ping 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Redis responding" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] Redis not responding" -ForegroundColor Red
    }
} catch {
    Write-Host "  [FAIL] Could not check Redis" -ForegroundColor Red
}

# Offer fixes
if ($Fix -or (-not $postgresRunning) -or (-not $backendRunning)) {
    Write-Host "`n=== Applying Fixes ===" -ForegroundColor Cyan
    
    Write-Host "`n[*] Stopping old containers..." -ForegroundColor Yellow
    docker-compose down -v --remove-orphans 2>$null
    Start-Sleep -Seconds 2
    
    Write-Host "[*] Starting PostgreSQL..." -ForegroundColor Yellow
    docker-compose up -d postgres
    
    Write-Host "[*] Waiting for PostgreSQL to be ready (20 seconds)..." -ForegroundColor Yellow
    Start-Sleep -Seconds 20
    
    Write-Host "[*] Starting Redis..." -ForegroundColor Yellow
    docker-compose up -d redis
    
    Write-Host "[*] Starting Backend..." -ForegroundColor Yellow
    docker-compose up -d backend
    
    Write-Host "[*] Waiting for backend to initialize (15 seconds)..." -ForegroundColor Yellow
    Start-Sleep -Seconds 15
    
    Write-Host "`n=== Verification ===" -ForegroundColor Cyan
    
    # Verify backend health
    $attempts = 0
    $maxAttempts = 10
    while ($attempts -lt $maxAttempts) {
        try {
            $health = Invoke-WebRequest -Uri "http://localhost:5000/health" -UseBasicParsing -TimeoutSec 3
            Write-Host "[OK] Backend is healthy!" -ForegroundColor Green
            break
        } catch {
            $attempts++
            if ($attempts -lt $maxAttempts) {
                Write-Host "[*] Waiting for backend... ($attempts/$maxAttempts)" -ForegroundColor Yellow
                Start-Sleep -Seconds 2
            }
        }
    }
    
    if ($attempts -eq $maxAttempts) {
        Write-Host "[FAIL] Backend did not start" -ForegroundColor Red
        Write-Host "`nView logs with: docker-compose logs backend" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Frontend: http://localhost:3000" -ForegroundColor Green
Write-Host "Backend:  http://localhost:5000" -ForegroundColor Green
Write-Host "Database: localhost:5432" -ForegroundColor Green
Write-Host "Cache:    localhost:6379" -ForegroundColor Green

Write-Host "`nUseful commands:" -ForegroundColor Yellow
Write-Host "  docker-compose logs -f backend       # View backend logs" -ForegroundColor Gray
Write-Host "  docker-compose ps                    # List containers" -ForegroundColor Gray
Write-Host "  curl http://localhost:5000/health    # Check backend health" -ForegroundColor Gray

Write-Host "`nIf frontend still shows 'Failed to fetch':" -ForegroundColor Yellow
Write-Host "  1. Check backend logs: docker-compose logs backend" -ForegroundColor Gray
Write-Host "  2. Clear browser cache: Ctrl+Shift+Delete" -ForegroundColor Gray
Write-Host "  3. Restart frontend: npm run dev" -ForegroundColor Gray
