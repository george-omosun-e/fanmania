# 🏗️ Fanmania Technical Architecture
## AI-Powered Fan Skill Engine - Complete Technical Specification

**Version:** 1.0  
**Date:** January 2026  
**Status:** Architecture Design Phase

---

## 📋 Executive Summary

**Fanmania** is a mobile-first, AI-powered competitive fan platform built with:
- **Cost-First Architecture**: Optimized for minimal operational costs
- **AI-Native Design**: Autonomous content generation and moderation
- **Legal-Safe Framework**: No celebrity likeness, skill-based only
- **Scalable Infrastructure**: Can grow from MVP to millions of users

**Estimated Monthly Costs:**
- MVP Phase (0-1K users): **$0-20/month**
- Growth Phase (1K-10K users): **$50-150/month**
- Scale Phase (10K-100K users): **$300-800/month**

---

## 🎯 Technology Stack Decision Matrix

### Mobile: **Flutter** ✅
**Why Flutter over React Native:**
- 60fps performance for kinetic UI animations
- Better glassmorphism and complex shader support
- Single codebase (iOS + Android)
- Smaller app size (~15MB vs ~25MB)
- Lower memory footprint
- Superior gradient and neon glow rendering
- **Cost Impact:** 30% faster development = lower costs

### Backend: **Go (Golang)** ✅
**Why Go over Python:**
- 10-20x lower memory usage (critical for free tiers)
- Built-in concurrency for real-time features
- Single binary deployment (no dependency hell)
- Lightning-fast cold starts on serverless
- **Cost Impact:** Can run on 256MB RAM vs 1GB+ for Python
- **Trade-off:** AI integration via APIs (not native ML)

### Database: **PostgreSQL** ✅
**Why PostgreSQL:**
- Free tier available (Neon, Supabase)
- Excellent for leaderboards and rankings
- ACID compliance for competitive integrity
- Full-text search for challenge content
- JSON support for flexible schemas

### Caching: **Redis** ✅
**Why Redis:**
- Free tier available (Upstash)
- Essential for leaderboard performance
- Challenge caching reduces AI costs
- Session management

---

## 🏛️ System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         FLUTTER MOBILE APP                       │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────────┐   │
│  │  Home/Feed   │  │  Challenges  │  │  Leaderboards       │   │
│  └──────────────┘  └──────────────┘  └─────────────────────┘   │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────────┐   │
│  │  Profile     │  │  Categories  │  │  Notifications      │   │
│  └──────────────┘  └──────────────┘  └─────────────────────┘   │
└───────────────────────────┬─────────────────────────────────────┘
                            │ REST/WebSocket
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                      GO BACKEND API GATEWAY                      │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Auth Service  │  Challenge Engine  │  Ranking Service   │   │
│  └──────────────────────────────────────────────────────────┘   │
└───────────────┬───────────────────┬─────────────────────────────┘
                │                   │
    ┌───────────▼────────┐ ┌────────▼──────────┐
    │   PostgreSQL       │ │   Redis Cache     │
    │   (Neon/Supabase)  │ │   (Upstash)       │
    └───────────┬────────┘ └───────────────────┘
                │
    ┌───────────▼────────────────────────────────┐
    │      AI Services (External APIs)           │
    │  ┌──────────────┐  ┌──────────────────┐   │
    │  │ Claude API   │  │  OpenAI API      │   │
    │  │ (Challenges) │  │  (Moderation)    │   │
    │  └──────────────┘  └──────────────────┘   │
    └────────────────────────────────────────────┘
