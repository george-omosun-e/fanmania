# 🎮 Fanmania - AI-Powered Fan Skill Engine

**Status:** Architecture & Design Phase  
**Tech Stack:** Flutter (Mobile) + Go (Backend) + PostgreSQL + Redis

---

## 📖 Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Development](#development)
- [Deployment](#deployment)
- [API Documentation](#api-documentation)
- [Contributing](#contributing)
- [Legal & Compliance](#legal--compliance)

---

## 🎯 Overview

Fanmania is a competitive, skill-based fan platform where users prove their mastery through AI-generated challenges. Unlike traditional fan apps, Fanmania:

- ✅ Rewards **skill, not proximity** to celebrities
- ✅ Uses AI for autonomous content generation
- ✅ Maintains legal safety (no celebrity likeness)
- ✅ Provides competitive leaderboards and rankings
- ✅ Scales from MVP to millions with minimal cost

### The Problem We Solve

Fandom today is passive, fragmented, and under-gamified. Fans lack:
- Structured ways to prove knowledge
- Competitive, skill-based status
- Fair recognition systems

### Our Solution

A self-running, AI-powered platform that makes fandom competitive, challenging, and rewarding.

---

## ⚡ Key Features

### MVP Features (Phase 1)
- **User Authentication** - Secure JWT-based auth
- **Category System** - Abstract genre/movement categories
- **AI-Generated Challenges** - Dynamic, difficulty-tiered questions
- **ELO-Style Ranking** - Competitive leaderboard system
- **Push Notifications** - Quest-based engagement (no celebrity names)
- **Streak System** - Daily engagement rewards
- **Profile & Stats** - Personal achievement tracking

### Future Features (Phase 2+)
- Creator opt-in zones
- Achievement badges
- Social features (limited)
- Multi-language support
- Advanced analytics

---

## 🏗️ Architecture

```
┌──────────────────┐
│  Flutter Mobile  │
│   (iOS/Android)  │
└────────┬─────────┘
         │ REST API / WebSocket
         ▼
┌──────────────────┐
│   Go Backend     │
│   (Fiber)        │
└────────┬─────────┘
         │
    ┌────┴────┬──────────┐
    ▼         ▼          ▼
┌────────┐ ┌──────┐ ┌─────────┐
│ Postgres│ │Redis │ │ AI APIs │
└────────┘ └──────┘ └─────────┘
```

### Why This Stack?

| Component | Choice | Reason |
|-----------|--------|--------|
| **Mobile** | Flutter | 60fps performance, single codebase, 30% faster dev |
| **Backend** | Go | 10-20x lower memory, perfect for free tiers |
| **Database** | PostgreSQL | ACID compliance, excellent for rankings |
| **Cache** | Redis | Leaderboard performance, challenge caching |
| **AI** | Claude/OpenAI | Cost-effective content generation |

---

## 🛠️ Tech Stack

### Frontend (Mobile)
- **Flutter 3.16+**
- **Dart 3.2+**
- State Management: `flutter_bloc` (BLoC pattern)
- HTTP: `dio`
- Local Storage: `hive`
- Animations: `flutter_animate`

### Backend
- **Go 1.21+**
- Web Framework: `fiber` (Express.js-like, 3x faster than gin)
- Database: `pgx/v5` (PostgreSQL driver)
- Cache: `go-redis/v9`
- Auth: `golang-jwt/jwt/v5`
- Validation: `go-playground/validator/v10`

### Infrastructure
- **Database:** Neon / Supabase (PostgreSQL)
- **Cache:** Upstash (Redis)
- **Hosting:** Fly.io / Railway
- **Push:** Firebase Cloud Messaging (FCM)
- **CDN:** Cloudflare

### AI Services
- **Anthropic Claude Sonnet** - Complex challenges (Tier 4-5)
- **OpenAI GPT-4o-mini** - Simple challenges (Tier 1-3) + Moderation

---

## 📁 Project Structure

```
fanmania/
├── backend/                    # Go backend API
│   ├── cmd/
│   │   └── api/
│   │       └── main.go        # Entry point
│   ├── internal/
│   │   ├── config/            # Configuration
│   │   ├── domain/            # Domain models
│   │   ├── repository/        # Data access layer
│   │   ├── service/           # Business logic
│   │   ├── handler/           # HTTP handlers
│   │   └── middleware/        # Middleware
│   ├── pkg/                   # Shared packages
│   ├── migrations/            # Database migrations
│   ├── go.mod
│   └── Dockerfile
│
├── mobile/                    # Flutter mobile app
│   ├── lib/
│   │   ├── core/              # Core utilities
│   │   ├── data/              # Models & repositories
│   │   ├── features/          # Feature modules
│   │   └── widgets/           # Reusable widgets
│   ├── test/                  # Unit & widget tests
│   ├── pubspec.yaml
│   └── README.md
│
├── docs/                      # Documentation
│   ├── ARCHITECTURE.md        # Full technical architecture
│   ├── API.md                 # API documentation
│   ├── DESIGN_GUIDE.md        # Design system
│   └── DEPLOYMENT.md          # Deployment guides
│
├── scripts/                   # Utility scripts
│   ├── seed_data.sql          # Sample data
│   └── generate_jwt_secret.sh # Secret generation
│
├── .github/
│   └── workflows/
│       └── deploy.yml         # CI/CD pipeline
│
├── docker-compose.yml         # Local development setup
├── .env.example               # Environment template
└── README.md                  # This file
```

---

## 🚀 Getting Started

### Prerequisites

- **Go 1.21+** ([Download](https://golang.org/dl/))
- **Flutter 3.16+** ([Install](https://flutter.dev/docs/get-started/install))
- **Docker & Docker Compose** ([Install](https://docs.docker.com/get-docker/))
- **Git**

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/fanmania.git
cd fanmania
```

### 2. Set Up Environment Variables

```bash
# Copy the example environment file
cp .env.example .env

# Edit .env with your configuration
nano .env  # or use your preferred editor
```

**Critical values to set:**
- `JWT_SECRET` - Generate with: `openssl rand -base64 64`
- `ANTHROPIC_API_KEY` - Get from https://console.anthropic.com
- `OPENAI_API_KEY` - Get from https://platform.openai.com

### 3. Start Local Development Environment

```bash
# Start all services (PostgreSQL, Redis, Backend)
docker-compose up -d

# View logs
docker-compose logs -f backend

# Check service health
docker-compose ps
```

**Services will be available at:**
- Backend API: http://localhost:8080
- PostgreSQL: localhost:5432
- Redis: localhost:6379
- pgAdmin: http://localhost:5050 (admin@fanmania.local / admin)
- Redis Commander: http://localhost:8081

### 4. Initialize Database

The database schema will auto-initialize on first run via `docker-entrypoint-initdb.d`.

To run migrations manually:
```bash
docker-compose exec postgres psql -U fanmania -d fanmania_dev -f /docker-entrypoint-initdb.d/001_init.sql
```

### 5. Set Up Flutter Mobile App

```bash
cd mobile

# Install dependencies
flutter pub get

# Run on iOS simulator (macOS only)
flutter run -d ios

# Run on Android emulator
flutter run -d android

# Or run on physical device
flutter run
```

---

## 💻 Development

### Backend Development

#### Running Locally (Without Docker)

```bash
cd backend

# Install dependencies
go mod download

# Install Air for hot reload
go install github.com/cosmtrek/air@latest

# Run with hot reload
air

# Or run directly
go run cmd/api/main.go
```

#### Running Tests

```bash
# Run all tests
go test ./...

# Run with coverage
go test -cover ./...

# Run specific package tests
go test ./internal/service/...

# Run with verbose output
go test -v ./...
```

#### Code Formatting & Linting

```bash
# Format code
go fmt ./...

# Run linter (install golangci-lint first)
golangci-lint run
```

### Mobile Development

#### Running Flutter App

```bash
cd mobile

# Run in debug mode
flutter run

# Run in profile mode (better performance testing)
flutter run --profile

# Run in release mode
flutter run --release
```

#### Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/features/auth/auth_test.dart
```

#### Code Generation (if using freezed/json_serializable)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Database Management

#### Access PostgreSQL CLI

```bash
docker-compose exec postgres psql -U fanmania -d fanmania_dev
```

#### Common SQL Queries

```sql
-- View all users
SELECT id, username, total_points, global_rank FROM users;

-- View challenges by category
SELECT c.name, COUNT(ch.id) 
FROM categories c 
LEFT JOIN challenges ch ON c.id = ch.category_id 
GROUP BY c.name;

-- Top 10 users
SELECT username, total_points, global_rank 
FROM users 
WHERE is_active = true 
ORDER BY global_rank ASC 
LIMIT 10;
```

#### Access Redis CLI

```bash
docker-compose exec redis redis-cli

# Common commands
> KEYS *                        # List all keys
> GET leaderboard:global        # Get specific key
> ZRANGE leaderboard:global 0 9 WITHSCORES  # Top 10 leaderboard
```

---

## 🌐 API Documentation

### Base URL

- **Local:** `http://localhost:8080/v1`
- **Production:** `https://api.fanmania.app/v1`

### Authentication

All protected endpoints require a JWT Bearer token:

```
Authorization: Bearer <your_access_token>
```

### Key Endpoints

#### Authentication
```
POST   /auth/register      # Register new user
POST   /auth/login         # Login
POST   /auth/refresh       # Refresh access token
```

#### Users
```
GET    /users/me           # Get current user profile
GET    /users/me/stats     # Get user statistics
PATCH  /users/me           # Update profile
```

#### Categories
```
GET    /categories         # List all categories
GET    /categories/:id     # Get category details
```

#### Challenges
```
GET    /challenges         # Get available challenges
POST   /challenges/:id/attempt  # Submit challenge attempt
```

#### Leaderboards
```
GET    /leaderboards/global              # Global leaderboard
GET    /leaderboards/category/:id        # Category leaderboard
```

#### Notifications
```
GET    /notifications                    # Get user notifications
POST   /notifications/:id/read           # Mark as read
POST   /notifications/register-device    # Register FCM token
```

For detailed API specs, see [api-specification.yaml](./api-specification.yaml)

---

## 🚢 Deployment

### Recommended Production Stack

| Service | Provider | Free Tier | Paid (Small) |
|---------|----------|-----------|--------------|
| Backend | Fly.io | 3 VMs (256MB) | $5/month (512MB) |
| Database | Neon | 0.5GB | $19/month |
| Cache | Upstash | 10K commands/day | $10/month |
| Storage | Cloudflare R2 | 10GB | $0.015/GB |
| Push | Firebase FCM | 1M messages/month | Free |

**Total Cost:** $0-10/month (MVP) → $50-100/month (Growth)

### Deploy to Fly.io

```bash
cd backend

# Install flyctl
curl -L https://fly.io/install.sh | sh

# Login
flyctl auth login

# Create app
flyctl launch

# Set environment variables
flyctl secrets set JWT_SECRET="your-secret"
flyctl secrets set DATABASE_URL="your-db-url"
flyctl secrets set REDIS_URL="your-redis-url"

# Deploy
flyctl deploy
```

### Deploy to Railway

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Initialize project
railway init

# Link to existing project or create new
railway link

# Deploy
railway up
```

### CI/CD with GitHub Actions

See `.github/workflows/deploy.yml` for automated deployment pipeline.

---

## 📚 Additional Documentation

- **[FANMANIA_TECHNICAL_ARCHITECTURE.md](./FANMANIA_TECHNICAL_ARCHITECTURE.md)** - Complete technical architecture
- **[api-specification.yaml](./api-specification.yaml)** - OpenAPI specification
- **[Fanmania_Design_Guide_v1.md](./docs/Fanmania_Design_Guide_v1.md)** - Design system & branding
- **[Fanmania_idea_brief_hard_design_rules.md](./docs/Fanmania_idea_brief_hard_design_rules.md)** - Product vision & legal rules

---

## 🔒 Legal & Compliance

### Core Principles

1. **No Celebrity Likeness** - Never display images, logos, or official branding
2. **Skill-Based Competition** - Rank by performance, not proximity
3. **Nominative Fair Use** - Reference public figures only in factual context
4. **No Implied Endorsement** - All content is fan-generated, not official
5. **AI Content Safeguards** - Automated legal compliance checks

### Pre-Launch Checklist

- [ ] No celebrity images anywhere
- [ ] Challenges use nominative fair use only
- [ ] Notification titles are generic
- [ ] Leaderboards are category-based
- [ ] Terms of Service reviewed
- [ ] Privacy Policy includes AI disclosure
- [ ] DMCA process documented
- [ ] Age gate implemented (13+)

---

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Follow code style**
   - Go: `gofmt`, `golangci-lint`
   - Flutter: `dart format`, `flutter analyze`
4. **Write tests**
5. **Commit with meaningful messages**
6. **Push to your fork**
7. **Create a Pull Request**

### Code Review Criteria

- [ ] Code follows project style guidelines
- [ ] Tests pass (`go test ./...` and `flutter test`)
- [ ] No legal compliance violations
- [ ] Documentation updated if needed
- [ ] No sensitive data in commits

---

## 📊 Monitoring & Analytics

### Health Check Endpoints

```bash
# Backend health
curl http://localhost:8080/health

# Database connection
curl http://localhost:8080/health/db

# Redis connection
curl http://localhost:8080/health/redis
```

### Metrics (Prometheus)

If `METRICS_ENABLED=true`:
- Metrics endpoint: `http://localhost:9090/metrics`

---

## 🐛 Troubleshooting

### Common Issues

**Docker services won't start:**
```bash
# Check for port conflicts
lsof -i :5432  # PostgreSQL
lsof -i :6379  # Redis
lsof -i :8080  # Backend

# Clean and restart
docker-compose down -v
docker-compose up -d
```

**Database connection refused:**
```bash
# Check PostgreSQL is running
docker-compose ps postgres

# Check logs
docker-compose logs postgres

# Restart PostgreSQL
docker-compose restart postgres
```

**Flutter build fails:**
```bash
# Clean build artifacts
flutter clean
flutter pub get
flutter run
```

**Go dependencies issue:**
```bash
# Clean module cache
go clean -modcache
go mod download
```

---

## 📞 Support & Contact

- **Issues:** [GitHub Issues](https://github.com/yourusername/fanmania/issues)
- **Discussions:** [GitHub Discussions](https://github.com/yourusername/fanmania/discussions)
- **Email:** dev@fanmania.app

---

## 📝 License

This project is proprietary. All rights reserved.

---

## 🙏 Acknowledgments

- Design inspiration from competitive gaming platforms
- AI integration powered by Anthropic Claude and OpenAI
- Built with ❤️ for passionate fans worldwide

---

**Made with Flutter & Go | Optimized for Cost & Performance | Built for Scale**
