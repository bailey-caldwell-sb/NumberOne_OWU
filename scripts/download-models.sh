#!/bin/bash

# NumberOne OWU - Model Download Script
# Downloads and configures AI models for the platform

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

check_ollama() {
    log_info "Checking Ollama availability..."
    
    if ! docker ps --format "{{.Names}}" | grep -q "ollama"; then
        log_error "Ollama container is not running. Please start it first with:"
        echo "  cd docker && docker-compose up -d ollama"
        exit 1
    fi
    
    # Wait for Ollama to be ready
    timeout=60
    while [ $timeout -gt 0 ]; do
        if docker exec numberone-ollama ollama list &> /dev/null; then
            log_success "Ollama is ready"
            break
        fi
        sleep 2
        timeout=$((timeout - 2))
    done
    
    if [ $timeout -le 0 ]; then
        log_error "Ollama failed to become ready within timeout"
        exit 1
    fi
}

download_model() {
    local model=$1
    local description=$2
    local size=$3
    
    log_info "Downloading $model ($description) - Size: $size"
    
    if docker exec numberone-ollama ollama pull "$model"; then
        log_success "✅ Downloaded $model"
        return 0
    else
        log_error "❌ Failed to download $model"
        return 1
    fi
}

show_model_menu() {
    echo
    echo "=============================================="
    echo "🤖 Available AI Models"
    echo "=============================================="
    echo
    echo "Essential Models (Required):"
    echo "  1. qwen2.5:7b          - General purpose (4.4 GB)"
    echo "  2. nomic-embed-text    - Embeddings (274 MB)"
    echo
    echo "Flagship Models (2025 Latest):"
    echo "  3. qwen3:8b            - Next-gen reasoning (5.2 GB)"
    echo "  4. gemma3:4b           - Google efficient (3.3 GB)"
    echo "  5. phi4:14b            - Microsoft latest (9.1 GB)"
    echo
    echo "Specialized Models:"
    echo "  6. codellama:13b       - Code specialist (7.3 GB)"
    echo "  7. qwen2.5:14b         - Larger variant (8.7 GB)"
    echo "  8. mistral:7b-instruct - European AI (4.1 GB)"
    echo "  9. deepseek-coder:6.7b - Advanced coding (3.8 GB)"
    echo " 10. llama3.2:3b        - Ultra-fast (2.0 GB)"
    echo
    echo "Additional Models:"
    echo " 11. llama3.1:8b        - Meta's flagship (4.7 GB)"
    echo " 12. yi:6b              - 01.AI model (3.4 GB)"
    echo " 13. neural-chat:7b     - Intel optimized (4.1 GB)"
    echo " 14. openchat:7b        - Open source chat (4.1 GB)"
    echo " 15. starling-lm:7b     - Berkeley model (4.1 GB)"
    echo " 16. vicuna:7b          - UC Berkeley (4.1 GB)"
    echo
    echo "Download Options:"
    echo "  a) Essential only (4.7 GB total)"
    echo "  b) Essential + Flagship (18.2 GB total)"
    echo "  c) All models (65+ GB total)"
    echo "  d) Custom selection"
    echo "  q) Quit"
    echo
}

download_essential() {
    log_info "Downloading essential models..."
    
    local models=(
        "qwen2.5:7b:General purpose model:4.4 GB"
        "nomic-embed-text:latest:Embedding model:274 MB"
    )
    
    local failed=0
    for model_info in "${models[@]}"; do
        IFS=':' read -r model tag description size <<< "$model_info"
        if [ "$tag" != "latest" ]; then
            model="$model:$tag"
        fi
        
        if ! download_model "$model" "$description" "$size"; then
            failed=$((failed + 1))
        fi
    done
    
    if [ $failed -eq 0 ]; then
        log_success "All essential models downloaded successfully"
    else
        log_warning "$failed essential models failed to download"
    fi
}

download_flagship() {
    log_info "Downloading flagship models..."
    
    local models=(
        "qwen3:8b:Next-generation reasoning:5.2 GB"
        "gemma3:4b:Google efficient model:3.3 GB"
        "phi4:14b:Microsoft latest:9.1 GB"
    )
    
    local failed=0
    for model_info in "${models[@]}"; do
        IFS=':' read -r model description size <<< "$model_info"
        
        if ! download_model "$model" "$description" "$size"; then
            failed=$((failed + 1))
        fi
    done
    
    if [ $failed -eq 0 ]; then
        log_success "All flagship models downloaded successfully"
    else
        log_warning "$failed flagship models failed to download"
    fi
}