```

---

## 📱 Mobile App Architecture (Flutter)

### **Core Structure**

```
fanmania_app/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── config/
│   │   │   ├── app_config.dart
│   │   │   ├── theme_config.dart       # Design system colors
│   │   │   └── api_config.dart
│   │   ├── utils/
│   │   │   ├── validators.dart
│   │   │   ├── formatters.dart
│   │   │   └── constants.dart
│   │   └── network/
│   │       ├── api_client.dart
│   │       ├── websocket_client.dart
│   │       └── interceptors.dart
│   ├── data/
│   │   ├── models/
│   │   │   ├── user_model.dart
│   │   │   ├── challenge_model.dart
│   │   │   ├── category_model.dart
│   │   │   └── leaderboard_model.dart
│   │   ├── repositories/
│   │   │   ├── auth_repository.dart
│   │   │   ├── challenge_repository.dart
│   │   │   └── user_repository.dart
│   │   └── services/
│   │       ├── storage_service.dart    # Local storage
│   │       ├── notification_service.dart
│   │       └── analytics_service.dart
│   ├── features/
│   │   ├── auth/
│   │   │   ├── presentation/
│   │   │   │   ├── pages/
│   │   │   │   └── widgets/
│   │   │   └── bloc/
│   │   ├── home/
│   │   ├── challenges/
│   │   ├── leaderboard/
│   │   ├── profile/
│   │   └── categories/
│   └── widgets/
│       ├── glassmorphic_card.dart
│       ├── neon_button.dart
│       ├── kinetic_background.dart
│       └── progress_bar.dart
```

### **State Management: Bloc/Cubit**
- **Why:** Predictable state, great for complex flows
- **Pattern:** Feature-based architecture
- **Testing:** Easy to test business logic

### **Key Dependencies**
```yaml
dependencies:
  flutter_bloc: ^8.1.3          # State management
  dio: ^5.4.0                   # HTTP client
  web_socket_channel: ^2.4.0   # Real-time updates
  hive: ^2.2.3                  # Local storage
  firebase_messaging: ^14.7.9  # Push notifications
  cached_network_image: ^3.3.0 # Image caching
  flutter_animate: ^4.3.0       # Kinetic animations
  shimmer: ^3.0.0              # Loading states
  fl_chart: ^0.65.0            # Stat visualizations
```

---

## 🔧 Backend Architecture (Go)

### **Project Structure**

```
fanmania-backend/
├── cmd/
│   └── api/
│       └── main.go              # Entry point
├── internal/
│   ├── config/
│   │   └── config.go            # Environment config
│   ├── domain/
│   │   ├── models/
│   │   │   ├── user.go
│   │   │   ├── challenge.go
│   │   │   ├── category.go
│   │   │   └── ranking.go
│   │   └── errors/
│   │       └── errors.go
│   ├── repository/
│   │   ├── postgres/
│   │   │   ├── user_repo.go
│   │   │   ├── challenge_repo.go
│   │   │   └── ranking_repo.go
│   │   └── redis/
│   │       └── cache_repo.go
│   ├── service/
│   │   ├── auth_service.go
│   │   ├── challenge_service.go
│   │   ├── ranking_service.go
│   │   ├── ai_service.go         # AI integration
│   │   └── notification_service.go
│   ├── handler/
│   │   ├── auth_handler.go
│   │   ├── challenge_handler.go
│   │   ├── user_handler.go
│   │   └── leaderboard_handler.go
│   └── middleware/
│       ├── auth.go
│       ├── ratelimit.go
│       └── logging.go
├── pkg/
│   ├── jwt/
│   │   └── jwt.go
│   ├── validator/
│   │   └── validator.go
│   └── utils/
│       └── helpers.go
├── migrations/
│   └── 000001_init.up.sql
├── scripts/
│   └── seed_data.go
├── go.mod
└── go.sum
```

### **Core Go Packages**
```go
// go.mod
module github.com/fanmania/backend

go 1.21

require (
    github.com/gofiber/fiber/v2 v2.51.0      // Web framework (faster than gin)
    github.com/gofiber/websocket/v2 v2.2.1  // WebSocket support
    github.com/golang-jwt/jwt/v5 v5.2.0     // JWT auth
    github.com/jackc/pgx/v5 v5.5.1          // PostgreSQL driver
    github.com/redis/go-redis/v9 v9.4.0     // Redis client
    github.com/joho/godotenv v1.5.1         // Environment variables
    golang.org/x/crypto v0.18.0             // Password hashing
    github.com/go-playground/validator/v10 v10.16.0 // Validation
)
```

### **Why Fiber over Gin:**
- 3x faster routing
- Built-in WebSocket support
- Better memory efficiency
- Express.js-like API (easier for team expansion)

---

## 🗄️ Database Schema

### **PostgreSQL Schema**

```sql
-- Users Table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(30) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    display_name VARCHAR(50),
    avatar_url TEXT,
    total_points BIGINT DEFAULT 0,
    global_rank INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_active TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    CONSTRAINT username_length CHECK (char_length(username) >= 3)
);

