#!/bin/bash

# NumberOne OWU - Backup Script
# Creates comprehensive backups of all data and configurations

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
BACKUP_DIR="$PROJECT_ROOT/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="numberone_owu_backup_$TIMESTAMP"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

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

create_backup_dir() {
    log_info "Creating backup directory..."
    mkdir -p "$BACKUP_PATH"
    mkdir -p "$BACKUP_PATH/docker_volumes"
    mkdir -p "$BACKUP_PATH/config"
    mkdir -p "$BACKUP_PATH/logs"
    mkdir -p "$BACKUP_PATH/metadata"
}

backup_docker_volumes() {
    log_info "Backing up Docker volumes..."
    
    cd "$PROJECT_ROOT/docker"
    
    # Get list of volumes
    volumes=$(docker-compose config --volumes)
    
    for volume in $volumes; do
        log_info "Backing up volume: $volume"
        
        # Create volume backup using docker run
        docker run --rm \
            -v "${volume}:/source:ro" \
            -v "$BACKUP_PATH/docker_volumes:/backup" \
            alpine:latest \
            tar -czf "/backup/${volume}.tar.gz" -C /source .
            
        if [ $? -eq 0 ]; then
            log_success "Volume $volume backed up successfully"
        else
            log_error "Failed to backup volume $volume"
        fi
    done
}

backup_configurations() {
    log_info "Backing up configurations..."
    
    # Copy configuration files
    cp "$PROJECT_ROOT/.env" "$BACKUP_PATH/config/" 2>/dev/null || log_warning ".env file not found"
    cp -r "$PROJECT_ROOT/docker" "$BACKUP_PATH/config/"
    cp -r "$PROJECT_ROOT/pipelines" "$BACKUP_PATH/config/"
    
    # Copy any custom configurations
    if [ -d "$PROJECT_ROOT/config" ]; then
        cp -r "$PROJECT_ROOT/config" "$BACKUP_PATH/"
    fi
    
    log_success "Configurations backed up"
}

