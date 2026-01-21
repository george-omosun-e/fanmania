.PHONY: help run build test clean install dev

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install dependencies
	@echo "Installing dependencies..."
	go mod download
	go install github.com/cosmtrek/air@latest

run: ## Run the application
	@echo "Starting server..."
	go run cmd/api/main.go

dev: ## Run with hot reload (requires air)
	@echo "Starting server with hot reload..."
	air -c ../.air.toml

build: ## Build the application
	@echo "Building application..."
	go build -o bin/fanmania-api cmd/api/main.go

build-linux: ## Build for Linux production
	@echo "Building for Linux..."
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
		-ldflags="-w -s" \
		-o bin/fanmania-api-linux \
		cmd/api/main.go

test: ## Run tests
	@echo "Running tests..."
	go test -v ./...

test-coverage: ## Run tests with coverage
	@echo "Running tests with coverage..."
	go test -cover -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out

fmt: ## Format code
	@echo "Formatting code..."
	go fmt ./...

vet: ## Run go vet
	@echo "Running go vet..."
	go vet ./...

lint: ## Run linter (requires golangci-lint)
	@echo "Running linter..."
	golangci-lint run

clean: ## Clean build artifacts
	@echo "Cleaning..."
	rm -rf bin/
	rm -rf tmp/
	rm -f coverage.out

docker-up: ## Start Docker services
	@echo "Starting Docker services..."
	docker-compose up -d

docker-down: ## Stop Docker services
	@echo "Stopping Docker services..."
	docker-compose down

docker-logs: ## View Docker logs
	docker-compose logs -f

db-migrate: ## Run database migrations
	@echo "Running migrations..."
	docker-compose exec postgres psql -U fanmania -d fanmania_dev -f /docker-entrypoint-initdb.d/001_init.sql

db-connect: ## Connect to database
	docker-compose exec postgres psql -U fanmania -d fanmania_dev

redis-cli: ## Connect to Redis CLI
	docker-compose exec redis redis-cli

.DEFAULT_GOAL := help