-- Categories Table
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    icon_type VARCHAR(50),           -- 'cube', 'triangle', 'wave', etc.
    color_primary VARCHAR(7),         -- Hex color
    color_secondary VARCHAR(7),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Challenges Table
CREATE TABLE challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID REFERENCES categories(id),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    question_data JSONB NOT NULL,    -- Stores question + options
    correct_answer_hash VARCHAR(255), -- Hashed correct answer
    difficulty_tier INTEGER CHECK (difficulty_tier BETWEEN 1 AND 5),
    base_points INTEGER NOT NULL,
    time_limit_seconds INTEGER,
    challenge_type VARCHAR(50),       -- 'multiple_choice', 'timeline', 'prediction'
    ai_generated BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true,
    active_from TIMESTAMP,
    active_until TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    usage_count INTEGER DEFAULT 0
);

-- User Challenge Attempts Table
CREATE TABLE user_challenge_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    challenge_id UUID REFERENCES challenges(id) ON DELETE CASCADE,
    is_correct BOOLEAN NOT NULL,
    points_earned INTEGER NOT NULL,
    time_taken_seconds INTEGER,
    attempted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_user_challenge UNIQUE(user_id, challenge_id)
);

-- Category Rankings Table
CREATE TABLE category_rankings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
    points BIGINT DEFAULT 0,
    rank INTEGER,
    mastery_percentage DECIMAL(5,2),  -- 0.00 to 100.00
    streak_days INTEGER DEFAULT 0,
    last_activity TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_user_category UNIQUE(user_id, category_id)
);

-- Leaderboards (Time-scoped)
CREATE TABLE leaderboard_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    category_id UUID REFERENCES categories(id),
    points BIGINT,
    rank INTEGER,
    snapshot_type VARCHAR(20),        -- 'daily', 'weekly', 'monthly', 'all_time'
    snapshot_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_leaderboard_lookup (category_id, snapshot_type, snapshot_date, rank)
);

-- Notifications Queue
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(100) NOT NULL,
    body TEXT NOT NULL,
    notification_type VARCHAR(50),    -- 'rank_threat', 'challenge_unlock', 'streak_risk'
    action_url TEXT,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);

-- Indexes for Performance
CREATE INDEX idx_users_global_rank ON users(global_rank) WHERE is_active = true;
CREATE INDEX idx_challenges_category ON challenges(category_id) WHERE is_active = true;
CREATE INDEX idx_user_attempts_user ON user_challenge_attempts(user_id);
CREATE INDEX idx_category_rankings_category ON category_rankings(category_id, rank);
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read, created_at);
```

### **Redis Cache Structure**

```
# Leaderboards (Sorted Sets)
leaderboard:global          -> ZSET (user_id, total_points)
leaderboard:category:{id}   -> ZSET (user_id, category_points)
leaderboard:weekly:{date}   -> ZSET (user_id, weekly_points)

# Active Challenges Cache
challenges:active:{category_id} -> LIST of challenge_ids
challenge:data:{id}            -> HASH of challenge data

# User Session
session:{user_id}              -> HASH (tokens, preferences)
user:stats:{user_id}           -> HASH (quick stats access)

# Rate Limiting
ratelimit:challenges:{user_id} -> STRING (attempts count, TTL)
ratelimit:api:{ip}            -> STRING (request count, TTL)

# Challenge Generation Queue
ai:generation:queue           -> LIST of pending generation tasks
ai:generated:cache:{params}   -> STRING (cached AI responses, 24h TTL)
```

---

## 🤖 AI Integration Architecture

### **AI Service Strategy**

```go
// internal/service/ai_service.go

type AIService struct {
    claudeClient *anthropic.Client
    openaiClient *openai.Client
    cache        *redis.Client
}

