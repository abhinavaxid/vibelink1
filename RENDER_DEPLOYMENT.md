# Render Deployment Guide for VibeLink

## Overview

Render is an excellent choice for VibeLink because it:
- ✅ Supports Node.js backend deployment
- ✅ Native Next.js support for frontend
- ✅ Managed PostgreSQL & Redis services
- ✅ Auto-deploys from Git
- ✅ SSL/HTTPS included
- ✅ Pay-as-you-go pricing with free tier options

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Render Platform                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────┐  ┌──────────────────────────┐   │
│  │  Frontend        │  │  Backend                 │   │
│  │  (Next.js)       │  │  (Express + TypeScript)  │   │
│  │  Port: 3000      │  │  Port: 5000              │   │
│  │  render.com      │  │  render.com              │   │
│  └──────────────────┘  └──────────────────────────┘   │
│         │                        │                     │
│         └────────────┬───────────┘                     │
│                      │                                 │
│  ┌──────────────────────────────────────────────────┐  │
│  │  PostgreSQL Database   │   Redis Cache            │  │
│  │  (Managed)             │   (Managed)              │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Step-by-Step Deployment

### Phase 1: Prepare Your Code (Local)

#### 1. Create `.env.example` files for reference

**Frontend** - `src/.env.example`:
```
NEXT_PUBLIC_API_URL=https://vibelink-backend.onrender.com
NEXT_PUBLIC_SOCKET_URL=https://vibelink-backend.onrender.com
```

**Backend** - `backend/.env.example`:
```
# Server
PORT=5000
SOCKET_PORT=4000
NODE_ENV=production

# Database
DB_HOST=your-postgres-host.onrender.com
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=your-secure-password
DB_NAME=vibelink
DB_POOL_SIZE=20

# Redis
REDIS_URL=redis://your-redis-user:your-password@your-redis-host:6379

# Security
JWT_SECRET=your-very-secure-jwt-secret-key
CORS_ORIGIN=https://vibelink.onrender.com

# Environment
NODE_ENV=production
```

#### 2. Ensure proper build scripts

Your `backend/package.json` already has:
```json
"scripts": {
  "build": "tsc",
  "start": "node dist/index.js"
}
```

Your `package.json` (frontend) already has:
```json
"scripts": {
  "build": "next build",
  "start": "next start"
}
```

✅ **These are correct for Render**

#### 3. Create `render.yaml` for infrastructure-as-code (Optional but Recommended)

Create `render.yaml` in your root directory:

```yaml
services:
  - type: web
    name: vibelink-backend
    env: node
    plan: standard
    buildCommand: cd backend && npm install && npm run build
    startCommand: cd backend && npm start
    envVars:
      - key: NODE_ENV
        value: production
      - key: PORT
        value: 5000
      - key: SOCKET_PORT
        value: 4000
      - key: DB_HOST
        fromDatabase:
          name: vibelink-postgres
          property: host
      - key: DB_PORT
        fromDatabase:
          name: vibelink-postgres
          property: port
      - key: DB_USER
        fromDatabase:
          name: vibelink-postgres
          property: user
      - key: DB_PASSWORD
        fromDatabase:
          name: vibelink-postgres
          property: password
      - key: DB_NAME
        fromDatabase:
          name: vibelink-postgres
          property: database
      - key: REDIS_URL
        fromService:
          name: vibelink-redis
          property: connectionString
      - key: JWT_SECRET
        sync: false
      - key: CORS_ORIGIN
        value: https://vibelink.onrender.com

  - type: web
    name: vibelink-frontend
    env: node
    plan: standard
    buildCommand: npm install && npm run build
    startCommand: npm start
    routes:
      - path: /
        destination: /
    envVars:
      - key: NEXT_PUBLIC_API_URL
        value: https://vibelink-backend.onrender.com
      - key: NEXT_PUBLIC_SOCKET_URL
        value: https://vibelink-backend.onrender.com

databases:
  - name: vibelink-postgres
    databaseName: vibelink
    user: postgres
    plan: standard

services:
  - name: vibelink-redis
    plan: standard
```

### Phase 2: Deploy to Render (Manual Steps)

#### Step 1: Create PostgreSQL Database