download_all() {
    log_info "Downloading all models..."
    
    local models=(
        # Essential
        "qwen2.5:7b:General purpose:4.4 GB"
        "nomic-embed-text:latest:Embeddings:274 MB"
        # Flagship
        "qwen3:8b:Next-gen reasoning:5.2 GB"
        "gemma3:4b:Google efficient:3.3 GB"
        "phi4:14b:Microsoft latest:9.1 GB"
        # Specialized
        "codellama:13b:Code specialist:7.3 GB"
        "qwen2.5:14b:Larger variant:8.7 GB"
        "mistral:7b-instruct:European AI:4.1 GB"
        "deepseek-coder:6.7b:Advanced coding:3.8 GB"
        "llama3.2:3b:Ultra-fast:2.0 GB"
        # Additional
        "llama3.1:8b:Meta flagship:4.7 GB"
        "yi:6b:01.AI model:3.4 GB"
        "neural-chat:7b:Intel optimized:4.1 GB"
        "openchat:7b:Open source chat:4.1 GB"
        "starling-lm:7b:Berkeley model:4.1 GB"
        "vicuna:7b:UC Berkeley:4.1 GB"
    )
    
    local total=${#models[@]}
    local failed=0
    local current=0
    
    for model_info in "${models[@]}"; do
        current=$((current + 1))
        IFS=':' read -r model description size <<< "$model_info"
        
        echo "[$current/$total] Downloading $model..."
        
        if ! download_model "$model" "$description" "$size"; then
            failed=$((failed + 1))
        fi
    done
    
    echo
    log_info "Download Summary:"
    log_info "Total models: $total"
    log_success "Successfully downloaded: $((total - failed))"
    if [ $failed -gt 0 ]; then
        log_warning "Failed downloads: $failed"
    fi
}

custom_selection() {
    log_info "Custom model selection..."
    
    local models=(
        "qwen2.5:7b:General purpose:4.4 GB"
        "nomic-embed-text:latest:Embeddings:274 MB"
        "qwen3:8b:Next-gen reasoning:5.2 GB"
        "gemma3:4b:Google efficient:3.3 GB"
        "phi4:14b:Microsoft latest:9.1 GB"
        "codellama:13b:Code specialist:7.3 GB"
        "qwen2.5:14b:Larger variant:8.7 GB"
        "mistral:7b-instruct:European AI:4.1 GB"
        "deepseek-coder:6.7b:Advanced coding:3.8 GB"
        "llama3.2:3b:Ultra-fast:2.0 GB"
        "llama3.1:8b:Meta flagship:4.7 GB"
        "yi:6b:01.AI model:3.4 GB"
        "neural-chat:7b:Intel optimized:4.1 GB"
        "openchat:7b:Open source chat:4.1 GB"
        "starling-lm:7b:Berkeley model:4.1 GB"
        "vicuna:7b:UC Berkeley:4.1 GB"
    )
    
    echo
    echo "Select models to download (space-separated numbers, e.g., 1 3 5):"
    echo "Or type 'all' for all models, 'essential' for essential only:"
    
    for i in "${!models[@]}"; do
        IFS=':' read -r model description size <<< "${models[$i]}"
        printf "%2d. %-20s - %s (%s)\n" $((i + 1)) "$model" "$description" "$size"
    done
    
    echo
    read -p "Enter your selection: " selection
    
    if [ "$selection" = "all" ]; then
        download_all
        return
    elif [ "$selection" = "essential" ]; then
        download_essential
        return
    fi
    
    # Parse selection
    local failed=0
    for num in $selection; do
        if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le ${#models[@]} ]; then
            local index=$((num - 1))
            IFS=':' read -r model description size <<< "${models[$index]}"
            
            if ! download_model "$model" "$description" "$size"; then
                failed=$((failed + 1))
            fi
        else
            log_warning "Invalid selection: $num"
        fi
    done
    
    if [ $failed -eq 0 ]; then
        log_success "All selected models downloaded successfully"
    else
        log_warning "$failed models failed to download"
    fi
}

list_installed_models() {
    log_info "Currently installed models:"
    echo
    docker exec numberone-ollama ollama list
    echo
}

show_disk_usage() {
    log_info "Disk usage information:"
    echo
    echo "Available space:"
    df -h "$PROJECT_ROOT" | awk 'NR==2 {print "  Available: " $4 " (" $5 " used)"}'
    echo
    echo "Ollama data usage:"
    docker exec numberone-ollama du -sh /root/.ollama 2>/dev/null || echo "  Unable to check Ollama data usage"
    echo
}

# Main execution
main() {
    echo "=============================================="
    echo "🤖 NumberOne OWU Model Download Script"
    echo "=============================================="
    echo
    
    check_ollama
    show_disk_usage
    list_installed_models
    
    while true; do
        show_model_menu
        read -p "Select an option: " choice
        
        case $choice in
            a|A)
                download_essential
                break
                ;;
            b|B)
                download_essential
                download_flagship
                break
                ;;
            c|C)
                echo
                log_warning "This will download 65+ GB of models. Continue? [y/N]"
                read -p "> " confirm
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    download_all
                fi
                break
                ;;
            d|D)
                custom_selection
                break
                ;;
            q|Q)
                log_info "Exiting..."
                exit 0
                ;;
            *)
                log_error "Invalid option. Please try again."
                ;;
        esac
    done
    
    echo
    log_success "Model download process completed!"
    echo
    list_installed_models
}

# Handle script interruption
trap 'log_error "Download interrupted"; exit 1' INT TERM

# Run main function
main "$@"