// Challenge Generation Flow
func (s *AIService) GenerateChallenge(ctx context.Context, req ChallengeRequest) (*Challenge, error) {
    // 1. Check cache first (reduce AI costs)
    cacheKey := generateCacheKey(req)
    if cached, err := s.cache.Get(ctx, cacheKey).Result(); err == nil {
        return parseCachedChallenge(cached), nil
    }
    
    // 2. Build AI prompt with legal constraints
    prompt := s.buildChallengePrompt(req)
    
    // 3. Call AI (Claude for complex, GPT-4-mini for simple)
    var response string
    if req.Difficulty >= 4 {
        response = s.callClaude(prompt)
    } else {
        response = s.callOpenAI(prompt)  // Cheaper
    }
    
    // 4. Validate legal compliance
    if !s.validateLegalCompliance(response) {
        return nil, errors.New("AI generated non-compliant content")
    }
    
    // 5. Cache for 24 hours
    s.cache.Set(ctx, cacheKey, response, 24*time.Hour)
    
    return parseChallenge(response), nil
}
```

### **AI Prompt Templates**

```
CHALLENGE_GENERATION_PROMPT = """
You are generating a competitive fan knowledge challenge for the category: {category_name}

HARD CONSTRAINTS (LEGAL):
- DO NOT mention specific celebrity names in challenge titles
- DO NOT reference copyrighted lyrics or quotes verbatim
- DO NOT imply endorsement or official status
- Frame questions as historical/analytical knowledge tests

CHALLENGE REQUIREMENTS:
- Difficulty Tier: {difficulty} (1=Easy, 5=Expert)
- Challenge Type: {type} (multiple_choice, timeline, prediction)
- Time Limit: {time_limit} seconds
- Must be objectively verifiable
- Must have one correct answer

CATEGORY CONTEXT:
{category_description}

RESPONSE FORMAT (JSON):
{
  "question": "Neutral, skill-based question here",
  "options": ["A", "B", "C", "D"],
  "correct_answer": "C",
  "explanation": "Brief explanation of correct answer",
  "difficulty_justification": "Why this is tier {difficulty}"
}

Generate now:
"""
```

### **Cost Optimization Strategy**

| Use Case | AI Model | Cost per 1K Challenges |
|----------|----------|------------------------|
| Easy Challenges (Tier 1-2) | GPT-4o-mini | ~$0.50 |
| Medium Challenges (Tier 3) | GPT-4o-mini | ~$0.75 |
| Hard Challenges (Tier 4-5) | Claude Sonnet | ~$2.00 |
| Moderation | GPT-4o-mini | ~$0.10 |

**Monthly AI Budget Estimate:**
- 1K active users × 5 challenges/day = 5K challenges/day
- Cache hit rate: 60% (reuse challenges)
- Actual AI calls: 2K/day = 60K/month
- **Estimated cost: $60-120/month**

---

## 🔐 Authentication & Security

### **JWT Authentication Flow**

```go
// internal/service/auth_service.go

type AuthService struct {
    userRepo repository.UserRepository
    jwt      jwt.TokenGenerator
}

// Register Flow
func (s *AuthService) Register(req RegisterRequest) (*AuthResponse, error) {
    // 1. Validate input
    if err := validate.Struct(req); err != nil {
        return nil, ErrInvalidInput
    }
    
    // 2. Check username uniqueness
    if exists := s.userRepo.UsernameExists(req.Username); exists {
        return nil, ErrUsernameExist
    }
    
    // 3. Hash password (bcrypt, cost 12)
    hash, _ := bcrypt.GenerateFromPassword([]byte(req.Password), 12)
    
    // 4. Create user
    user := &User{
        Username:     req.Username,
        Email:        req.Email,
        PasswordHash: string(hash),
    }
    
    if err := s.userRepo.Create(user); err != nil {
        return nil, err
    }
    
    // 5. Generate tokens
    accessToken := s.jwt.GenerateAccessToken(user.ID, 15*time.Minute)
    refreshToken := s.jwt.GenerateRefreshToken(user.ID, 7*24*time.Hour)
    
    return &AuthResponse{
        User:         user,
        AccessToken:  accessToken,
        RefreshToken: refreshToken,
    }, nil
}

// Token Refresh Flow
func (s *AuthService) RefreshToken(refreshToken string) (*TokenPair, error) {
    claims, err := s.jwt.ValidateRefreshToken(refreshToken)
    if err != nil {
        return nil, ErrInvalidToken
    }
    
    newAccess := s.jwt.GenerateAccessToken(claims.UserID, 15*time.Minute)
    newRefresh := s.jwt.GenerateRefreshToken(claims.UserID, 7*24*time.Hour)
    
    return &TokenPair{newAccess, newRefresh}, nil
}
```

### **Security Measures**

- **Password:** bcrypt hash (cost 12)
- **Access Token:** 15-minute expiry
- **Refresh Token:** 7-day expiry, rotated on use
- **Rate Limiting:** 100 requests/minute per IP
- **CORS:** Whitelist mobile app origins
- **Input Validation:** go-playground/validator on all endpoints

---

## 📊 Ranking & Leaderboard System

### **ELO-Style Ranking Algorithm**

```go
// internal/service/ranking_service.go

