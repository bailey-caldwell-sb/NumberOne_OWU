#!/bin/bash

# NumberOne OWU - Development Environment Script
# Sets up and manages the development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOCKER_DIR="$PROJECT_ROOT/docker"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    echo "NumberOne OWU Development Environment"
    echo
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  start     Start development environment"
    echo "  stop      Stop development environment"
    echo "  restart   Restart development environment"
    echo "  logs      Show logs for all services"
    echo "  status    Show status of all services"
    echo "  shell     Open shell in specific service"
    echo "  test      Run tests"
    echo "  lint      Run linting"
    echo "  format    Format code"
    echo "  clean     Clean development environment"
    echo "  reset     Reset development environment"
    echo "  help      Show this help message"
    echo
    echo "Examples:"
    echo "  $0 start                    # Start dev environment"
    echo "  $0 logs ollama              # Show Ollama logs"
    echo "  $0 shell pipelines          # Open shell in pipelines container"
    echo "  $0 test pipelines           # Test pipeline code"
    echo
}

check_prerequisites() {
    log_info "Checking development prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not installed"
        exit 1
    fi
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        log_error "Docker is not running"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

setup_dev_environment() {
    log_info "Setting up development environment..."
    
    # Create development .env if it doesn't exist
    if [ ! -f "$PROJECT_ROOT/.env" ]; then
        log_info "Creating development .env file..."
        cp "$PROJECT_ROOT/.env.example" "$PROJECT_ROOT/.env"
        
        # Set development-specific values
        sed -i 's/WEBUI_AUTH=true/WEBUI_AUTH=false/' "$PROJECT_ROOT/.env"
        sed -i 's/DEFAULT_USER_ROLE=user/DEFAULT_USER_ROLE=admin/' "$PROJECT_ROOT/.env"
        sed -i 's/DEBUG_MODE=false/DEBUG_MODE=true/' "$PROJECT_ROOT/.env"
        sed -i 's/LOG_LEVEL=INFO/LOG_LEVEL=DEBUG/' "$PROJECT_ROOT/.env"
        
        log_success "Development .env created"
    fi
    
    # Create development directories
    mkdir -p "$PROJECT_ROOT/data/dev"
    mkdir -p "$PROJECT_ROOT/logs/dev"
    mkdir -p "$PROJECT_ROOT/config/nginx"
    mkdir -p "$PROJECT_ROOT/config/filebrowser"
    
    # Create nginx development config
    if [ ! -f "$PROJECT_ROOT/config/nginx/dev.conf" ]; then
        cat > "$PROJECT_ROOT/config/nginx/dev.conf" << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream openwebui {
        server open-webui:8080;
    }
    
    upstream langfuse {
        server langfuse:3000;
    }
    
    server {
        listen 80;
        server_name localhost;
        
        location / {
            proxy_pass http://openwebui;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
        
        location /langfuse/ {
            proxy_pass http://langfuse/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}
EOF
        log_success "Nginx development config created"
    fi
    
    # Create filebrowser config
    if [ ! -f "$PROJECT_ROOT/config/filebrowser/settings.json" ]; then
        cat > "$PROJECT_ROOT/config/filebrowser/settings.json" << 'EOF'
{
    "port": 80,
    "baseURL": "",
    "address": "",
    "log": "stdout",
    "database": "/database.db",
    "root": "/srv"
}
EOF
        log_success "Filebrowser config created"
    fi
    
    log_success "Development environment setup completed"
}

start_dev() {
    log_info "Starting development environment..."
    
    cd "$DOCKER_DIR"
    
    # Pull latest images
    log_info "Pulling latest development images..."
    docker-compose -f docker-compose.dev.yml pull
    
    # Start services
    log_info "Starting development services..."
    docker-compose -f docker-compose.dev.yml up -d
    
    # Wait for services to be ready
    log_info "Waiting for services to be ready..."
    sleep 30
    
    # Check service health
    services=("open-webui:3000" "ollama:11434/api/tags" "qdrant:6333/health" "pipelines:9099/health")
    
    for service in "${services[@]}"; do
        IFS=':' read -r name endpoint <<< "$service"
        log_info "Checking $name..."
        
        timeout=60
        while [ $timeout -gt 0 ]; do
            if curl -s "http://localhost:$endpoint" &> /dev/null; then
                log_success "$name is ready"
                break
            fi
            sleep 2
            timeout=$((timeout - 2))
        done
        
        if [ $timeout -le 0 ]; then
            log_warning "$name is not responding"
        fi
    done
    
    show_dev_summary
}

stop_dev() {
    log_info "Stopping development environment..."
    
    cd "$DOCKER_DIR"
    docker-compose -f docker-compose.dev.yml down
    
    log_success "Development environment stopped"
}

restart_dev() {
    log_info "Restarting development environment..."
    stop_dev
    start_dev
}

show_logs() {
    local service=$1
    cd "$DOCKER_DIR"
    
    if [ -n "$service" ]; then
        log_info "Showing logs for $service..."
        docker-compose -f docker-compose.dev.yml logs -f "$service"
    else
        log_info "Showing logs for all services..."
        docker-compose -f docker-compose.dev.yml logs -f
    fi
}

show_status() {
    log_info "Development environment status:"
    echo
    
    cd "$DOCKER_DIR"
    docker-compose -f docker-compose.dev.yml ps
    
    echo
    log_info "Service endpoints:"
    echo "  • Open WebUI:      http://localhost:3000"
    echo "  • Langfuse:        http://localhost:3003"
    echo "  • Qdrant:          http://localhost:6333/dashboard"
    echo "  • Adminer:         http://localhost:8080"
    echo "  • File Browser:    http://localhost:8081"
    echo "  • Nginx Proxy:     http://localhost:80"
    echo
}

open_shell() {
    local service=$1
    
    if [ -z "$service" ]; then
        log_error "Please specify a service name"
        echo "Available services: ollama, qdrant, open-webui, langfuse, pipelines, redis, adminer"
        exit 1
    fi
    
    cd "$DOCKER_DIR"
    log_info "Opening shell in $service..."
    docker-compose -f docker-compose.dev.yml exec "$service" /bin/sh
}

run_tests() {
    local service=$1
    
    log_info "Running tests..."
    
    if [ "$service" = "pipelines" ] || [ -z "$service" ]; then
        log_info "Testing pipeline imports..."
        cd "$DOCKER_DIR"
        docker-compose -f docker-compose.dev.yml exec pipelines python -c "
import sys
sys.path.append('/app/pipelines')
try:
    import mem0_memory_filter
    import langfuse_tracking
    import perplexity_search
    print('✅ All pipelines import successfully')
except ImportError as e:
    print(f'❌ Import error: {e}')
    sys.exit(1)
"
    fi
    
    # Add more tests here
    log_success "Tests completed"
}

run_lint() {
    log_info "Running linting..."
    
    # Lint Python files
    if command -v flake8 &> /dev/null; then
        log_info "Linting Python files..."
        flake8 pipelines/ --max-line-length=127 --ignore=E501,W503
    else
        log_warning "flake8 not installed, skipping Python linting"
    fi
    
    # Lint shell scripts
    if command -v shellcheck &> /dev/null; then
        log_info "Linting shell scripts..."
        find scripts/ -name "*.sh" -exec shellcheck {} \;
    else
        log_warning "shellcheck not installed, skipping shell script linting"
    fi
    
    log_success "Linting completed"
}

format_code() {
    log_info "Formatting code..."
    
    # Format Python files
    if command -v black &> /dev/null; then
        log_info "Formatting Python files..."
        black pipelines/
    else
        log_warning "black not installed, skipping Python formatting"
    fi
    
    # Format with isort
    if command -v isort &> /dev/null; then
        log_info "Sorting imports..."
        isort pipelines/
    else
        log_warning "isort not installed, skipping import sorting"
    fi
    
    log_success "Code formatting completed"
}

clean_dev() {
    log_info "Cleaning development environment..."
    
    cd "$DOCKER_DIR"
    
    # Stop services
    docker-compose -f docker-compose.dev.yml down
    
    # Remove development volumes
    docker volume rm $(docker volume ls -q | grep dev) 2>/dev/null || true
    
    # Clean Docker system
    docker system prune -f
    
    log_success "Development environment cleaned"
}

reset_dev() {
    log_warning "This will completely reset the development environment!"
    read -p "Are you sure? [y/N]: " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Resetting development environment..."
        
        cd "$DOCKER_DIR"
        
        # Stop and remove everything
        docker-compose -f docker-compose.dev.yml down -v
        
        # Remove development data
        rm -rf "$PROJECT_ROOT/data/dev"
        rm -rf "$PROJECT_ROOT/logs/dev"
        
        # Recreate environment
        setup_dev_environment
        
        log_success "Development environment reset completed"
    else
        log_info "Reset cancelled"
    fi
}

show_dev_summary() {
    echo
    echo "=============================================="
    echo "🚀 Development Environment Ready!"
    echo "=============================================="
    echo
    echo "📱 Development Services:"
    echo "  • Open WebUI:      http://localhost:3000 (no auth)"
    echo "  • Langfuse:        http://localhost:3003"
    echo "  • Qdrant:          http://localhost:6333/dashboard"
    echo "  • Adminer:         http://localhost:8080"
    echo "  • File Browser:    http://localhost:8081"
    echo "  • Nginx Proxy:     http://localhost:80"
    echo
    echo "🔧 Development Tools:"
    echo "  • Hot reload:      Enabled for pipelines"
    echo "  • Debug logging:   Enabled"
    echo "  • Python debug:    Port 5678"
    echo "  • No auth:         Open WebUI auth disabled"
    echo
    echo "📚 Useful Commands:"
    echo "  • View logs:       ./scripts/dev.sh logs [service]"
    echo "  • Open shell:      ./scripts/dev.sh shell [service]"
    echo "  • Run tests:       ./scripts/dev.sh test"
    echo "  • Format code:     ./scripts/dev.sh format"
    echo
}

# Main execution
main() {
    local command=${1:-help}
    
    case $command in
        start)
            check_prerequisites
            setup_dev_environment
            start_dev
            ;;
        stop)
            stop_dev
            ;;
        restart)
            restart_dev
            ;;
        logs)
            show_logs "$2"
            ;;
        status)
            show_status
            ;;
        shell)
            open_shell "$2"
            ;;
        test)
            run_tests "$2"
            ;;
        lint)
            run_lint
            ;;
        format)
            format_code
            ;;
        clean)
            clean_dev
            ;;
        reset)
            reset_dev
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Handle script interruption
trap 'log_error "Development script interrupted"; exit 1' INT TERM

# Run main function
main "$@"
