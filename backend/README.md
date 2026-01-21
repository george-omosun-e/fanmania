# Fanmania Backend API

Go backend for the Fanmania AI-powered fan skill platform.

## 🚀 Quick Start

### Prerequisites

- Go 1.21+
- PostgreSQL 16+
- Redis 7+

### Setup

1. **Install dependencies:**
```bash
go mod download
```

2. **Configure environment:**
```bash
cp ../.env.example ../.env
# Edit .env and add your configuration
```

3. **Run database migrations:**
```bash
# Using Docker:
docker-compose exec postgres psql -U fanmania -d fanmania_dev -f /docker-entrypoint-initdb.d/001_init.sql

# Or manually:
psql -U fanmania -d fanmania_dev -f ../database_migration_001_init.sql
```

4. **Run the server:**
```bash
# Development (with hot reload)
air

# Or without hot reload
go run cmd/api/main.go
```

## 📁 Project Structure

```
backend/
├── cmd/
│   └── api/
│       └── main.go              # Application entry point
├── internal/
│   ├── config/
│   │   └── config.go            # Configuration loader
│   ├── domain/
│   │   ├── models/              # Data models
│   │   └── errors/              # Custom errors
│   ├── repository/
│   │   └── postgres/            # Database layer
│   ├── service/                 # Business logic
│   ├── handler/                 # HTTP handlers
│   └── middleware/              # HTTP middleware
├── pkg/
│   └── jwt/                     # JWT utilities
├── go.mod
└── go.sum
```

## 🛠️ Development

### Running Locally

```bash
# Start with hot reload
air

# Run tests
go test ./...

# Run with coverage
go test -cover ./...

# Build binary
go build -o bin/api cmd/api/main.go

# Run binary
./bin/api
```

### Available Endpoints

**Public:**
- `GET  /health` - Health check
- `POST /v1/auth/register` - User registration
- `POST /v1/auth/login` - User login
- `POST /v1/auth/refresh` - Refresh access token
- `GET  /v1/categories` - List all categories
- `GET  /v1/categories/:id` - Get category details

**Protected (require Bearer token):**
- `GET   /v1/users/me` - Get current user
- `GET   /v1/users/me/stats` - Get user statistics
- `PATCH /v1/users/me` - Update user profile

### Testing with curl

```bash
# Health check
curl http://localhost:8080/health

# Register
curl -X POST http://localhost:8080/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123"
  }'

# Login
curl -X POST http://localhost:8080/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "password123"
  }'

# Get current user (replace TOKEN)
curl http://localhost:8080/v1/users/me \
  -H "Authorization: Bearer <TOKEN>"

# Get categories
curl http://localhost:8080/v1/categories
```

## 🔧 Configuration

Environment variables (see `.env.example`):

| Variable | Description | Default |
|----------|-------------|---------|
| `APP_ENV` | Environment (development/production) | development |
| `APP_PORT` | Server port | 8080 |
| `DB_HOST` | PostgreSQL host | localhost |
| `DB_PORT` | PostgreSQL port | 5432 |
| `DATABASE_URL` | Full DB connection string | - |
| `REDIS_HOST` | Redis host | localhost |
| `REDIS_URL` | Full Redis connection string | - |
| `JWT_SECRET` | JWT signing secret | **REQUIRED** |
| `ANTHROPIC_API_KEY` | Claude API key | - |
| `OPENAI_API_KEY` | OpenAI API key | - |

## 🐛 Debugging

```bash
# View database logs
docker-compose logs -f postgres

# View Redis logs
docker-compose logs -f redis

# Connect to database
docker-compose exec postgres psql -U fanmania -d fanmania_dev

# Connect to Redis
docker-compose exec redis redis-cli

# Check which process is using port 8080
lsof -i :8080
```

## 📦 Building for Production

```bash
# Build optimized binary
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
  -ldflags="-w -s" \
  -o bin/fanmania-api \
  cmd/api/main.go

# Run
./bin/fanmania-api
```

## 🚢 Deployment

See the main [DEPLOYMENT.md](../DEPLOYMENT.md) for production deployment instructions.

## 📝 Code Quality

```bash
# Format code
go fmt ./...

# Vet code
go vet ./...

# Install linter
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Run linter
golangci-lint run
```

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Run tests: `go test ./...`
4. Format code: `go fmt ./...`
5. Submit a pull request

## 📄 License

Proprietary - All rights reserved
