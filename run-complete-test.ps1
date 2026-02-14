# VibeLink Complete Automation Script
# Starts all services and runs E2E tests
# Usage: .\run-complete-test.ps1

param(
    [bool]$SkipDependencyCheck = $false,
    [bool]$SkipTests = $false,
    [bool]$Headless = $false
)

$ErrorActionPreference = "Continue"

# Colors for output
$colors = @{
    Success = 'Green'
    Warning = 'Yellow'
    Error   = 'Red'
    Info    = 'Cyan'
}

function Write-Log {
    param([string]$Message, [string]$Type = 'Info')
    Write-Host $Message -ForegroundColor $colors[$Type]
}

function Check-Command {
    param([string]$Command)
    $exists = $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
    return $exists
}

# ============================================
# STEP 1: Check prerequisites
# ============================================
Write-Log "`n[CHECK] Checking prerequisites..." -Type Info

if (-not $SkipDependencyCheck) {
    $required = @('docker', 'docker-compose', 'node', 'npm')
    
    foreach ($cmd in $required) {
        if (Check-Command $cmd) {
            Write-Log "  [OK] $cmd found" -Type Success
        } else {
            Write-Log "  [FAIL] $cmd not found - please install it" -Type Error
            exit 1
        }
    }
}

# ============================================
# STEP 2: Stop and clean previous services
# ============================================
Write-Log "`n[CLEAN] Cleaning up previous services..." -Type Info
Set-Location "$PSScriptRoot\backend"

$running = docker-compose ps --services --filter "status=running" 2>$null
if ($running) {
    Write-Log "  Stopping existing containers..." -Type Warning
    docker-compose down -v --remove-orphans 2>$null
    Start-Sleep -Seconds 2
}

# ============================================
# STEP 3: Build and start backend services
# ============================================
Write-Log "`n[DATABASE] Starting PostgreSQL, Redis, and Backend..." -Type Info

Write-Log "  Building Docker image (this may take 5-10 minutes on first run)..." -Type Info
try {
    & docker-compose build --no-cache backend | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Log "  [WARN] Docker build had warnings (continuing...)" -Type Warning
    }
} catch {
    Write-Log "  [WARN] Docker build output (continuing...)" -Type Warning
}

Write-Log "  Starting PostgreSQL and Redis..." -Type Info
docker-compose up -d postgres redis
Write-Log "  [OK] PostgreSQL and Redis started" -Type Success

Start-Sleep -Seconds 5

Write-Log "  Waiting for database to be ready..." -Type Info
$maxRetries = 30
$retries = 0
while ($retries -lt $maxRetries) {
    try {
        docker-compose exec -T postgres pg_isready -U vibelink 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "  [OK] Database ready" -Type Success
            break
        }
    } catch { }
    
    Start-Sleep -Seconds 1
    $retries++
    
    if ($retries -eq $maxRetries) {
        Write-Log "  [WARN] Database check timeout (continuing anyway...)" -Type Warning
    }
}

docker-compose up -d backend
Write-Log "  [OK] Backend started" -Type Success

# Wait for backend to initialize
Start-Sleep -Seconds 10

# ============================================
# STEP 4: Start frontend
# ============================================
Write-Log "`n[FRONTEND] Starting Frontend..." -Type Info
Set-Location $PSScriptRoot

# Check npm dependencies
if (-not (Test-Path "$PSScriptRoot\node_modules")) {
    Write-Log "  Installing npm dependencies (this may take 3-5 minutes)..." -Type Info
    & npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Log "  [WARN] npm install had warnings (continuing...)" -Type Warning
    }
}

Write-Log "  Starting Next.js dev server..." -Type Info
$frontendProcess = Start-Process -FilePath "npm" -ArgumentList "run", "dev" `
    -WorkingDirectory $PSScriptRoot `
    -NoNewWindow `
    -PassThru `
    -ErrorAction Continue

