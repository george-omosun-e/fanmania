#!/bin/bash

# =======================
# Fanmania Quick Start Script
# =======================
# This script helps you get the Fanmania development environment running quickly

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect which docker compose command to use
detect_docker_compose() {
    if command_exists docker-compose; then
        echo "docker-compose"
    elif docker compose version >/dev/null 2>&1; then
        echo "docker compose"
    else
        echo ""
    fi
}

# Main setup
main() {
    print_header "Fanmania Quick Start"
    
    # Check prerequisites
    print_info "Checking prerequisites..."
    
    MISSING_DEPS=0
    
    if ! command_exists docker; then
        print_error "Docker is not installed. Please install Docker first."
        MISSING_DEPS=1
    else
        print_success "Docker found"
    fi
    
    # Detect docker compose command
    COMPOSE_CMD=$(detect_docker_compose)
    if [ -z "$COMPOSE_CMD" ]; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        MISSING_DEPS=1
    else
        print_success "Docker Compose found ($COMPOSE_CMD)"
    fi
    
    if ! command_exists go; then
        print_warning "Go is not installed. Backend development will be limited to Docker."
    else
        print_success "Go found ($(go version))"
    fi
    
    if ! command_exists flutter; then
        print_warning "Flutter is not installed. Mobile development will not be available."
    else
        print_success "Flutter found ($(flutter --version | head -n 1))"
    fi
    
    if [ $MISSING_DEPS -eq 1 ]; then
        print_error "Missing required dependencies. Please install them and try again."
        exit 1
    fi
    
    # Check for .env file
    print_info "Checking environment configuration..."
    if [ ! -f .env ]; then
        print_warning ".env file not found. Creating from template..."
        cp .env.example .env
        print_success "Created .env file"
        print_warning "IMPORTANT: Edit .env and add your API keys:"
        print_warning "  - ANTHROPIC_API_KEY"
        print_warning "  - OPENAI_API_KEY"
        print_warning "  - JWT_SECRET (generate with: openssl rand -base64 64)"
        echo ""
        read -p "Press Enter after you've configured .env..."
    else
        print_success ".env file exists"
    fi
    
    # Start Docker services
    print_header "Starting Services"
    print_info "Starting PostgreSQL, Redis, and Backend..."
    
    $COMPOSE_CMD up -d
    
    print_success "Services started!"
    
    # Wait for services to be healthy
    print_info "Waiting for services to be ready..."
    sleep 5
    
    # Check service health
    if $COMPOSE_CMD ps | grep -q "postgres.*Up"; then
        print_success "PostgreSQL is running"
    else
        print_error "PostgreSQL failed to start"
    fi
    
    if $COMPOSE_CMD ps | grep -q "redis.*Up"; then
        print_success "Redis is running"
    else
        print_error "Redis failed to start"
    fi
    
    if $COMPOSE_CMD ps | grep -q "backend.*Up"; then
        print_success "Backend is running"
    else
        print_warning "Backend may still be starting..."
    fi
    
    # Display access information
    print_header "Services Ready!"
    echo ""
    print_success "Backend API:        http://localhost:8080"
    print_success "API Health Check:   http://localhost:8080/health"
    print_success "PostgreSQL:         localhost:5432"
    print_success "Redis:              localhost:6379"
    print_success "pgAdmin:            http://localhost:5050"
    print_info "  └─ Email: admin@fanmania.local"
    print_info "  └─ Password: admin"
    print_success "Redis Commander:    http://localhost:8081"
    echo ""
    
    # Display next steps
    print_header "Next Steps"
    echo ""
    echo "1. Backend Development:"
    echo "   cd backend"
    echo "   go run cmd/api/main.go"
    echo ""
    echo "2. Mobile Development:"
    echo "   cd mobile"
    echo "   flutter run"
    echo ""
    echo "3. View Logs:"
    echo "   $COMPOSE_CMD logs -f backend"
    echo ""
    echo "4. Stop Services:"
    echo "   $COMPOSE_CMD down"
    echo ""
    echo "5. API Documentation:"
    echo "   See api-specification.yaml"
    echo ""
    
    print_success "Setup complete! Happy coding! 🚀"
}

# Cleanup function
cleanup() {
    print_header "Cleaning Up"
    COMPOSE_CMD=$(detect_docker_compose)
    if [ -n "$COMPOSE_CMD" ]; then
        $COMPOSE_CMD down -v
        print_success "All services stopped and volumes removed"
    else
        print_error "Docker Compose not found"
    fi
}

# Reset function
reset() {
    print_header "Resetting Development Environment"
    print_warning "This will delete all data!"
    read -p "Are you sure? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        cleanup
        rm -rf tmp/
        print_success "Environment reset complete"
    else
        print_info "Reset cancelled"
    fi
}

# Script arguments
case "${1:-}" in
    start)
        main
        ;;
    stop)
        print_header "Stopping Services"
        COMPOSE_CMD=$(detect_docker_compose)
        if [ -n "$COMPOSE_CMD" ]; then
            $COMPOSE_CMD down
            print_success "Services stopped"
        else
            print_error "Docker Compose not found"
        fi
        ;;
    restart)
        print_header "Restarting Services"
        COMPOSE_CMD=$(detect_docker_compose)
        if [ -n "$COMPOSE_CMD" ]; then
            $COMPOSE_CMD restart
            print_success "Services restarted"
        else
            print_error "Docker Compose not found"
        fi
        ;;
    logs)
        COMPOSE_CMD=$(detect_docker_compose)
        if [ -n "$COMPOSE_CMD" ]; then
            $COMPOSE_CMD logs -f
        else
            print_error "Docker Compose not found"
        fi
        ;;
    clean)
        cleanup
        ;;
    reset)
        reset
        ;;
    *)
        print_header "Fanmania Development Script"
        echo ""
        echo "Usage: $0 {start|stop|restart|logs|clean|reset}"
        echo ""
        echo "Commands:"
        echo "  start   - Start all services and run initial setup"
        echo "  stop    - Stop all services"
        echo "  restart - Restart all services"
        echo "  logs    - View logs from all services"
        echo "  clean   - Stop services and remove volumes"
        echo "  reset   - Complete reset (removes all data)"
        echo ""
        echo "Examples:"
        echo "  $0 start         # First time setup"
        echo "  $0 logs          # Watch logs"
        echo "  $0 stop          # When done for the day"
        exit 1
        ;;
esac