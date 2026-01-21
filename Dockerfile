# =======================
# DEVELOPMENT DOCKERFILE
# =======================
# Multi-stage build optimized for development with hot reload

FROM golang:1.21-alpine AS development

# Install dependencies for development
RUN apk add --no-cache git make bash curl

# Install Air for hot reload
RUN go install github.com/cosmtrek/air@latest

# Set working directory
WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Expose port
EXPOSE 8080

# Use Air for hot reload in development
CMD ["air", "-c", ".air.toml"]

# =======================
# PRODUCTION DOCKERFILE
# =======================
# Use this for production deployments

FROM golang:1.21-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git make

WORKDIR /build

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build binary with optimizations
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s -X main.Version=${VERSION}" \
    -o /build/fanmania-api \
    ./cmd/api

# =======================
# FINAL STAGE (Production)
# =======================
FROM alpine:latest AS production

# Install CA certificates for HTTPS
RUN apk --no-cache add ca-certificates tzdata

# Create non-root user
RUN addgroup -g 1000 fanmania && \
    adduser -D -u 1000 -G fanmania fanmania

WORKDIR /app

# Copy binary from builder
COPY --from=builder /build/fanmania-api .

# Copy migrations (if needed at runtime)
COPY --from=builder /build/migrations ./migrations

# Change ownership
RUN chown -R fanmania:fanmania /app

# Switch to non-root user
USER fanmania

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/app/fanmania-api", "health"] || exit 1

# Run binary
ENTRYPOINT ["/app/fanmania-api"]

# =======================
# BUILD INSTRUCTIONS
# =======================
# Development:
#   docker build --target development -t fanmania-api:dev .
#   docker run -p 8080:8080 --env-file .env fanmania-api:dev
#
# Production:
#   docker build --target production -t fanmania-api:prod .
#   docker run -p 8080:8080 --env-file .env fanmania-api:prod
#
# Multi-platform build:
#   docker buildx build --platform linux/amd64,linux/arm64 -t fanmania-api:latest .
