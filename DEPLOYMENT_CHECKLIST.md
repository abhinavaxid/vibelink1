# Render Deployment Checklist

## Pre-Deployment (Local Setup)

- [ ] All code committed to GitHub
- [ ] No API keys/secrets in repository
- [ ] `.env` files are in `.gitignore`
- [ ] Both `npm run build` commands work locally
- [ ] Both `npm start` commands work locally
- [ ] npm test passes (83% acceptable for MVP)
- [ ] No TypeScript compilation errors
- [ ] All dependencies in package.json

## Render Account Setup

- [ ] Create Render account (render.com)
- [ ] Connect GitHub account
- [ ] Verify billing method

## Database Setup

### PostgreSQL
- [ ] Create PostgreSQL instance on Render
- [ ] Copy database connection details
- [ ] Note: Host, Port, User, Password, Database name
- [ ] Test connection locally (optional):
  ```bash
  psql postgresql://user:password@host:port/database
  ```

### Redis
- [ ] Create Redis instance on Render
- [ ] Copy Redis connection URL
- [ ] Format: `redis://user:password@host:port`

## Backend Deployment

### Before Deploy
- [ ] Update `backend/.env.example` with all required vars
- [ ] Verify `backend/package.json` has build + start scripts
- [ ] Check `backend/tsconfig.json` outputs to `dist/`
- [ ] Confirm `NODE_ENV=production` works locally

### Create Service
- [ ] New Web Service on Render
- [ ] Connect GitHub repo
- [ ] Set build command: `cd backend && npm install && npm run build`
- [ ] Set start command: `cd backend && npm start`
- [ ] Set environment variables:
  - [ ] `NODE_ENV` = `production`
  - [ ] `PORT` = `5000` (Render will override to dynamic port)
  - [ ] `SOCKET_PORT` = `4000`
  - [ ] `DB_HOST` = PostgreSQL host
  - [ ] `DB_PORT` = `5432`
  - [ ] `DB_USER` = `postgres`
  - [ ] `DB_PASSWORD` = PostgreSQL password
  - [ ] `DB_NAME` = `vibelink`
  - [ ] `DB_POOL_SIZE` = `20`
  - [ ] `REDIS_URL` = Redis connection URL
  - [ ] `JWT_SECRET` = (generate strong random string)
  - [ ] `CORS_ORIGIN` = Your frontend URL

### After Deploy
- [ ] Wait for green ✅ status
- [ ] Check logs for errors
- [ ] Test health endpoint: `https://vibelink-backend.onrender.com/api/health`
- [ ] Note backend URL for frontend config

## Frontend Deployment

### Before Deploy
- [ ] Update `.env.example` with API URL
- [ ] Verify `package.json` has build + start scripts
- [ ] Check all API calls use env variable URLs
- [ ] Test locally: `npm run build && npm start`

### Create Service
- [ ] New Web Service on Render
- [ ] Connect GitHub repo (same repo, root)
- [ ] Set build command: `npm install && npm run build`
- [ ] Set start command: `npm start`
- [ ] Set environment variables:
  - [ ] `NEXT_PUBLIC_API_URL` = Your backend URL (from app logs)
  - [ ] `NEXT_PUBLIC_SOCKET_URL` = Same as API URL

### After Deploy
- [ ] Wait for green ✅ status
- [ ] Check logs for errors
- [ ] Visit frontend URL in browser
- [ ] Test login flow
- [ ] Check browser console for errors
- [ ] Verify API calls reach backend (Network tab)

## Post-Deployment Testing

### Functional Tests
- [ ] Frontend loads without errors
- [ ] Can navigate pages
- [ ] User registration works
- [ ] User login works
- [ ] User profile displays
- [ ] API calls reach backend (no CORS errors)
- [ ] Real-time features work (if using WebSocket)

### Performance Check
- [ ] Page loads in <3s
- [ ] API responses <1s
- [ ] No memory leaks (check Render dashboard)
- [ ] CPU usage reasonable (<50%)

### Database Tests
- [ ] Data persists after restart
- [ ] User registration creates DB entry
- [ ] Profile updates save correctly
- [ ] No connection timeouts

## Monitoring & Maintenance

- [ ] Check Render dashboard daily (first week)
- [ ] Monitor error logs
- [ ] Track CPU/memory usage
- [ ] Set up error alerts (Sentry recommended)
- [ ] Automated backups enabled

## Scaling (If Needed)

- [ ] Monitor usage metrics
- [ ] Upgrade plans if hitting limits
- [ ] Optimize database queries if slow
- [ ] Add more Redis if cache hit rate low
- [ ] Enable auto-scaling if available

## DNS & Domain (Optional)

- [ ] Purchase domain (GoDaddy, Namecheap, etc.)
- [ ] Add custom domain in Render settings
- [ ] Update DNS to point to Render
- [ ] SSL automatically provisioned

## Common Issues to Watch For

- [ ] ❌ Backend failing to start? → Check env vars and logs
- [ ] ❌ Frontend can't reach API? → Verify CORS_ORIGIN
- [ ] ❌ WebSocket disconnects? → Need HTTPS (Render provides)
- [ ] ❌ Database errors? → Check connection string
- [ ] ❌ Out of memory? → Upgrade plan or optimize code

## Rollback Plan

If deployment breaks:

```bash
# Option 1: Rollback via Render dashboard
# Service → Settings → Deployments → Select previous version → Deploy

# Option 2: Git rollback
git revert <commit-hash>
git push origin main
# Render auto-deploys previous version
```

## Success Criteria

✅ All checks pass before marking deployment complete:

1. Frontend loads (render.com URL works)
2. Backend API responds (health check passes)
3. Database connected (queries execute)
4. Authentication works (register + login)
5. Data persists (check after restart)
6. No error logs in Render console
7. <3s page load time
8. Can run `npm test` in local checkout

---

**Estimated Setup Time**: 30-45 minutes
**Deployment Time**: 10-15 minutes (after setup)
