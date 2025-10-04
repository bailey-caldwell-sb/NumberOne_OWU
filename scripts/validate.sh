#!/bin/bash

# NumberOne OWU - Repository Validation Script
# Validates the complete repository structure and configuration

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

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✅ PASS]${NC} $1"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
}

log_warning() {
    echo -e "${YELLOW}[⚠️  WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[❌ FAIL]${NC} $1"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
}

check_file() {
    local file=$1
    local description=$2
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [ -f "$PROJECT_ROOT/$file" ]; then
        log_success "$description exists"
    else
        log_error "$description missing: $file"
    fi
}

check_directory() {
    local dir=$1
    local description=$2
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [ -d "$PROJECT_ROOT/$dir" ]; then
        log_success "$description exists"
    else
        log_error "$description missing: $dir"
    fi
}

check_executable() {
    local file=$1
    local description=$2
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [ -x "$PROJECT_ROOT/$file" ]; then
        log_success "$description is executable"
    else
        log_error "$description not executable: $file"
    fi
}

validate_structure() {
    log_info "Validating repository structure..."
    echo
    
    # Root files
    check_file "README.md" "Main README"
    check_file "LICENSE" "License file"
    check_file ".env.example" "Environment template"
    check_file ".gitignore" "Git ignore file"
    
    # Documentation
    check_directory "docs" "Documentation directory"
    check_file "docs/SETUP.md" "Setup guide"
    check_file "docs/AGENTS.md" "Agent documentation"
    check_file "docs/API.md" "API reference"
    check_file "docs/TROUBLESHOOTING.md" "Troubleshooting guide"
    
    # Docker configuration
    check_directory "docker" "Docker directory"
    check_file "docker/docker-compose.yml" "Main Docker Compose"
    check_file "docker/docker-compose.dev.yml" "Development Docker Compose"
    
    # Pipelines
    check_directory "pipelines" "Pipelines directory"
    check_file "pipelines/mem0_memory_filter.py" "Memory pipeline"
    check_file "pipelines/langfuse_tracking.py" "Langfuse pipeline"
    check_file "pipelines/perplexity_search.py" "Perplexity pipeline"
    
    # Scripts
    check_directory "scripts" "Scripts directory"
    check_file "scripts/deploy.sh" "Deployment script"
    check_file "scripts/backup.sh" "Backup script"
    check_file "scripts/dev.sh" "Development script"
    check_file "scripts/download-models.sh" "Model download script"
    check_file "scripts/init-repo.sh" "Repository initialization script"
    check_file "scripts/validate.sh" "Validation script"
    
    # Monitoring
    check_directory "monitoring" "Monitoring directory"
    check_directory "monitoring/dashboard" "Dashboard directory"
    check_file "monitoring/dashboard/Dockerfile" "Dashboard Dockerfile"
    check_file "monitoring/dashboard/package.json" "Dashboard package.json"
    check_file "monitoring/dashboard/server.js" "Dashboard server"
    
    # GitHub configuration
    check_directory ".github" "GitHub directory"
    check_directory ".github/workflows" "GitHub workflows"
    check_file ".github/workflows/ci.yml" "CI/CD workflow"
    
    echo
}

validate_executables() {
    log_info "Validating script executables..."
    echo
    
    check_executable "scripts/deploy.sh" "Deployment script"
    check_executable "scripts/backup.sh" "Backup script"
    check_executable "scripts/dev.sh" "Development script"
    check_executable "scripts/download-models.sh" "Model download script"
    check_executable "scripts/init-repo.sh" "Repository initialization script"
    check_executable "scripts/validate.sh" "Validation script"
    
    echo
}

validate_docker_configs() {
    log_info "Validating Docker configurations..."
    echo
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if docker-compose -f "$PROJECT_ROOT/docker/docker-compose.yml" config &> /dev/null; then
        log_success "Main Docker Compose is valid"
    else
        log_error "Main Docker Compose has syntax errors"
    fi
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if docker-compose -f "$PROJECT_ROOT/docker/docker-compose.dev.yml" config &> /dev/null; then
        log_success "Development Docker Compose is valid"
    else
        log_error "Development Docker Compose has syntax errors"
    fi
    
    echo
}

validate_python_syntax() {
    log_info "Validating Python syntax..."
    echo
    
    local python_files=(
        "pipelines/mem0_memory_filter.py"
        "pipelines/langfuse_tracking.py"
        "pipelines/perplexity_search.py"
        "monitoring/dashboard/server.js"
    )
    
    for file in "${python_files[@]}"; do
        if [[ "$file" == *.py ]]; then
            TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
            if python3 -m py_compile "$PROJECT_ROOT/$file" 2>/dev/null; then
                log_success "Python syntax valid: $file"
            else
                log_error "Python syntax error: $file"
            fi
        fi
    done
    
    echo
}

validate_environment_template() {
    log_info "Validating environment template..."
    echo
    
    local required_vars=(
        "ANTHROPIC_API_KEY"
        "OPENAI_API_KEY"
        "PERPLEXITY_API_KEY"
        "MEM0_USER"
        "MEM0_STORE_CYCLES"
        "LANGFUSE_SECRET"
        "LANGFUSE_SALT"
        "WEBUI_NAME"
        "OLLAMA_KEEP_ALIVE"
    )
    
    for var in "${required_vars[@]}"; do
        TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
        if grep -q "^$var=" "$PROJECT_ROOT/.env.example" 2>/dev/null; then
            log_success "Environment variable defined: $var"
        else
            log_error "Environment variable missing: $var"
        fi
    done
    
    echo
}

