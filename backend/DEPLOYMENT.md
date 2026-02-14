# VibeLink Backend Deployment Guide

Complete guide for deploying the VibeLink backend to production.

## 📋 Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Local Docker Setup](#local-docker-setup)
3. [Production Deployment Options](#production-deployment-options)
4. [Environment Configuration](#environment-configuration)
5. [Database Setup](#database-setup)
6. [Monitoring & Logging](#monitoring--logging)
7. [Scaling](#scaling)
8. [Troubleshooting](#troubleshooting)

---

## ✅ Pre-Deployment Checklist

- [ ] All tests passing: `npm test`
- [ ] No TypeScript errors: `npm run build`
- [ ] Environment variables configured
- [ ] Database backups configured
- [ ] SSL/TLS certificates obtained
- [ ] Monitoring and logging setup
- [ ] Rate limiting configured
- [ ] CORS origins configured
- [ ] JWT secrets changed from defaults
- [ ] Code reviewed

---

## 🐳 Local Docker Setup

### Prerequisites

- Docker installed
- Docker Compose installed

### Quick Start

```bash
# Start all services (PostgreSQL, Redis, Backend)
docker-compose up -d

# View logs
docker-compose logs -f backend

# Stop services
docker-compose down

# Reset data
docker-compose down -v
```

### Verify Services

```bash
# Check backend health
curl http://localhost:5000/health

# Connect to database
psql postgresql://vibelink:vibelink_password@localhost:5432/vibelink_db

# Check Redis
redis-cli -h localhost ping
```

---

## 🚀 Production Deployment Options

### Option 1: Railway (Recommended for Webhook)

**Easiest setup with automatic deployments**

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Initialize project
railway init

# Set environment variables
railway variables set NODE_ENV=production
railway variables set JWT_SECRET=your_secret_here
railway variables set DATABASE_URL=postgresql://...

# Deploy
railway up
```

**Features:**
- Automatic deployments from Git
- Built-in PostgreSQL addon
- Environment isolation
- Zero-downtime deployments
- Custom domains

### Option 2: Vercel (For REST API only)

Note: Vercel doesn't support WebSocket well. Better for REST API.

```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
vercel

# Set secrets
vercel env add JWT_SECRET
vercel env add DATABASE_URL

# Link database
vercel postgres create --project-id=...
```

### Option 3: Heroku

```bash
# Install Heroku CLI
curl https://cli-assets.heroku.com/install.sh | sh

# Login
heroku login

# Create app
heroku create vibelink-backend

# Add PostgreSQL
heroku addons:create heroku-postgresql:standard-0 -a vibelink-backend

# Set environment variables
heroku config:set NODE_ENV=production -a vibelink-backend
heroku config:set JWT_SECRET=your_secret_here -a vibelink-backend

# Deploy
git push heroku main

# View logs
heroku logs --tail -a vibelink-backend
```

### Option 4: AWS (EC2 + RDS)

**For maximum control**

1. **Create EC2 Instance**
```bash
# Security group: Allow 5000, 4000, 22
# IAM role: CloudWatch, S3 access
```

2. **Connect and Setup**
```bash
ssh -i key.pem ec2-user@instance-ip

# Update system
sudo yum update -y
sudo yum install -y nodejs npm git postgresql

# Clone repository
git clone <repo-url>
cd backend

# Install dependencies
npm install

# Setup PM2 for process management
npm install -g pm2
pm2 start "npm start" --name "vibelink"
pm2 startup
pm2 save
```

3. **Create RDS PostgreSQL**
- Engine: PostgreSQL 14+
- Instance class: db.t3.micro (for testing)
- Storage: 20GB (auto-scaling enabled)
- Backup retention: 7 days
- Multi-AZ: Yes

4. **Configure Security**
- Add EC2 security group to RDS
- Enable encryption at rest
- Enable enhanced monitoring

5. **Setup Environment**
```bash
# Copy .env template
cp .env.example .env

# Edit with AWS RDS credentials
nano .env
```

6. **Run Database Migrations**
```bash
npm run migrate
```

7. **Start Application**
```bash
pm2 restart vibelink
```

### Option 5: Docker on Kubernetes

**For enterprise deployments**

1. **Build and Push Image**
```bash
docker build -t vibelink-backend:1.0.0 .
docker tag vibelink-backend:1.0.0 registry.example.com/vibelink-backend:1.0.0
docker push registry.example.com/vibelink-backend:1.0.0
```

2. **Create Kubernetes Manifests**

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vibelink-backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: vibelink-backend
  template:
    metadata:
      labels:
        app: vibelink-backend
    spec:
      containers:
      - name: backend
        image: registry.example.com/vibelink-backend:1.0.0
        ports:
        - containerPort: 5000
          name: rest
        - containerPort: 4000
          name: websocket
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: vibelink-secrets
              key: database-url
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: vibelink-secrets
              key: jwt-secret
        livenessProbe:
          httpGet:
            path: /health
            port: 5000
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 5000
          initialDelaySeconds: 5
          periodSeconds: 5
```

3. **Deploy**
```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

---

## ⚙️ Environment Configuration

### Production Environment Variables

```env
# Server
NODE_ENV=production
PORT=5000
HOST=0.0.0.0

# Database (use RDS or managed service)
DATABASE_URL=postgresql://user:pwd@prod.rds.amazonaws.com:5432/vibelink

# Security (Generate with: openssl rand -hex 32)
JWT_SECRET=your_very_long_random_secret_here
REFRESH_TOKEN_SECRET=your_refresh_token_secret_here

# WebSocket
SOCKET_PORT=4000
SOCKET_URL=https://api.vibelink.com:4000

# CORS (restrict to your domain)
CORS_ORIGIN=https://vibelink.com,https://www.vibelink.com

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Logging
LOG_LEVEL=info

# Optional: Monitoring
SENTRY_DSN=https://...
```

---

## 🗄️ Database Setup

### PostgreSQL Configuration

```bash
# Connect to production database
psql $DATABASE_URL

# Create extension for UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

# Run migrations
npm run migrate

# Verify schema
\dt
```

### Backup Strategy

```bash
# Automated daily backups
0 2 * * * pg_dump $DATABASE_URL | gzip > /backups/vibelink-$(date +\%Y-\%m-\%d).sql.gz

# Monthly S3 backup
0 3 1 * * aws s3 cp /backups/ s3://vibelink-backups/ --recursive
```

### Connection Pooling

For production, use PgBouncer:

```ini
[databases]
vibelink = host=localhost port=5432 user=vibelink

[pgbouncer]
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 25
reserve_pool_size = 5
reserve_pool_timeout = 3
```

---

## 📊 Monitoring & Logging

### Application Monitoring

```javascript
// Add to index.ts
import * as Sentry from "@sentry/node";

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: 1.0,
});

app.use(Sentry.Handlers.requestHandler());
app.use(Sentry.Handlers.errorHandler());
```

### Log Aggregation

**CloudWatch (AWS)**
```bash
# Install agent
curl https://s3.amazonaws.com/amazoncloudwatch-agent/linux/amd64/latest/amazon-cloudwatch-agent.zip -O
unzip amazon-cloudwatch-agent.zip
sudo ./install.sh
```

**ELK Stack (Self-hosted)**
```yaml
version: '3'
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.0.0
    environment:
      discovery.type: single-node
    
  kibana:
    image: docker.elastic.co/kibana/kibana:8.0.0
    ports:
      - "5601:5601"
```

### Metrics

```javascript
// Track key metrics
app.get('/metrics', (req, res) => {
  const metrics = {
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    cpu: process.cpuUsage(),
  };
  res.json(metrics);
});
```

---

## 📈 Scaling

### Horizontal Scaling

```bash
# Add more instances behind load balancer
# Use AWS ALB or nginx

upstream backend {
  server backend1:5000;
  server backend2:5000;
  server backend3:5000;
}

server {
  listen 80;
  location / {
    proxy_pass http://backend;
  }
}
```

### Caching Layer

```javascript
// Add Redis caching
import redis from 'redis';
const client = redis.createClient({ 
  url: process.env.REDIS_URL 
});

app.get('/api/users/:id', async (req, res) => {
  // Check cache first
  const cached = await client.get(`user:${req.params.id}`);
  if (cached) return res.json(JSON.parse(cached));
  
  // Fetch from DB
  const user = await UserRepository.findById(req.params.id);
  
  // Cache for 1 hour
  await client.setEx(`user:${req.params.id}`, 3600, JSON.stringify(user));
  
  res.json(user);
});
```

### Database Optimization

```sql
-- Add indexes for frequently queried columns
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);
CREATE INDEX CONCURRENTLY idx_sessions_created ON game_sessions(created_at DESC);

-- Monitor slow queries
log_min_duration_statement = 1000  -- Log queries > 1s
log_min_query_duration = 0

-- Vacuum and analyze
VACUUM ANALYZE;
```

---

## 🐛 Troubleshooting

### Connection Issues

```bash
# Check if backend is responding
curl https://api.vibelink.com/health

# Check port binding
lsof -i :5000

# Check firewall
sudo ufw status
sudo ufw allow 5000/tcp
```

### Database Issues

```bash
# Check connections
SELECT * FROM pg_stat_activity;

# Kill idle connections
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE state = 'idle' AND duration > interval '1 hour';

# Check tablespace
SELECT pg_size_pretty(pg_database_size('vibelink_db'));
```

### Memory Leaks

```javascript
// Enable heap snapshots on memory pressure
if (process.memoryUsage().heapUsed > 1000 * 1000 * 1000) {
  console.error('Memory usage high, restarting...');
  process.exit(1); // Let PM2 restart
}
```

### Performance Issues

```bash
# Profile with --prof
node --prof dist/index.js

# Analyze profile
node --prof-process isolate-*.log > profile.txt
```

---

## 🔒 Security Considerations

- [ ] Enable HTTPS/TLS (Let's Encrypt)
- [ ] Keep dependencies updated: `npm audit fix`
- [ ] Use strong JW secrets (32+ characters)
- [ ] Enable rate limiting for auth endpoints
- [ ] Implement DDoS protection (Cloudflare)
- [ ] Use secrets manager for credentials
- [ ] Enable database encryption at rest
- [ ] Regular security audits
- [ ] WAF rules for common attacks

---

## 📞 Support & Maintenance

- Set up uptime monitoring (UptimeRobot, Datadog)
- Configure alerting for errors and performance
- Establish on-call rotation for production issues
- Regular backup testing and recovery drills
- Quarterly security assessments

---

## 🎉 Deployment Checklist (Final)

Before going live:

- [ ] All tests pass
- [ ] Performance benchmarks acceptable
- [ ] Monitoring and alerting active
- [ ] Backups verified
- [ ] Disaster recovery plan documented
- [ ] Team trained on deployment process
- [ ] Rollback procedure ready