type RankingService struct {
    db    *sql.DB
    cache *redis.Client
}

// Update User Rank after Challenge
func (s *RankingService) UpdateRank(userID uuid.UUID, challengeResult ChallengeResult) error {
    // 1. Calculate points based on difficulty & performance
    points := s.calculatePoints(challengeResult)
    
    // 2. Apply diminishing returns (prevents farming)
    if challengeResult.AttemptsToday > 10 {
        points = int(float64(points) * 0.7) // 30% reduction
    }
    
    // 3. Update user total points
    tx := s.db.Begin()
    if err := s.updateUserPoints(tx, userID, points); err != nil {
        tx.Rollback()
        return err
    }
    
    // 4. Update category-specific rank
    if err := s.updateCategoryRank(tx, userID, challengeResult.CategoryID, points); err != nil {
        tx.Rollback()
        return err
    }
    
    // 5. Update Redis sorted set (for real-time leaderboards)
    s.cache.ZIncrBy(ctx, "leaderboard:global", float64(points), userID.String())
    s.cache.ZIncrBy(ctx, fmt.Sprintf("leaderboard:category:%s", challengeResult.CategoryID), 
                    float64(points), userID.String())
    
    tx.Commit()
    
    // 6. Check if rank threshold triggers notification
    s.checkRankNotification(userID)
    
    return nil
}

// Calculate Points with Difficulty Multiplier
func (s *RankingService) calculatePoints(result ChallengeResult) int {
    basePoints := result.ChallengeBasePoints
    
    // Difficulty multiplier
    multiplier := 1.0
    switch result.Difficulty {
    case 1: multiplier = 1.0
    case 2: multiplier = 1.5
    case 3: multiplier = 2.0
    case 4: multiplier = 3.0
    case 5: multiplier = 5.0
    }
    
    // Speed bonus (finished in < 50% of time limit)
    if result.TimeTaken < result.TimeLimit/2 {
        multiplier *= 1.2
    }
    
    // Streak bonus
    if result.CurrentStreak >= 7 {
        multiplier *= 1.15
    }
    
    // Wrong answer penalty
    if !result.IsCorrect {
        return -int(float64(basePoints) * 0.3) // Lose 30% of potential points
    }
    
    return int(float64(basePoints) * multiplier)
}

// Get Leaderboard (Cached)
func (s *RankingService) GetLeaderboard(categoryID uuid.UUID, scope string, limit int) ([]RankEntry, error) {
    cacheKey := fmt.Sprintf("leaderboard:category:%s:%s", categoryID, scope)
    
    // Try Redis first
    cached, err := s.cache.ZRevRangeWithScores(ctx, cacheKey, 0, int64(limit-1)).Result()
    if err == nil && len(cached) > 0 {
        return parseRankEntries(cached), nil
    }
    
    // Fallback to PostgreSQL
    return s.fetchLeaderboardFromDB(categoryID, scope, limit)
}
```

### **Leaderboard Scopes**

- **Global:** All-time across all categories
- **Category:** Per-category rankings
- **Daily:** Resets at midnight UTC
- **Weekly:** Resets every Monday 00:00 UTC
- **Monthly:** Resets 1st of month

---

## 🔔 Notification System

### **Push Notification Strategy**

```go
// internal/service/notification_service.go

type NotificationService struct {
    fcm   *fcm.Client
    db    *sql.DB
    queue chan Notification
}

// Start background worker
func (s *NotificationService) Start() {
    go s.worker()
}

