# VibeLink Complete Automation Testing Guide

## Overview

This guide provides step-by-step instructions to run the complete VibeLink application with all services and automated E2E tests.

## What Gets Tested

The automation test suite includes:

1. ✅ **Health Check** - Backend API health endpoint
2. ✅ **Frontend Load** - Next.js app loads properly
3. ✅ **User Registration** - New user can register
4. ✅ **User Login** - Registered user can login
5. ✅ **API Endpoints** - REST API endpoints respond
6. ✅ **Room Creation** - User can create game rooms (if implemented)

## Prerequisites

### System Requirements
- Windows/Mac/Linux with PowerShell or Bash
- Docker Desktop installed and running
- Node.js 18+ and npm
- Chrome/Chromium browser (for Selenium tests)
- 4+ GB RAM, 20+ GB disk space

### Install Docker
1. Download [Docker Desktop](https://www.docker.com/products/docker-desktop)
2. Install and restart your system
3. Verify: `docker --version`

### Install Node.js
1. Download from [nodejs.org](https://nodejs.org) (LTS version)
2. Install and restart terminal
3. Verify: `node --version` and `npm --version`

---

## Quick Start (5 minutes)

### Option 1: Automated Setup (Recommended)

**Windows PowerShell:**
```powershell
cd d:\Projects\Vibelink
.\run-complete-test.ps1
```

**Windows Command Prompt:**
```batch
cd d:\Projects\Vibelink
run-complete-test.bat
```

**Mac/Linux:**
```bash
cd ~/Projects/Vibelink
chmod +x run-complete-test.ps1
pwsh run-complete-test.ps1
```

This will:
- ✅ Start PostgreSQL, Redis in Docker
- ✅ Build and start Backend API
- ✅ Start Frontend (Next.js)
- ✅ Run automated E2E tests
- ✅ Display comprehensive test report

### Option 2: Manual Setup (for debugging)

#### Step 1: Start Backend Services

```bash
cd d:\Projects\Vibelink\backend

# Start Docker containers
docker-compose down -v
docker-compose up -d postgres redis

# Wait for database (10 seconds)
Start-Sleep -Seconds 10

# Verify database is ready
docker-compose exec postgres pg_isready -U vibelink

# Start backend
docker-compose up -d backend

# Verify health
curl http://localhost:5000/health
```

Expected output:
```json
{"status":"ok","timestamp":"2026-02-14T...","environment":"development"}
```

#### Step 2: Start Frontend

In **new terminal**:
```bash
cd d:\Projects\Vibelink

# Install dependencies (first time only)
npm install

# Start development server
npm run dev
```

Expected output:
```
▲ Next.js 15.x
- Local: http://localhost:3000
```

#### Step 3: Manual Testing

Open browser and test manually:

1. **Register**: http://localhost:3000/login
   - Click "JOIN VIBE"
   - Fill in: Email, Username, Password
   - Click "JOIN VIBE" button
   - Should redirect to lobby

2. **Login**: http://localhost:3000/login
   - Click "Log In"
   - Enter credentials
   - Click "Sign In"
   - Should show dashboard

3. **Create Room**: In lobby
   - Click "Create Room" or similar
   - Enter room name
   - Click "Create"

4. **Join Game**: 
   - Select a room
   - Join and start playing

#### Step 4: Run Automated Tests

In **new terminal**:
```bash
cd d:\Projects\Vibelink

# Install test dependencies
npm install

# Run Selenium automation tests
npm run test:automation
```

The script will:
- Open Chrome browser
- Register a new user
- Login with credentials
- Navigate through the app
- Generate test report

---

## Test Results Interpretation

### Success Example
```
╔════════════════════════════════════════════════╗
║         VibeLink Automation Tests              ║
╠════════════════════════════════════════════════╣
✅ PASS | Health Check
✅ PASS | Frontend Loads
✅ PASS | User Registration
✅ PASS | User Login
✅ PASS | API Endpoints
⚠️ SKIP | Room Creation
╠════════════════════════════════════════════════╣
Total: 6 | Passed: 5 | Failed: 0 | Skipped: 1
╚════════════════════════════════════════════════╝
```

### Troubleshooting Test Failures

#### "Cannot GET /health"
- **Problem**: Backend not responding
- **Solution**: Check `docker-compose logs backend`

#### "Cannot find Chrome"
- **Problem**: Selenium can't find browser
- **Solution**: 
  ```bash
  # Install Chrome if missing
  # Windows: Download from google.com/chrome
  # Mac: brew install --cask google-chrome
  # Linux: sudo apt-get install chromium-browser
  ```

#### "Connection refused"
- **Problem**: Services not running
- **Solution**: Verify all containers: `docker-compose ps`

#### "Database does not exist"
- **Problem**: Database initialization failed
- **Solution**:
  ```bash
  docker-compose down -v
  docker-compose up postgres
  Start-Sleep -Seconds 20
  ```

---

## Advanced Options

### Run Tests with Custom Settings

```powershell
# Run without tests (just start services)
.\run-complete-test.ps1 -SkipTests $true

# Run tests in headless mode (no browser window)
.\run-complete-test.ps1 -Headless $true

# Skip dependency check
.\run-complete-test.ps1 -SkipDependencyCheck $true
```

### Run Individual Test Types

```bash
cd d:\Projects\Vibelink

# Run only Selenium automation tests
npm run test:automation

# Run only API tests
npm run test:e2e

# Run all tests
npm run test:all
```

### Modify Test Data

Edit [automation.test.js](../tests/automation.test.js) to change test user:

```javascript
const testUser = {
  email: `test-${Date.now()}@vibelink.com`,
  username: `testuser-${Date.now()}`,
  password: 'TestPassword123!',
};
```

---

## Service Status Checks

### Check all services running

```bash
cd d:\Projects\Vibelink\backend

# List all containers
docker-compose ps

# View service logs
docker-compose logs postgres    # Database logs
docker-compose logs redis       # Cache logs
docker-compose logs backend     # API logs
```

### Check Frontend

```bash
# Test frontend load
curl http://localhost:3000 -I

# Check next.js is running
curl http://localhost:3000/api/health
```

### Check Backend API

```bash
# Health check
curl http://localhost:5000/health

# List rooms
curl http://localhost:5000/api/rooms -H "Authorization: Bearer TOKEN"

# List users (requires token)
curl http://localhost:5000/api/users/me -H "Authorization: Bearer TOKEN"
```

### Check Database

```bash
# Connect and list tables
docker-compose exec postgres psql -U vibelink -d vibelink_db

# Inside psql:
\dt                          # List tables
SELECT COUNT(*) FROM users;  # Count users
SELECT * FROM users LIMIT 5; # View users
\q                           # Exit
```

### Check Redis

```bash
# Connect to Redis CLI
docker-compose exec redis redis-cli

# Inside redis-cli:
PING                    # Check connection
KEYS *                  # List all keys
GET sessionkey          # Get a value
FLUSHALL                # Clear all data
EXIT                    # Exit
```

---

## Stopping Services

### Stop All Services

```bash
# Stop all containers (keep data)
cd d:\Projects\Vibelink\backend
docker-compose stop

# Stop and remove containers (keep data)
docker-compose down

# Stop, remove containers AND delete data
docker-compose down -v

# Kill frontend process
Stop-Process -Name "node" -ErrorAction SilentlyContinue
```

### Restart Services

```bash
cd d:\Projects\Vibelink\backend
docker-compose restart
```

---

## Performance Optimization

### Reduce Test Duration

```powershell
# Run tests without rebuilding Docker image
.\run-complete-test.ps1
# (skips rebuild on subsequent runs)
```

### Cache npm Dependencies

```bash
# Docker will cache npm installs between runs
# Just don't use --no-cache if rebuilding
docker-compose build backend
```

---

## Continuous Integration

### GitHub Actions (CI/CD)

Create `.github/workflows/e2e-tests.yml`:

```yaml
name: E2E Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15-alpine
        env:
          POSTGRES_USER: vibelink
          POSTGRES_PASSWORD: vibelink_password
          POSTGRES_DB: vibelink_db
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v2
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: npm install

      - name: Run tests
        run: npm run test:automation
```

---

## Logs and Debugging

### Enable Debug Mode

```bash
# Backend debug logs
DEBUG=* npm run dev

# Docker compose logs with timestamps
docker-compose logs --timestamps --tail=100 backend
```

### Save Test Screenshots

Modify [automation.test.js](../tests/automation.test.js) to add:

```javascript
// After each test failure:
const screenshot = await driver.takeScreenshot();
fs.writeFileSync(`./screenshots/test-${Date.now()}.png`, screenshot, 'base64');
```

---

## Common Issues & Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| Port 5000 in use | Another app using it | `netstat -ano \| findstr :5000` then kill PID |
| Port 3000 in use | Another app using it | `netstat -ano \| findstr :3000` then kill PID |
| Docker can't connect | Docker daemon not running | Start Docker Desktop |
| Database errors | Old volume data | `docker-compose down -v` |
| Test timeouts | Services slow to start | Increase timeout in automation.test.js |
| Chrome not found | Missing browser | Install Chrome/Chromium |
| CORS errors | Backend URL mismatch | Verify `.env` variables |

---

## Next Steps

1. ✅ Run complete test suite: `.\run-complete-test.ps1`
2. ✅ Review test report and fix any failures
3. ✅ Customize tests for your features
4. ✅ Set up CI/CD pipeline
5. ✅ Deploy to Render

---

## Additional Resources

- [Backend README](../backend/README.md)
- [Render Deployment](../RENDER_DEPLOYMENT.md)
- [API Documentation](../API_INTEGRATION_GUIDE.md)
- [Database Schema](../DATABASE_SCHEMA.md)

---

## Support

For issues or questions:
1. Check [troubleshooting section](#common-issues--solutions)
2. View service logs: `docker-compose logs`
3. Check test output: `npm run test:automation`
4. Review source code: [automation.test.js](../tests/automation.test.js)