if ($null -eq $frontendProcess) {
    Write-Log "  [FAIL] Failed to start frontend process" -Type Error
} else {
    Write-Log "  [OK] Frontend process started (PID: $($frontendProcess.Id))" -Type Success
}

Start-Sleep -Seconds 10

# ============================================
# STEP 5: Verify services are running
# ============================================
Write-Log "`n[VERIFY] Verifying services..." -Type Info

$services = @(
    @{ Name = "Backend Health"; Url = "http://localhost:5000/health"; Expected = 200 },
    @{ Name = "Frontend"; Url = "http://localhost:3000"; Expected = 200 }
)

foreach ($service in $services) {
    $serviceOk = $false
    for ($i = 0; $i -lt 5; $i++) {
        try {
            $response = Invoke-WebRequest -Uri $service.Url -UseBasicParsing -ErrorAction SilentlyContinue -TimeoutSec 3
            if ($response.StatusCode -eq $service.Expected) {
                Write-Log "  [OK] $($service.Name): Running" -Type Success
                $serviceOk = $true
                break
            }
        } catch {
            # Continue retrying
        }
        Start-Sleep -Seconds 2
    }
    
    if (-not $serviceOk) {
        Write-Log "  [WARN] $($service.Name): Not responding yet (might start during tests)" -Type Warning
    }
}

# ============================================
# STEP 6: Run E2E Tests
# ============================================
if (-not $SkipTests) {
    Write-Log "`n[TEST] Running E2E Tests..." -Type Info
    Write-Log "  Installing test dependencies..." -Type Info
    
    try {
        npm install selenium-webdriver chromedriver --save-dev 2>$null
    } catch {
        Write-Log "  [WARN] Selenium/Chrome driver install had issues (continuing...)" -Type Warning
    }
    
    Write-Log "  Starting automation tests..." -Type Info
    $testFailed = $false
    
    try {
        $env:FRONTEND_URL = "http://localhost:3000"
        $env:BACKEND_URL = "http://localhost:5000"
        
        if ($Headless) {
            $env:HEADLESS = "true"
        }
        
        & npm run test:automation
        if ($LASTEXITCODE -ne 0) {
            $testFailed = $true
        }
    } catch {
        $testFailed = $true
        Write-Log "  [WARN] Tests completed with issues: $_" -Type Warning
    }
}

# ============================================
# STEP 7: Summary
# ============================================
Write-Log "`n========================================" -Type Info
Write-Log "     VibeLink Services Running        " -Type Info
Write-Log "========================================" -Type Info
Write-Log "  Web Frontend:     http://localhost:3000" -Type Info
Write-Log "  REST API:         http://localhost:5000" -Type Info
Write-Log "  PostgreSQL:       localhost:5432" -Type Info
Write-Log "  Redis Cache:      localhost:6379" -Type Info
Write-Log "========================================" -Type Info

Write-Log "`n[COMMANDS] Available commands:" -Type Info
Write-Log "  npm run dev              - Frontend dev server" -Type Info
Write-Log "  npm run test:automation  - Run Selenium tests" -Type Info
Write-Log "  npm run test:all         - Run all tests" -Type Info
Write-Log "  npm run build            - Build frontend" -Type Info

Write-Log "`n[STOP] To stop services:" -Type Info
Write-Log "  Backend/DB: cd backend && docker-compose down -v" -Type Info
if ($null -ne $frontendProcess) {
    Write-Log "  Frontend: Stop-Process -Id $($frontendProcess.Id)" -Type Info
}

if (-not $testFailed) {
    Write-Log "`n[SUCCESS] All systems operational! Ready for testing." -Type Success
} else {
    Write-Log "`n[WARNING] Services running but tests had issues. Check logs above." -Type Warning
}

# Keep script running
Write-Log "`n[INFO] Press Ctrl+C to stop all services..." -Type Info
while ($true) {
    Start-Sleep -Seconds 60
}