func (s *NotificationService) worker() {
    for notif := range s.queue {
        // 1. Check user notification preferences
        if !s.userAllowsNotification(notif.UserID, notif.Type) {
            continue
        }
        
        // 2. Legal compliance check
        if !s.isLegallyCompliant(notif) {
            log.Warn("Blocked non-compliant notification", notif)
            continue
        }
        
        // 3. Send via FCM
        msg := &messaging.Message{
            Token: notif.FCMToken,
            Notification: &messaging.Notification{
                Title: notif.Title,
                Body:  notif.Body,
            },
            Data: map[string]string{
                "type":       notif.Type,
                "action_url": notif.ActionURL,
            },
        }
        
        s.fcm.Send(context.Background(), msg)
        
        // 4. Store in DB for in-app inbox
        s.db.Exec("INSERT INTO notifications (...) VALUES (...)")
    }
}

// Trigger Types (All Quest-Based)
func (s *NotificationService) TriggerRankThreat(userID uuid.UUID) {
    s.queue <- Notification{
        UserID: userID,
        Type:   "rank_threat",
        Title:  "Your rank is under threat",
        Body:   "3 users are closing in on your position",
        ActionURL: "/challenges",
    }
}

func (s *NotificationService) TriggerDifficultyUnlock(userID uuid.UUID, tier int) {
    s.queue <- Notification{
        UserID: userID,
        Type:   "difficulty_unlock",
        Title:  fmt.Sprintf("Tier %d unlocked", tier),
        Body:   "Only 8% of users reach this level",
        ActionURL: fmt.Sprintf("/challenges?tier=%d", tier),
    }
}
```

### **Notification Rules (Legal Safe)**

✅ **Allowed:**
- "Your rank is under threat"
- "High-difficulty challenge unlocked"
- "Streak at risk – 2 hours left"
- "Only 4% passed today's test"

❌ **Disallowed:**
- Any celebrity names in titles
- Implied endorsements
- Promotional language
- Non-actionable messages

---

## 🚀 Deployment Architecture

### **Hosting Options (Cost Comparison)**

| Platform | Free Tier | Paid (Small) | Best For |
|----------|-----------|--------------|----------|
| **Fly.io** | 3 VMs (256MB) | $5/month | Go backend ✅ |
| **Railway** | $5 credit/month | $10-20/month | Easy deployment |
| **Render** | 750 hrs/month | $7/month | Static + API |
| **Neon** (DB) | 0.5GB storage | $19/month | PostgreSQL ✅ |
| **Upstash** (Redis) | 10K commands/day | $10/month | Redis cache ✅ |
| **Cloudflare R2** | 10GB storage | $0.015/GB | File storage ✅ |

**Recommended Stack:**
- **Backend:** Fly.io ($5/month for 512MB VM)
- **Database:** Neon free tier → Scale to $19
- **Cache:** Upstash free tier → $10/month
- **Storage:** Cloudflare R2 ($0-5/month)
- **CDN:** Cloudflare (free)
- **Push:** Firebase FCM (free up to 1M messages/month)

**Total Monthly Cost:**
- MVP (0-1K users): **$0-10**
- Growth (10K users): **$50-100**
- Scale (100K users): **$300-500**

### **CI/CD Pipeline**

```yaml
# .github/workflows/deploy.yml

name: Deploy Fanmania Backend

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-go@v4
        with:
          go-version: '1.21'
      - run: go test ./...
      
  deploy:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: superfly/flyctl-actions@master
        with:
          args: deploy
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
```

---

## 📈 Performance & Scaling

### **Performance Targets**

| Metric | Target | Strategy |
|--------|--------|----------|
| API Response Time | < 200ms (p95) | Redis caching, DB indexes |
| Leaderboard Load | < 100ms | Redis sorted sets |
| Challenge Generation | < 3s | AI response caching |
| App Launch Time | < 2s | Optimized Flutter build |
| Concurrent Users | 10K simultaneous | Go concurrency, connection pooling |

### **Scaling Strategy**

**Phase 1: MVP (0-1K users)**
- Single Fly.io instance (512MB)
- Neon free tier
- Upstash free tier

**Phase 2: Growth (1K-10K users)**
- 2x Fly.io instances (1GB each)
- Neon paid tier
- Upstash paid tier
- Add read replicas

**Phase 3: Scale (10K-100K users)**
- Auto-scaling (3-10 instances)
- PostgreSQL primary + 2 read replicas
- Redis cluster (3 nodes)
- CDN for static assets

**Phase 4: Massive (100K+ users)**
- Kubernetes migration
- Sharded databases
- Multi-region deployment

---

## 🧪 Testing Strategy

### **Backend Testing**

```go
// internal/service/ranking_service_test.go

