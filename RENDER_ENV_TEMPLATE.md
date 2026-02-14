# Render Deployment Environment Variables
# Copy these to Render dashboard when creating services

## BACKEND ENVIRONMENT VARIABLES

# Server Configuration
NODE_ENV=production
PORT=5000
SOCKET_PORT=4000

# Database Configuration
# Get these from Render PostgreSQL instance dashboard
DB_HOST=your-postgres-instance-name.c.aivencloud.com
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=your-postgres-password
DB_NAME=vibelink
DB_POOL_SIZE=20

# Redis Configuration
# Get this from Render Redis instance dashboard
REDIS_URL=redis://default:your-redis-password@your-redis-instance.aivencloud.com:6379

# Security
# Generate with: openssl rand -hex 32
JWT_SECRET=your-generated-jwt-secret-here

# CORS Configuration
# Set to your frontend Render URL
CORS_ORIGIN=https://vibelink.onrender.com

## FRONTEND ENVIRONMENT VARIABLES

# API Configuration
# Set to your backend Render URL
NEXT_PUBLIC_API_URL=https://vibelink-backend.onrender.com
NEXT_PUBLIC_SOCKET_URL=https://vibelink-backend.onrender.com

---

# INSTRUCTIONS:

# 1. Generate JWT Secret (run locally):
#    macOS/Linux:
#    openssl rand -hex 32
#
#    Windows PowerShell:
#    [Convert]::ToBase64String( [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32)) )

# 2. For Database/Redis:
#    - Create instances on Render first
#    - Copy connection details from their dashboards
#    - Replace "your-xxxxx" placeholders

# 3. For URLs:
#    - Backend URL: shown in green on Render service page
#    - Frontend URL: same format as backend
#    - Use HTTPS (Render auto-provides)

# 4. When setting in Render:
#    - Web Service → Environment
#    - Add each variable
#    - Backend service needs all DB/Redis/JWT vars
#    - Frontend service only needs API URL vars

# 5. Template breakdown:
#    - your-postgres-instance-name → From PostgreSQL dashboard
#    - your-postgres-password → Created when you made PostgreSQL
#    - your-redis-password → Created when you made Redis instance
#    - your-redis-instance → From Redis dashboard
#    - your-generated-jwt-secret-here → Run command above
#    - vibelink-backend.onrender.com → From backend service page
#    - vibelink.onrender.com → From frontend service page