1. Go to [render.com](https://render.com) → Sign up/Login
2. Click **"New"** → **"PostgreSQL"**
3. Configuration:
   - **Name**: `vibelink-postgres`
   - **Database**: `vibelink`
   - **User**: `postgres`
   - **Region**: Choose closest to your users
   - **Plan**: Standard ($9/month) or development ($7/month)
4. Click **"Create Database"**
5. **Copy the connection string** (you'll need it)

#### Step 2: Create Redis Cache

1. Click **"New"** → **"Redis"**
2. Configuration:
   - **Name**: `vibelink-redis`
   - **Region**: Same as database
   - **Plan**: Standard or Free (limited)
3. Click **"Create Redis"**
4. **Copy the connection URL**

#### Step 3: Deploy Backend

1. Push your code to GitHub (if not already)
   ```bash
   git add .
   git commit -m "Prepare for Render deployment"
   git push origin main
   ```

2. On Render dashboard, click **"New"** → **"Web Service"**
3. Configuration:
   - **Repository**: Select your VibeLink GitHub repo
   - **Branch**: `main`
   - **Name**: `vibelink-backend`
   - **Region**: Same as database
   - **Build Command**: `cd backend && npm install && npm run build`
   - **Start Command**: `cd backend && npm start`
   - **Plan**: Standard ($7/month minimum)

4. **Environment Variables** (click "Advanced"):
   ```
   NODE_ENV = production
   PORT = 5000
   SOCKET_PORT = 4000
   DB_HOST = [from PostgreSQL instance connection string]
   DB_PORT = 5432
   DB_USER = postgres
   DB_PASSWORD = [from PostgreSQL instance]
   DB_NAME = vibelink
   DB_POOL_SIZE = 20
   REDIS_URL = [from Redis instance connection string]
   JWT_SECRET = [generate a strong random string]
   CORS_ORIGIN = https://vibelink.onrender.com
   ```

5. Click **"Create Web Service"**

**Wait for deployment to complete** (usually 3-5 minutes)

#### Step 4: Run Database Migrations

After backend deploys:

1. Get your backend URL (e.g., `https://vibelink-backend.onrender.com`)
2. In Render console dashboard:
   - Select your backend service
   - Click **"Shell"** tab
   - Run: `npm run migrate` (if you have migration scripts)
   - Or manually create schema if needed

#### Step 5: Deploy Frontend

1. On Render dashboard, click **"New"** → **"Web Service"**
2. Configuration:
   - **Repository**: Select your VibeLink GitHub repo
   - **Branch**: `main`
   - **Name**: `vibelink-frontend`
   - **Region**: Same as backend
   - **Build Command**: `npm install && npm run build`
   - **Start Command**: `npm start`
   - **Plan**: Standard ($7/month)

3. **Environment Variables**:
   ```
   NEXT_PUBLIC_API_URL = https://vibelink-backend.onrender.com
   NEXT_PUBLIC_SOCKET_URL = https://vibelink-backend.onrender.com
   ```

4. Click **"Create Web Service"**

**Wait for deployment to complete**

## Post-Deployment Verification

### 1. Test Backend API

```bash
curl https://vibelink-backend.onrender.com/api/health
# Should return: { "status": "ok" }
```

### 2. Check Frontend

Visit `https://vibelink.onrender.com` in your browser

### 3. View Logs

In Render dashboard:
- Select service → **"Logs"** tab
- Check for any errors during startup

### 4. Monitor Performance

- Dashboard shows:
  - CPU usage
  - Memory usage
  - Requests/minute
  - Response times

## Cost Estimation

| Service | Plan | Price/Month |
|---------|------|-------------|
| Backend (Web) | Standard | $7 |
| Frontend (Web) | Standard | $7 |
| PostgreSQL | Standard | $15 |
| Redis | Standard | $6 |
| **Total** | | **$35/month** |

*Free tier options available with limitations*

## Environment Variables Reference

### Backend Variables

| Variable | Value | Notes |
|----------|-------|-------|
| `NODE_ENV` | `production` | Disables debug logs |
| `PORT` | `5000` | REST API port |
| `SOCKET_PORT` | `4000` | WebSocket port |
| `DB_HOST` | PostgreSQL host | From Render instance |
| `DB_PORT` | `5432` | Standard PostgreSQL port |
| `DB_USER` | `postgres` | Database user |
| `DB_PASSWORD` | Your password | From Render instance |
| `DB_NAME` | `vibelink` | Database name |
| `DB_POOL_SIZE` | `20` | Connection pool size |
| `REDIS_URL` | Redis connection URL | From Render instance |
| `JWT_SECRET` | Random 32+ chars | Generate strong secret |
| `CORS_ORIGIN` | Your frontend URL | `https://vibelink.onrender.com` |

### Frontend Variables

| Variable | Value |
|----------|-------|
| `NEXT_PUBLIC_API_URL` | `https://vibelink-backend.onrender.com` |
| `NEXT_PUBLIC_SOCKET_URL` | `https://vibelink-backend.onrender.com` |

## Troubleshooting

### Backend won't start

**Problem**: `Build failed` or `Application failed to start`

**Solutions**:
1. Check logs: **Logs** tab in service details
2. Verify environment variables are set
3. Ensure `build` script outputs to `dist/` directory
4. Check database connection:
   ```bash
   # In Render shell
   psql $DATABASE_URL -c "SELECT 1"
   ```

### Frontend can't reach backend

**Problem**: Homepage works but API calls fail

**Solutions**:
1. Verify `NEXT_PUBLIC_API_URL` includes full URL
2. Check backend `CORS_ORIGIN` includes frontend URL
3. Both must use HTTPS (Render auto-provides)
4. Test API directly: `curl https://vibelink-backend.onrender.com/api/health`

### Database migration failed

**Problem**: Tables don't exist after deployment

**Solutions**:
1. Run migrations manually via Render shell
2. Or create migration script in `backend/scripts/`
3. Call migrations from `npm start` or in separate step

### WebSocket connection fails

**Problem**: Real-time features not working

**Solutions**:
1. WebSocket needs HTTPS (Render provides this)
2. Verify `io()` uses correct backend URL
3. Check CORS headers include origin
4. Both services must be on same domain or CORS must allow

### High memory/CPU usage

**Problem**: Render throttles or service restarts

**Solutions**:
1. Increase plan to use more resources
2. Optimize database queries
3. Add Redis caching for frequently accessed data
4. Implement rate limiting
5. Monitor with Render dashboard metrics

## Auto-Deployment from Git

Render automatically redeploys when you push to GitHub:

```bash
# Make changes locally
git add .
git commit -m "Update feature"
git push origin main

# Render will automatically:
# 1. Trigger build
# 2. Run build command
# 3. Deploy new version
# 4. Restart service
```

To disable auto-deploy or trigger manual redeploy:
- Service dashboard → **"Settings"** → **"Auto-deploy"**

## Scaling Up

When your app needs more power:

1. **Upgrade Web Service Plan**:
   - Render dashboard → Select service
   - **"Settings"** → Change plan
   - More CPU/memory available

2. **Enable Auto-scaling** (Pro plans):
   - Automatically scale based on load

3. **Use PostgreSQL read replicas**:
   - For heavy database queries

4. **Upgrade Redis plan**:
   - For better caching performance

## Backup & Recovery

### Database Backups

Render automatically backs up PostgreSQL daily. To restore:

1. Dashboard → PostgreSQL instance
2. **"Backups"** tab
3. Select restore point
4. Click **"Restore"**

### Code Recovery

Since code is on GitHub:
```bash
# If needed, revert to previous commit
git revert <commit-hash>
git push origin main
# Render auto-deploys
```

## Security Checklist

- ✅ All services use HTTPS (automatic)
- ✅ Environment variables for secrets (not in code)
- ✅ JWT_SECRET is strong (32+ random characters)
- ✅ Database password is strong
- ✅ CORS_ORIGIN restricted to your domain
- ✅ No console.log() of sensitive data
- ✅ Rate limiting enabled on API
- ✅ Helmet.js enabled (you have it)

## Next Steps After Deployment

1. **Set up custom domain** (if you own one):
   - Render dashboard → Web Service → Custom Domain
   - Point your domain DNS to Render

2. **Enable Branch Deployments**:
   - Deploy PR previews automatically
   - Dashboard → Service Settings → Branch Deployments

3. **Add monitoring**:
   - Sentry (error tracking)
   - LogRocket (user session tracking)
   - DataDog (performance monitoring)

4. **Set up CI/CD**:
   - Run tests before deployment
   - Automated test runs on every push

## Support & Documentation

- **Render Docs**: https://render.com/docs
- **Node.js on Render**: https://render.com/docs/deploy-node-express-app
- **Next.js on Render**: https://render.com/docs/deploy-nextjs
- **PostgreSQL on Render**: https://render.com/docs/databases

---

**Ready to deploy?** Start with Phase 1 (prepare code) and follow the manual steps in Phase 2!