func TestCalculatePoints(t *testing.T) {
    s := &RankingService{}
    
    tests := []struct {
        name     string
        result   ChallengeResult
        expected int
    }{
        {
            name: "Easy correct answer",
            result: ChallengeResult{
                ChallengeBasePoints: 100,
                Difficulty:          1,
                IsCorrect:           true,
            },
            expected: 100,
        },
        {
            name: "Expert with speed bonus",
            result: ChallengeResult{
                ChallengeBasePoints: 100,
                Difficulty:          5,
                IsCorrect:           true,
                TimeTaken:          30,
                TimeLimit:          120,
            },
            expected: 600, // 100 * 5.0 * 1.2
        },
        {
            name: "Wrong answer penalty",
            result: ChallengeResult{
                ChallengeBasePoints: 100,
                Difficulty:          3,
                IsCorrect:           false,
            },
            expected: -30, // 100 * -0.3
        },
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := s.calculatePoints(tt.result)
            if got != tt.expected {
                t.Errorf("got %d, want %d", got, tt.expected)
            }
        })
    }
}
```

### **Flutter Testing**

```dart
// test/features/challenges/bloc/challenge_bloc_test.dart

void main() {
  group('ChallengeBloc', () {
    late ChallengeBloc bloc;
    late MockChallengeRepository mockRepo;
    
    setUp(() {
      mockRepo = MockChallengeRepository();
      bloc = ChallengeBloc(repository: mockRepo);
    });
    
    test('emits [Loading, Loaded] when challenges fetched successfully', () {
      final challenges = [Challenge(id: '1', title: 'Test')];
      when(mockRepo.fetchChallenges(any))
          .thenAnswer((_) async => challenges);
      
      bloc.add(FetchChallenges(categoryId: 'cat-1'));
      
      expectLater(
        bloc.stream,
        emitsInOrder([
          ChallengeLoading(),
          ChallengeLoaded(challenges),
        ]),
      );
    });
  });
}
```

---

## 🔒 Legal Compliance Checklist

### **Pre-Launch Verification**

- [ ] No celebrity images anywhere in app
- [ ] No official logos or branding
- [ ] Challenges use nominative fair use only
- [ ] No implied endorsements in copy
- [ ] Notification titles are generic
- [ ] Leaderboards are category-based, not person-based
- [ ] Terms of Service reviewed by lawyer
- [ ] Privacy Policy includes AI usage disclosure
- [ ] DMCA takedown process documented
- [ ] Age gate implemented (13+ required)

### **Ongoing Monitoring**

- [ ] AI-generated content flagged for manual review (sample 10%)
- [ ] User-reported content moderation queue
- [ ] Monthly legal audit of top 100 challenges
- [ ] Quarterly review of notification templates

---

## 📋 Development Roadmap

### **Phase 1: MVP (Weeks 1-8)**

**Week 1-2: Backend Foundation**
- [ ] Go project structure setup
- [ ] PostgreSQL schema implementation
- [ ] JWT authentication system
- [ ] Basic CRUD APIs

**Week 3-4: AI Integration**
- [ ] Claude/OpenAI API integration
- [ ] Challenge generation pipeline
- [ ] Legal compliance validation layer
- [ ] Caching strategy implementation

**Week 5-6: Flutter App Core**
- [ ] Design system implementation
- [ ] Authentication screens
- [ ] Home feed & category selection
- [ ] Challenge UI components

**Week 7-8: Ranking & Polish**
- [ ] Ranking algorithm implementation
- [ ] Leaderboard screens
- [ ] Notification system
- [ ] Beta testing

### **Phase 2: Growth Features (Weeks 9-16)**
- [ ] Streak system
- [ ] Social features (limited)
- [ ] Achievement badges
- [ ] Advanced analytics

### **Phase 3: Scale Prep (Weeks 17-24)**
- [ ] Performance optimization
- [ ] Multi-region support
- [ ] Creator opt-in framework
- [ ] Revenue features

---

## 🎨 Next Steps

I'll now create:
1. **API Specification** (OpenAPI/Swagger)
2. **Flutter Project Starter**
3. **Go Backend Boilerplate**
4. **Docker Compose for local dev**
5. **Deployment scripts**

Would you like me to generate any specific component first, or proceed with all of them?
