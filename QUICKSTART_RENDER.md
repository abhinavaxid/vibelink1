# Quick Render Deployment Guide (30 mins)

## TL;DR - 5 Step Process

### Step 1: Prepare Code (5 mins)
```bash
cd d:\Projects\Vibelink
git add .
git commit -m "Ready for Render deployment"
git push origin main
```

✅ Your code is now on GitHub ready for Render to deploy

### Step 2: Create Database & Cache (5 mins)

1. Go to [render.com](https://render.com)
2. **New** → **PostgreSQL**
   - Name: `vibelink-postgres`
   - Database: `vibelink`
   - Grab connection details
3. **New** → **Redis**
   - Name: `vibelink-redis`
   - Grab connection URL

### Step 3: Deploy Backend (10 mins)

1. **New** → **Web Service**
2. Select your GitHub repo
3. Configuration:
   ```
   Name: vibelink-backend
   Branch: main
   Build: cd backend && npm install && npm run build
   Start: cd backend && npm start
   ```
4. **Environment** (copy from [RENDER_ENV_TEMPLATE.md](RENDER_ENV_TEMPLATE.md)):
   - All `DB_*` variables from PostgreSQL
   - `REDIS_URL` from Redis
   - `JWT_SECRET`: Generate strong secret
   - `CORS_ORIGIN`: https://vibelink.onrender.com

5. **Create** → Wait for ✅ green status
6. Note your backend URL (e.g., `https://vibelink-backend.onrender.com`)

### Step 4: Deploy Frontend (10 mins)

1. **New** → **Web Service**
2. Same repo, root directory
3. Configuration:
   ```
   Name: vibelink-frontend
   Branch: main
   Build: npm install && npm run build
   Start: npm start
   ```
4. **Environment**:
   ```
   NEXT_PUBLIC_API_URL = https://vibelink-backend.onrender.com
   NEXT_PUBLIC_SOCKET_URL = https://vibelink-backend.onrender.com
   ```

5. **Create** → Wait for ✅ green status
6. Click your frontend URL when ready

### Step 5: Verify It Works (5 mins)

```bash
# Test backend health
curl https://vibelink-backend.onrender.com/api/health
# Should return: {"status":"ok"}

# Visit frontend
https://vibelink.onrender.com

# Test login
- Register new account
- Login with that account
- Check profile loads
```

✅ **Done!** Your app is live on Render

---

## Need Help?

| Problem | Solution |
|---------|----------|
| Build fails | Check **Logs** tab → see error |
| App won't start | Check env vars are correct |
| API calls fail | Verify `NEXT_PUBLIC_API_URL` and `CORS_ORIGIN` |
| Database errors | Confirm connection string from PostgreSQL instance |

## Important Variables Cheat Sheet

```
Backend needs:
- DB_HOST, DB_USER, DB_PASSWORD, DB_NAME
- REDIS_URL
- JWT_SECRET
- CORS_ORIGIN = frontend URL

Frontend needs:
- NEXT_PUBLIC_API_URL = backend URL
- NEXT_PUBLIC_SOCKET_URL = backend URL
```

## Cost
- Backend Web Service: ~$7/month
- Frontend Web Service: ~$7/month
- PostgreSQL: ~$15/month
- Redis: ~$6/month
- **Total: ~$35/month**

---

See [RENDER_DEPLOYMENT.md](RENDER_DEPLOYMENT.md) for full guide with troubleshooting & scaling.