validate_documentation() {
    log_info "Validating documentation..."
    echo
    
    # Check for required sections in README
    local readme_sections=(
        "Features"
        "Quick Start"
        "Installation"
        "Configuration"
        "Documentation"
    )
    
    for section in "${readme_sections[@]}"; do
        TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
        if grep -q "$section" "$PROJECT_ROOT/README.md" 2>/dev/null; then
            log_success "README section exists: $section"
        else
            log_error "README section missing: $section"
        fi
    done
    
    # Check documentation links
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if grep -q "docs/SETUP.md" "$PROJECT_ROOT/README.md" 2>/dev/null; then
        log_success "Setup guide linked in README"
    else
        log_error "Setup guide not linked in README"
    fi
    
    echo
}

validate_security() {
    log_info "Validating security configuration..."
    echo
    
    # Check .gitignore for sensitive files
    local sensitive_patterns=(
        ".env"
        "*.key"
        "secrets/"
        "*.log"
        "data/"
    )
    
    for pattern in "${sensitive_patterns[@]}"; do
        TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
        if grep -q "$pattern" "$PROJECT_ROOT/.gitignore" 2>/dev/null; then
            log_success "Sensitive pattern ignored: $pattern"
        else
            log_error "Sensitive pattern not ignored: $pattern"
        fi
    done
    
    # Check for hardcoded secrets (excluding development configs and variable names)
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if grep -r "sk-[a-zA-Z0-9]\|pk-[a-zA-Z0-9]\|AIza[a-zA-Z0-9]" "$PROJECT_ROOT" --exclude-dir=.git --exclude="*.md" --exclude=".env.example" | grep -v "your_.*_here" | grep -v "changeme" | grep -v "example" | grep -v "test-" | grep -v "dev-" &> /dev/null; then
        log_error "Potential real API keys found"
    else
        log_success "No hardcoded real secrets detected"
    fi
    
    echo
}

validate_completeness() {
    log_info "Validating feature completeness..."
    echo
    
    # Check pipeline features
    local pipeline_features=(
        "mem0.*memory"
        "langfuse.*tracking"
        "perplexity.*search"
    )
    
    for feature in "${pipeline_features[@]}"; do
        TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
        if find "$PROJECT_ROOT/pipelines" -name "*.py" -exec grep -l "$feature" {} \; | head -1 &> /dev/null; then
            log_success "Pipeline feature implemented: $feature"
        else
            log_error "Pipeline feature missing: $feature"
        fi
    done
    
    # Check automation scripts
    local automation_features=(
        "deploy"
        "backup"
        "development"
        "model.*download"
    )
    
    for feature in "${automation_features[@]}"; do
        TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
        if find "$PROJECT_ROOT/scripts" -name "*.sh" -exec grep -l "$feature" {} \; | head -1 &> /dev/null; then
            log_success "Automation feature implemented: $feature"
        else
            log_error "Automation feature missing: $feature"
        fi
    done
    
    echo
}

show_validation_summary() {
    echo "=============================================="
    echo "📋 Validation Summary"
    echo "=============================================="
    echo
    echo "Total Checks: $TOTAL_CHECKS"
    echo -e "Passed: ${GREEN}$PASSED_CHECKS${NC}"
    echo -e "Failed: ${RED}$FAILED_CHECKS${NC}"
    echo
    
    local success_rate=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
    
    if [ $FAILED_CHECKS -eq 0 ]; then
        echo -e "${GREEN}🎉 All validations passed! Repository is ready.${NC}"
        echo
        echo "✅ Repository structure is complete"
        echo "✅ All scripts are executable"
        echo "✅ Docker configurations are valid"
        echo "✅ Python syntax is correct"
        echo "✅ Documentation is comprehensive"
        echo "✅ Security best practices followed"
        echo
        echo "🚀 Ready for deployment!"
    elif [ $success_rate -ge 90 ]; then
        echo -e "${YELLOW}⚠️  Minor issues found ($success_rate% success rate)${NC}"
        echo "Repository is mostly ready but has some minor issues to fix."
    else
        echo -e "${RED}❌ Significant issues found ($success_rate% success rate)${NC}"
        echo "Repository needs attention before deployment."
    fi
    
    echo
    echo "Next steps:"
    if [ $FAILED_CHECKS -eq 0 ]; then
        echo "  1. Run: ./scripts/init-repo.sh"
        echo "  2. Push to GitHub"
        echo "  3. Deploy with: ./scripts/deploy.sh"
    else
        echo "  1. Fix the failed validation checks above"
        echo "  2. Run validation again: ./scripts/validate.sh"
        echo "  3. Initialize repository when all checks pass"
    fi
    echo
}

# Main execution
main() {
    echo "=============================================="
    echo "🔍 NumberOne OWU Repository Validation"
    echo "=============================================="
    echo
    
    cd "$PROJECT_ROOT"
    
    validate_structure
    validate_executables
    validate_docker_configs
    validate_python_syntax
    validate_environment_template
    validate_documentation
    validate_security
    validate_completeness
    show_validation_summary
    
    # Exit with error code if any checks failed
    if [ $FAILED_CHECKS -gt 0 ]; then
        exit 1
    fi
}

# Run main function
main "$@"
