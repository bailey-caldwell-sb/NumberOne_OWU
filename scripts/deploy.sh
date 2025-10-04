#!/bin/bash

# NumberOne OWU - One-Click Deployment Script
# This script deploys the complete AI platform stack

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOCKER_DIR="$PROJECT_ROOT/docker"
ENV_FILE="$PROJECT_ROOT/.env"

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

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        log_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    
    # Check available disk space (minimum 50GB)
    available_space=$(df "$PROJECT_ROOT" | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt 52428800 ]; then  # 50GB in KB
        log_warning "Less than 50GB available disk space. AI models require significant storage."
    fi
    
    log_success "Prerequisites check passed"
}

setup_environment() {
    log_info "Setting up environment..."
    
    # Create .env file if it doesn't exist
    if [ ! -f "$ENV_FILE" ]; then
        log_info "Creating .env file from template..."
        cp "$PROJECT_ROOT/.env.example" "$ENV_FILE"
        log_warning "Please edit .env file with your API keys and configuration"
    fi
    
    # Create necessary directories
    mkdir -p "$PROJECT_ROOT/data/ollama"
    mkdir -p "$PROJECT_ROOT/data/qdrant"
    mkdir -p "$PROJECT_ROOT/data/openwebui"
    mkdir -p "$PROJECT_ROOT/data/langfuse"
    mkdir -p "$PROJECT_ROOT/data/pipelines"
    mkdir -p "$PROJECT_ROOT/logs"
    mkdir -p "$PROJECT_ROOT/backups"
    
    log_success "Environment setup completed"
}

check_gpu_support() {
    log_info "Checking GPU support..."
    
    if command -v nvidia-smi &> /dev/null; then
        if nvidia-smi &> /dev/null; then
            log_success "NVIDIA GPU detected and available"
            export GPU_SUPPORT=true
        else
            log_warning "NVIDIA GPU detected but not accessible"
            export GPU_SUPPORT=false
        fi
    else
        log_info "No NVIDIA GPU detected, using CPU-only mode"
        export GPU_SUPPORT=false
    fi
}

deploy_services() {
    log_info "Deploying NumberOne OWU services..."
    
    cd "$DOCKER_DIR"
    
    # Pull latest images
    log_info "Pulling latest Docker images..."
    docker-compose pull
    
    # Start services
    log_info "Starting services..."
    docker-compose up -d
    
    log_success "Services deployment initiated"
}

wait_for_services() {
    log_info "Waiting for services to be ready..."
    
    # Wait for Ollama
    log_info "Waiting for Ollama..."
    timeout=300  # 5 minutes
    while [ $timeout -gt 0 ]; do
        if curl -s http://localhost:11434/api/tags &> /dev/null; then
            log_success "Ollama is ready"
            break
        fi
        sleep 5
        timeout=$((timeout - 5))
    done
    
    if [ $timeout -le 0 ]; then
        log_error "Ollama failed to start within timeout"
        return 1
    fi
    
    # Wait for Qdrant
    log_info "Waiting for Qdrant..."
    timeout=120  # 2 minutes
    while [ $timeout -gt 0 ]; do
        if curl -s http://localhost:6333/health &> /dev/null; then
            log_success "Qdrant is ready"
            break
        fi
        sleep 5
        timeout=$((timeout - 5))
    done
    
    # Wait for Open WebUI
    log_info "Waiting for Open WebUI..."
    timeout=180  # 3 minutes
    while [ $timeout -gt 0 ]; do
        if curl -s http://localhost:3000 &> /dev/null; then
            log_success "Open WebUI is ready"
            break
        fi
        sleep 5
        timeout=$((timeout - 5))
    done
    
    # Wait for Langfuse
    log_info "Waiting for Langfuse..."
    timeout=180  # 3 minutes
    while [ $timeout -gt 0 ]; do
        if curl -s http://localhost:3003/api/public/health &> /dev/null; then
            log_success "Langfuse is ready"
            break
        fi
        sleep 5
        timeout=$((timeout - 5))
    done
    
    log_success "All services are ready"
}

download_models() {
    log_info "Downloading AI models..."
    
    # Essential models
    models=(
        "qwen2.5:7b"
        "nomic-embed-text:latest"
    )
    
    # Additional models (optional)
    optional_models=(
        "qwen3:8b"
        "gemma3:4b"
        "phi4:14b"
        "codellama:13b"
    )
    
    # Download essential models
    for model in "${models[@]}"; do
        log_info "Downloading $model..."
        if docker exec numberone-ollama ollama pull "$model"; then
            log_success "Downloaded $model"
        else
            log_error "Failed to download $model"
        fi
    done
    
    # Ask user about optional models
    echo
    read -p "Download additional models? (qwen3:8b, gemma3:4b, phi4:14b, codellama:13b) [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        for model in "${optional_models[@]}"; do
            log_info "Downloading $model..."
            if docker exec numberone-ollama ollama pull "$model"; then
                log_success "Downloaded $model"
            else
                log_warning "Failed to download $model (continuing...)"
            fi
        done
    fi
    
    log_success "Model download completed"
}

verify_deployment() {
    log_info "Verifying deployment..."
    
    # Check service status
    cd "$DOCKER_DIR"
    if ! docker-compose ps | grep -q "Up"; then
        log_error "Some services are not running"
        docker-compose ps
        return 1
    fi
    
    # Test endpoints
    endpoints=(
        "http://localhost:3000:Open WebUI"
        "http://localhost:3003:Langfuse"
        "http://localhost:6333/dashboard:Qdrant Dashboard"
        "http://localhost:11434/api/tags:Ollama API"
        "http://localhost:9099/health:Pipelines"
    )
    
    for endpoint in "${endpoints[@]}"; do
        url="${endpoint%:*}"
        name="${endpoint#*:}"
        
        if curl -s "$url" &> /dev/null; then
            log_success "$name is accessible"
        else
            log_warning "$name is not accessible at $url"
        fi
    done
    
    log_success "Deployment verification completed"
}

show_summary() {
    echo
    echo "=============================================="
    echo "🚀 NumberOne OWU Deployment Complete!"
    echo "=============================================="
    echo
    echo "📱 Access your services:"
    echo "  • Open WebUI:      http://localhost:3000"
    echo "  • Langfuse:        http://localhost:3003"
    echo "  • Qdrant:          http://localhost:6333/dashboard"
    echo "  • System Dashboard: http://localhost:8080"
    echo
    echo "🔧 Management commands:"
    echo "  • View logs:       docker-compose logs -f"
    echo "  • Stop services:   docker-compose down"
    echo "  • Restart:         docker-compose restart"
    echo "  • Update:          ./scripts/update.sh"
    echo
    echo "📚 Next steps:"
    echo "  1. Create your account in Open WebUI"
    echo "  2. Configure pipelines in Admin → Settings"
    echo "  3. Set up Langfuse tracking"
    echo "  4. Start chatting with AI models!"
    echo
    echo "📖 Documentation: docs/SETUP.md"
    echo "🐛 Issues: https://github.com/yourusername/NumberOne_OWU/issues"
    echo
}

# Main execution
main() {
    echo "=============================================="
    echo "🚀 NumberOne OWU Deployment Script"
    echo "=============================================="
    echo
    
    check_prerequisites
    setup_environment
    check_gpu_support
    deploy_services
    wait_for_services
    download_models
    verify_deployment
    show_summary
    
    log_success "Deployment completed successfully!"
}

# Handle script interruption
trap 'log_error "Deployment interrupted"; exit 1' INT TERM

# Run main function
main "$@"