backup_logs() {
    log_info "Backing up logs..."
    
    cd "$PROJECT_ROOT/docker"
    
    # Export container logs
    containers=$(docker-compose ps --services)
    
    for container in $containers; do
        log_info "Exporting logs for: $container"
        docker-compose logs --no-color "$container" > "$BACKUP_PATH/logs/${container}.log" 2>/dev/null || true
    done
    
    # Copy any local log files
    if [ -d "$PROJECT_ROOT/logs" ]; then
        cp -r "$PROJECT_ROOT/logs"/* "$BACKUP_PATH/logs/" 2>/dev/null || true
    fi
    
    log_success "Logs backed up"
}

create_metadata() {
    log_info "Creating backup metadata..."
    
    # System information
    cat > "$BACKUP_PATH/metadata/system_info.txt" << EOF
NumberOne OWU Backup Information
================================
Backup Date: $(date)
Backup Version: $TIMESTAMP
System: $(uname -a)
Docker Version: $(docker --version)
Docker Compose Version: $(docker-compose --version)

Services Status at Backup Time:
$(cd "$PROJECT_ROOT/docker" && docker-compose ps)

Docker Images:
$(docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}")

Docker Volumes:
$(docker volume ls)
EOF

    # Environment variables (sanitized)
    if [ -f "$PROJECT_ROOT/.env" ]; then
        log_info "Creating sanitized environment backup..."
        grep -v -E "(API_KEY|SECRET|PASSWORD|TOKEN)" "$PROJECT_ROOT/.env" > "$BACKUP_PATH/metadata/env_sanitized.txt" || true
    fi
    
    # Git information
    if [ -d "$PROJECT_ROOT/.git" ]; then
        cd "$PROJECT_ROOT"
        echo "Git Commit: $(git rev-parse HEAD)" >> "$BACKUP_PATH/metadata/system_info.txt"
        echo "Git Branch: $(git branch --show-current)" >> "$BACKUP_PATH/metadata/system_info.txt"
        echo "Git Status:" >> "$BACKUP_PATH/metadata/system_info.txt"
        git status --porcelain >> "$BACKUP_PATH/metadata/system_info.txt"
    fi
    
    log_success "Metadata created"
}

export_ollama_models() {
    log_info "Exporting Ollama model list..."
    
    # Get list of installed models
    if docker ps --format "{{.Names}}" | grep -q "ollama"; then
        docker exec numberone-ollama ollama list > "$BACKUP_PATH/metadata/ollama_models.txt" 2>/dev/null || true
        log_success "Ollama models list exported"
    else
        log_warning "Ollama container not running, skipping model list export"
    fi
}

create_restore_script() {
    log_info "Creating restore script..."
    
    cat > "$BACKUP_PATH/restore.sh" << 'EOF'
#!/bin/bash

# NumberOne OWU - Restore Script
# Restores from backup created by backup.sh

set -e

BACKUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$BACKUP_DIR")")"

echo "🔄 Restoring NumberOne OWU from backup..."
echo "Backup: $BACKUP_DIR"
echo "Target: $PROJECT_ROOT"

read -p "This will overwrite existing data. Continue? [y/N]: " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Restore cancelled"
    exit 1
fi

# Stop services
echo "Stopping services..."
cd "$PROJECT_ROOT/docker"
docker-compose down -v

# Restore configurations
echo "Restoring configurations..."
cp -r "$BACKUP_DIR/config/docker" "$PROJECT_ROOT/"
cp -r "$BACKUP_DIR/config/pipelines" "$PROJECT_ROOT/"
cp "$BACKUP_DIR/config/.env" "$PROJECT_ROOT/" 2>/dev/null || true

# Restore Docker volumes
echo "Restoring Docker volumes..."
cd "$PROJECT_ROOT/docker"

# Recreate volumes
docker-compose up --no-start

for volume_backup in "$BACKUP_DIR/docker_volumes"/*.tar.gz; do
    if [ -f "$volume_backup" ]; then
        volume_name=$(basename "$volume_backup" .tar.gz)
        echo "Restoring volume: $volume_name"
        
        docker run --rm \
            -v "${volume_name}:/target" \
            -v "$BACKUP_DIR/docker_volumes:/backup:ro" \
            alpine:latest \
            tar -xzf "/backup/${volume_name}.tar.gz" -C /target
    fi
done

# Start services
echo "Starting services..."
docker-compose up -d

echo "✅ Restore completed successfully!"
echo "Please verify all services are working correctly."
EOF

    chmod +x "$BACKUP_PATH/restore.sh"
    log_success "Restore script created"
}

compress_backup() {
    log_info "Compressing backup..."
    
    cd "$BACKUP_DIR"
    tar -czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"
    
    if [ $? -eq 0 ]; then
        # Remove uncompressed backup
        rm -rf "$BACKUP_NAME"
        log_success "Backup compressed: ${BACKUP_NAME}.tar.gz"
    else
        log_error "Failed to compress backup"
        return 1
    fi
}

cleanup_old_backups() {
    log_info "Cleaning up old backups..."
    
    # Keep only the last 7 backups
    cd "$BACKUP_DIR"
    ls -t numberone_owu_backup_*.tar.gz 2>/dev/null | tail -n +8 | xargs rm -f 2>/dev/null || true
    
    log_success "Old backups cleaned up"
}

show_summary() {
    echo
    echo "=============================================="
    echo "💾 Backup Summary"
    echo "=============================================="
    echo "Backup Name: $BACKUP_NAME"
    echo "Backup Path: $BACKUP_DIR/${BACKUP_NAME}.tar.gz"
    echo "Backup Size: $(du -h "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" | cut -f1)"
    echo "Created: $(date)"
    echo
    echo "📁 Backup Contents:"
    echo "  • Docker volumes (all persistent data)"
    echo "  • Configuration files (.env, docker-compose.yml)"
    echo "  • Pipeline configurations"
    echo "  • Service logs"
    echo "  • System metadata"
    echo "  • Restore script"
    echo
    echo "🔄 To restore this backup:"
    echo "  tar -xzf ${BACKUP_NAME}.tar.gz"
    echo "  cd ${BACKUP_NAME}"
    echo "  ./restore.sh"
    echo
}

# Main execution
main() {
    echo "=============================================="
    echo "💾 NumberOne OWU Backup Script"
    echo "=============================================="
    echo
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        log_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    
    create_backup_dir
    backup_docker_volumes
    backup_configurations
    backup_logs
    create_metadata
    export_ollama_models
    create_restore_script
    compress_backup
    cleanup_old_backups
    show_summary
    
    log_success "Backup completed successfully!"
}

# Handle script interruption
trap 'log_error "Backup interrupted"; exit 1' INT TERM

# Run main function
main "$@"
