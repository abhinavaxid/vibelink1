# VibeLink Complete Automation - Quick Reference

## 🚀 One-Line Setup & Test

```powershell
# Windows PowerShell - starts everything and runs tests
.\run-complete-test.ps1
```

```batch
# Windows CMD - starts everything and runs tests  
run-complete-test.bat
```

---

## What This Does ✨

Automatically:
1. 🐘 Starts PostgreSQL database in Docker
2. 🔴 Starts Redis cache in Docker  
3. ⚙️ Builds and starts Backend API
4. 🎨 Starts Frontend (Next.js)
5. 🧪 Runs Selenium E2E tests
6. 📊 Generates test report

**Total time: ~5-7 minutes**

---

## What Gets Tested ✅

| Test | Purpose | Status |
|------|---------|--------|
| Health Check | Backend API responding | ✅ |
| Frontend Load | Next.js app loads | ✅ |
| User Registration | New user signup works | ✅ |
| User Login | Authentication works | ✅ |
| API Endpoints | REST endpoints respond | ✅ |
| Room Creation | Game room creation | ⚠️ Optional |

---

## Access Points After Startup

| Service | URL | Purpose |
|---------|-----|---------|
| Frontend | `http://localhost:3000` | Web app |
| Backend API | `http://localhost:5000` | REST API |
| Backend Health | `http://localhost:5000/health` | API status |
| Database | `localhost:5432` | PostgreSQL |
| Cache | `localhost:6379` | Redis |

---

## Troubleshooting

### If services don't start:

```powershell
# 1. Check Docker is running
docker ps

# 2. Clean everything
cd backend
docker-compose down -v

# 3. Start fresh (this will take time)
docker-compose up

# 4. In new terminal, start frontend
npm run dev

# 5. In another terminal, run tests
npm run test:automation
```

### If tests fail:

```powershell
# View backend logs
cd backend
docker-compose logs -f backend

# View full test output
npm run test:automation -- --verbose
```

---

## Manual Testing (Skip Automation)

If you want to test manually without Selenium:

```powershell
# Terminal 1: Start backend services
cd backend
docker-compose down -v
docker-compose up postgres redis backend

# Terminal 2: Start frontend
cd ..
npm install
npm run dev

# Terminal 3: Test manually at browser
# Go to http://localhost:3000
```

---

## Advanced Options

```powershell
# Run without tests (just start services)
.\run-complete-test.ps1 -SkipTests $true

# Run with headless browser (no window)
.\run-complete-test.ps1 -Headless $true

# Skip dependency checks
.\run-complete-test.ps1 -SkipDependencyCheck $true
```

---

## Stop Everything

```powershell
# Stop backend services
cd backend
docker-compose down -v

# Stop frontend (Ctrl+C in terminal) or:
Stop-Process -Name "node"
```

---

## Custom Test User Credentials

Tests use auto-generated email/username:
- Email: `test-{timestamp}@vibelink.com`
- Username: `testuser-{timestamp}`
- Password: `TestPassword123!`

---

## View Full Documentation

See [COMPLETE_TESTING_GUIDE.md](./COMPLETE_TESTING_GUIDE.md) for:
- Prerequisites and setup
- Step-by-step manual testing
- Docker commands reference
- Database queries
- CI/CD integration
- Performance optimization
- Debugging tips

---

## File Structure

```
vibelink/
├── run-complete-test.ps1      ← Run this (PowerShell)
├── run-complete-test.bat      ← Or this (CMD)
├── COMPLETE_TESTING_GUIDE.md  ← Full documentation
├── QUICK_TEST_GUIDE.md        ← This file
├── backend/
│   ├── docker-compose.yml     ← Services config
│   ├── Dockerfile             ← Backend container
│   └── src/
├── tests/
│   ├── automation.test.js     ← Selenium tests
│   └── run-tests.js
└── src/                        ← Frontend app
```

---

## Test Report Example

```
════════════════════════════════════════════════
📊 TEST RESULTS SUMMARY
════════════════════════════════════════════════
✅ PASS | Health Check
✅ PASS | Frontend Loads
✅ PASS | User Registration
✅ PASS | User Login
✅ PASS | API Endpoints
⚠️ SKIP | Room Creation
════════════════════════════════════════════════
Total: 6 | Passed: 5 | Failed: 0 | Skipped: 1
════════════════════════════════════════════════
```

---

## Performance Tips

- First run takes longer (Docker build, npm install)
- Subsequent runs reuse cached Docker layers
- Disable `-no-cache` after first successful build
- Browser opens only for Selenium tests
- Run with `-Headless $true` for CI/CD

---

## Useful Commands While Testing

```powershell
# View all services
docker-compose ps

# View service logs
docker-compose logs -f backend

# Connect to database
docker-compose exec postgres psql -U vibelink -d vibelink_db

# Connect to Redis
docker-compose exec redis redis-cli

# Rebuild specific service
docker-compose build --no-cache backend

# Restart all services
docker-compose restart
```

---

## Next: Deploy to Render

After successful local testing:

1. Push code to GitHub: `git push`
2. Follow [RENDER_DEPLOYMENT.md](./RENDER_DEPLOYMENT.md)
3. Create Render services for Backend & Frontend
4. Point to PostgreSQL and Redis on Render
5. Deploy and test live app

---

**Ready? Let's test!** 🚀

```powershell
.\run-complete-test.ps1
```
