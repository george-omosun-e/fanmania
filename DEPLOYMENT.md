# 🚀 Fanmania Deployment Guide

Complete guide for deploying Fanmania to production with cost optimization.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Infrastructure Choices](#infrastructure-choices)
- [Pre-Deployment Checklist](#pre-deployment-checklist)
- [Option 1: Fly.io (Recommended)](#option-1-flyio-recommended)
- [Option 2: Railway](#option-2-railway)
- [Option 3: Render](#option-3-render)
- [Database Setup (Neon)](#database-setup-neon)
- [Redis Setup (Upstash)](#redis-setup-upstash)
- [Mobile App Deployment](#mobile-app-deployment)
- [CI/CD Setup](#cicd-setup)
- [Monitoring & Alerts](#monitoring--alerts)
- [Cost Breakdown](#cost-breakdown)

---

## 🎯 Overview

Fanmania's architecture is optimized for cost-effective scaling:

**MVP Phase (0-1K users):** $0-20/month  
**Growth Phase (1K-10K users):** $50-150/month  
**Scale Phase (10K-100K users):** $300-800/month

---

## 🏗️ Infrastructure Choices

### Recommended Stack

| Service | Provider | Why | Free Tier |
|---------|----------|-----|-----------|
| **Backend** | Fly.io | Go optimized, 256MB is enough | 3 VMs (256MB each) |
| **Database** | Neon | Serverless PostgreSQL, auto-scaling | 0.5GB storage |
| **Cache** | Upstash | Redis with pay-per-request | 10K commands/day |
| **Storage** | Cloudflare R2 | Cheapest object storage | 10GB free |
| **CDN** | Cloudflare | Free, fast, global | Unlimited |
| **Push** | Firebase FCM | Industry standard | 1M messages/month |

### Alternative Options

| Service | Alternative | Trade-off |
|---------|-------------|-----------|
| Backend | Railway | Easier but more expensive |
| Backend | Render | Good UI but slower cold starts |
| Database | Supabase | More features but pricier |
| Database | Railway | Integrated but expensive at scale |
| Cache | Redis Cloud | More features but complex pricing |

---

## ✅ Pre-Deployment Checklist

### 1. Environment Variables

Ensure all required variables are set:

```bash
# Generate secure secrets
openssl rand -base64 64  # For JWT_SECRET

# Get API keys
- Anthropic API Key: https://console.anthropic.com
- OpenAI API Key: https://platform.openai.com
- Firebase credentials: https://console.firebase.google.com
```

### 2. Code Readiness

```bash
# Run all tests
cd backend
go test ./...

cd ../mobile
flutter test

# Check for security issues
go vet ./...
golangci-lint run

# Build test
go build -o /tmp/test ./cmd/api
```

### 3. Database Migrations

```bash
# Test migrations on a local copy
docker-compose exec postgres psql -U fanmania -d fanmania_dev -f /migrations/001_init.sql

# Verify schema
docker-compose exec postgres psql -U fanmania -d fanmania_dev -c "\dt"
```

### 4. Legal Compliance

- [ ] No celebrity images in codebase
- [ ] Challenges reviewed for legal compliance
- [ ] Terms of Service finalized
- [ ] Privacy Policy complete
- [ ] DMCA process documented

---

## 🚁 Option 1: Fly.io (Recommended)

**Best for:** Cost optimization, Go applications, global distribution

### Step 1: Install Fly CLI

```bash
# macOS
brew install flyctl

# Linux
curl -L https://fly.io/install.sh | sh

# Windows
iwr https://fly.io/install.ps1 -useb | iex
```

### Step 2: Login & Create App

```bash
# Login
flyctl auth login

# Navigate to backend directory
cd backend

# Create new app (interactive)
flyctl launch
# - Choose app name: fanmania-api
# - Choose region: closest to your users
# - Don't deploy yet (we need to set secrets first)
```

### Step 3: Configure fly.toml

Edit the generated `fly.toml`:

```toml
app = "fanmania-api"
primary_region = "iad"  # Change to your region

[build]
  builder = "paketobuildpacks/builder:base"

[env]
  APP_ENV = "production"
  APP_PORT = "8080"
  LOG_LEVEL = "info"

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = true
  auto_start_machines = true
  min_machines_running = 1

  [[http_service.checks]]
    grace_period = "10s"
    interval = "30s"
    method = "GET"
    timeout = "5s"
    path = "/health"

[[vm]]
  cpu_kind = "shared"
  cpus = 1
  memory_mb = 256  # Start small, scale up if needed

# Auto-scaling
[metrics]
  port = 9091
  path = "/metrics"
```

### Step 4: Set Secrets

```bash
# Set all secrets at once
flyctl secrets set \
  JWT_SECRET="your-jwt-secret-here" \
  DATABASE_URL="postgresql://user:pass@host:port/db?sslmode=require" \
  REDIS_URL="redis://default:pass@host:port" \
  ANTHROPIC_API_KEY="your-key" \
  OPENAI_API_KEY="your-key"

# Verify secrets (won't show values)
flyctl secrets list
```

### Step 5: Deploy

```bash
# Deploy to production
flyctl deploy

# Watch deployment
flyctl logs

# Check status
flyctl status

# Open in browser
flyctl open
```

### Step 6: Configure Scaling

```bash
# Set scaling limits
flyctl scale count 1 --max-per-region 3

# Set VM size (if 256MB isn't enough)
flyctl scale vm shared-cpu-512mb  # or shared-cpu-1x
```

### Fly.io URLs

```
Production API: https://fanmania-api.fly.dev
Health check:   https://fanmania-api.fly.dev/health
Metrics:        https://fanmania-api.fly.dev/metrics
```

---

## 🚂 Option 2: Railway

**Best for:** Ease of use, integrated database, quick deploys

### Step 1: Install Railway CLI

```bash
npm install -g @railway/cli

# Or use the web interface at railway.app
```

### Step 2: Login & Initialize

```bash
# Login
railway login

# Create new project
railway init

# Link to GitHub repo (optional but recommended)
railway link
```

### Step 3: Add Services

Via Railway Dashboard:
1. Click "New Project"
2. Select "Deploy from GitHub repo"
3. Connect your repository
4. Railway will auto-detect Go and create a service

### Step 4: Add Database & Redis

```bash
# Add PostgreSQL
railway add --plugin postgresql

# Add Redis
railway add --plugin redis

# Railway will automatically inject DATABASE_URL and REDIS_URL
```

### Step 5: Set Environment Variables

```bash
# Set via CLI
railway variables set JWT_SECRET="your-secret"
railway variables set ANTHROPIC_API_KEY="your-key"
railway variables set OPENAI_API_KEY="your-key"

# Or set in Railway dashboard under Variables
```

### Step 6: Deploy

```bash
# Deploy
railway up

# Or push to GitHub and Railway auto-deploys

# View logs
railway logs

# Open in browser
railway open
```

### Railway Costs

- Free tier: $5 credit/month
- Paid: ~$20-30/month for small app
- Database included in plan

---

## 🎨 Option 3: Render

**Best for:** Simple setup, good documentation

### Quick Deploy

1. Go to https://render.com
2. Click "New +" → "Web Service"
3. Connect GitHub repository
4. Configure:
   - **Name:** fanmania-api
   - **Environment:** Go
   - **Build Command:** `go build -o bin/api ./cmd/api`
   - **Start Command:** `./bin/api`
   - **Plan:** Free (or $7/month for better)

### Add Database

1. Click "New +" → "PostgreSQL"
2. Copy Internal Database URL
3. Add to environment variables

### Environment Variables

Set in Render dashboard:
```
JWT_SECRET=...
DATABASE_URL=...
REDIS_URL=...
ANTHROPIC_API_KEY=...
OPENAI_API_KEY=...
```

---

## 🗄️ Database Setup (Neon)

**Best serverless PostgreSQL for Fanmania**

### Step 1: Create Account

1. Go to https://neon.tech
2. Sign up (free tier available)
3. Create a new project: "fanmania-prod"

### Step 2: Get Connection String

```
postgresql://user:password@ep-cool-name.us-east-2.aws.neon.tech/neondb?sslmode=require
```

### Step 3: Run Migrations

```bash
# Using psql
psql "postgresql://user:pass@host/db?sslmode=require" -f database_migration_001_init.sql

# Or using Go migrate tool
migrate -database "postgresql://user:pass@host/db?sslmode=require" \
        -path migrations up
```

### Step 4: Configure Backups

- Neon auto-backups (point-in-time recovery)
- Set retention: 7 days (free tier)
- For production: Upgrade to 30-day retention

### Neon Pricing

- Free: 0.5GB storage, 3 projects
- Scale: $19/month for 10GB
- Pro: $69/month for 50GB

---

## 🔴 Redis Setup (Upstash)

**Best serverless Redis for Fanmania**

### Step 1: Create Database

1. Go to https://upstash.com
2. Create account
3. Create new Redis database
   - **Name:** fanmania-cache
   - **Region:** Same as your backend
   - **Type:** Pay as you go

### Step 2: Get Connection String

```
redis://default:password@host:port
```

### Step 3: Configure Client

Already configured in backend if you use `REDIS_URL` env variable.

### Upstash Pricing

- Free: 10K commands/day
- Paid: $0.2 per 100K commands
- Typical cost for 10K users: $5-10/month

---

## 📱 Mobile App Deployment

### iOS Deployment (App Store)

#### Prerequisites

- Apple Developer Account ($99/year)
- Mac with Xcode
- Valid certificates and provisioning profiles

#### Build for iOS

```bash
cd mobile

# Clean
flutter clean
flutter pub get

# Build iOS release
flutter build ios --release

# Or build IPA
flutter build ipa
```

#### Upload to App Store

1. Open Xcode: `open ios/Runner.xcworkspace`
2. Select "Any iOS Device"
3. Product → Archive
4. Distribute App → App Store Connect
5. Upload

### Android Deployment (Play Store)

#### Prerequisites

- Google Play Developer Account ($25 one-time)
- Signing key

#### Generate Signing Key

```bash
keytool -genkey -v -keystore ~/fanmania-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias fanmania
```

#### Configure Signing

Create `android/key.properties`:

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=fanmania
storeFile=/path/to/fanmania-key.jks
```

#### Build Android Release

```bash
cd mobile

# Build APK
flutter build apk --release

# Or build App Bundle (recommended)
flutter build appbundle --release
```

#### Upload to Play Store

1. Go to https://play.google.com/console
2. Create new app
3. Upload app bundle
4. Fill in store listing
5. Submit for review

---

## 🔄 CI/CD Setup

### GitHub Actions Workflow

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.21'
      
      - name: Run tests
        run: |
          cd backend
          go test ./...
      
      - name: Build
        run: |
          cd backend
          go build -o bin/api ./cmd/api

  deploy:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to Fly.io
        uses: superfly/flyctl-actions/setup-flyctl@master
      
      - run: flyctl deploy --remote-only
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
```

### Secrets to Add

In GitHub Settings → Secrets:
- `FLY_API_TOKEN` (get from `flyctl auth token`)

---

## 📊 Monitoring & Alerts

### Health Checks

```bash
# Add to your Go backend
func healthHandler(c *fiber.Ctx) error {
    return c.JSON(fiber.Map{
        "status": "healthy",
        "version": "1.0.0",
        "timestamp": time.Now(),
    })
}
```

### Uptime Monitoring

**Free Options:**
- UptimeRobot (free for 50 monitors)
- Better Uptime (free tier available)

**Setup:**
1. Add monitor for: `https://your-api.fly.dev/health`
2. Check interval: 5 minutes
3. Alert on 2 consecutive failures
4. Alert via: Email, Slack, Discord

### Error Tracking (Sentry)

```bash
# Add to .env
SENTRY_DSN=https://...@sentry.io/...

# Install in Go
go get github.com/getsentry/sentry-go
```

---

## 💰 Cost Breakdown

### MVP Phase (0-1K users)

| Service | Plan | Cost |
|---------|------|------|
| Fly.io (Backend) | Free tier | $0 |
| Neon (Database) | Free tier | $0 |
| Upstash (Redis) | Free tier | $0 |
| Cloudflare R2 | Free tier | $0 |
| Firebase FCM | Free tier | $0 |
| **Total** | | **$0-5/month** |

### Growth Phase (1K-10K users)

| Service | Plan | Cost |
|---------|------|------|
| Fly.io | 2x 512MB VMs | $10/month |
| Neon | Scale plan | $19/month |
| Upstash | Pay-as-you-go | $10/month |
| Cloudflare R2 | 50GB storage | $1/month |
| Firebase FCM | Free | $0 |
| AI APIs | ~60K calls/month | $60-100/month |
| **Total** | | **$100-140/month** |

### Scale Phase (10K-100K users)

| Service | Plan | Cost |
|---------|------|------|
| Fly.io | 5x 1GB VMs | $100/month |
| Neon | Pro plan | $69/month |
| Upstash | Higher tier | $50/month |
| Cloudflare R2 | 200GB | $5/month |
| Firebase FCM | 2M messages | $20/month |
| AI APIs | ~200K calls/month | $200-300/month |
| **Total** | | **$444-544/month** |

---

## 🔐 Security Checklist

Before going live:

- [ ] All secrets in environment variables, not code
- [ ] JWT_SECRET is cryptographically random (64+ chars)
- [ ] Database uses SSL (sslmode=require)
- [ ] CORS is properly configured
- [ ] Rate limiting is enabled
- [ ] HTTPS is enforced
- [ ] API keys are rotated regularly
- [ ] Logs don't contain sensitive data
- [ ] Error messages don't expose internals

---

## 📞 Support & Troubleshooting

### Common Issues

**Deployment fails:**
```bash
# Check logs
flyctl logs
railway logs
```

**Database connection fails:**
- Verify `DATABASE_URL` is correct
- Check SSL mode is `require`
- Ensure IP is whitelisted (if applicable)

**High latency:**
- Check region selection (backend should be near database)
- Enable Redis caching
- Add read replicas if needed

---

## 🎉 Launch Checklist

Final steps before going live:

- [ ] All tests passing
- [ ] Production environment variables set
- [ ] Database migrated
- [ ] Health checks working
- [ ] Monitoring configured
- [ ] Error tracking enabled
- [ ] Backups configured
- [ ] SSL certificates valid
- [ ] Domain name configured (if custom)
- [ ] Mobile apps submitted to stores
- [ ] Terms of Service live
- [ ] Privacy Policy live
- [ ] Support email configured

---

**Ready to deploy? 🚀**

Start with the MVP stack (free tier) and scale up as you grow!
