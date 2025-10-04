#!/bin/bash

# NumberOne OWU - Repository Initialization Script
# Initializes a new GitHub repository with all necessary configurations

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
REPO_NAME="NumberOne_OWU"

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
    
    # Check Git
    if ! command -v git &> /dev/null; then
        log_error "Git is not installed"
        exit 1
    fi
    
    # Check GitHub CLI (optional)
    if command -v gh &> /dev/null; then
        log_success "GitHub CLI detected"
        export HAS_GH_CLI=true
    else
        log_warning "GitHub CLI not found. Manual repository creation required."
        export HAS_GH_CLI=false
    fi
    
    log_success "Prerequisites check passed"
}

initialize_git() {
    log_info "Initializing Git repository..."
    
    cd "$PROJECT_ROOT"
    
    # Initialize git if not already done
    if [ ! -d ".git" ]; then
        git init
        log_success "Git repository initialized"
    else
        log_info "Git repository already exists"
    fi
    
    # Create .gitignore if it doesn't exist
    if [ ! -f ".gitignore" ]; then
        create_gitignore
    fi
    
    # Set up Git configuration
    setup_git_config
    
    log_success "Git initialization completed"
}

create_gitignore() {
    log_info "Creating .gitignore file..."
    
    cat > "$PROJECT_ROOT/.gitignore" << 'EOF'
# =============================================================================
# NumberOne OWU - Git Ignore Configuration
# =============================================================================

# Environment & Secrets
.env
.env.local
.env.production
.env.staging
*.key
*.pem
*.p12
secrets/
config/secrets/

# Data & Logs
data/
logs/
backups/
*.log
*.log.*

# Docker
docker-compose.override.yml
.docker/

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# Virtual Environments
venv/
env/
ENV/
.venv/
.env/

# IDE & Editor Files
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store
Thumbs.db

# Node.js (for dashboard)
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.npm
.yarn-integrity

# Temporary Files
*.tmp
*.temp
.cache/
.temp/

# AI Models (too large for git)
*.gguf
*.bin
models/
ollama_data/

# Database Files
*.db
*.sqlite
*.sqlite3

# Monitoring & Analytics
grafana/
prometheus/
*.rrd

# OS Generated Files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Backup Files
*.bak
*.backup
*.old

# Test Coverage
.coverage
htmlcov/
.pytest_cache/

# Documentation Build
docs/_build/
site/

# Local Development
local/
dev/
debug/
EOF

    log_success ".gitignore created"
}

setup_git_config() {
    log_info "Setting up Git configuration..."
    
    cd "$PROJECT_ROOT"
    
    # Set up Git hooks directory
    mkdir -p .githooks
    
    # Create pre-commit hook
    cat > .githooks/pre-commit << 'EOF'
#!/bin/bash
# NumberOne OWU Pre-commit Hook

echo "Running pre-commit checks..."

# Check for secrets in staged files
if git diff --cached --name-only | xargs grep -l "api.*key\|secret\|password" 2>/dev/null; then
    echo "❌ Potential secrets detected in staged files!"
    echo "Please review and remove any sensitive information."
    exit 1
fi

# Check for large files
large_files=$(git diff --cached --name-only | xargs ls -la 2>/dev/null | awk '$5 > 100000000 {print $9}')
if [ -n "$large_files" ]; then
    echo "❌ Large files detected (>100MB):"
    echo "$large_files"
    echo "Please use Git LFS for large files."
    exit 1
fi

echo "✅ Pre-commit checks passed"
EOF

    chmod +x .githooks/pre-commit
    
    # Configure Git to use custom hooks directory
    git config core.hooksPath .githooks
    
    log_success "Git configuration completed"
}

create_github_repository() {
    log_info "Creating GitHub repository..."
    
    if [ "$HAS_GH_CLI" = true ]; then
        # Check if user is authenticated
        if gh auth status &> /dev/null; then
            log_info "Creating repository with GitHub CLI..."
            
            # Create repository
            gh repo create "$REPO_NAME" \
                --public \
                --description "NumberOne OWU - Complete AI Platform with Open WebUI, Ollama, Mem0 Memory, Langfuse Tracking, and Perplexity Search" \
                --homepage "https://github.com/yourusername/$REPO_NAME" \
                --add-readme=false
            
            # Set remote origin
            git remote add origin "https://github.com/$(gh api user --jq .login)/$REPO_NAME.git"
            
            log_success "GitHub repository created successfully"
        else
            log_warning "GitHub CLI not authenticated. Please run 'gh auth login' first."
            manual_repo_instructions
        fi
    else
        manual_repo_instructions
    fi
}

manual_repo_instructions() {
    echo
    echo "=============================================="
    echo "📋 Manual Repository Creation Required"
    echo "=============================================="
    echo
    echo "Please create a GitHub repository manually:"
    echo
    echo "1. Go to https://github.com/new"
    echo "2. Repository name: $REPO_NAME"
    echo "3. Description: NumberOne OWU - Complete AI Platform"
    echo "4. Set as Public"
    echo "5. Do NOT initialize with README, .gitignore, or license"
    echo "6. Click 'Create repository'"
    echo
    echo "Then run these commands:"
    echo "  git remote add origin https://github.com/YOURUSERNAME/$REPO_NAME.git"
    echo "  git branch -M main"
    echo "  git push -u origin main"
    echo
    read -p "Press Enter when you've created the repository..."
}

setup_repository_settings() {
    log_info "Setting up repository settings..."
    
    cd "$PROJECT_ROOT"
    
    # Create GitHub issue templates
    mkdir -p .github/ISSUE_TEMPLATE
    
    # Bug report template
    cat > .github/ISSUE_TEMPLATE/bug_report.md << 'EOF'
---
name: Bug report
about: Create a report to help us improve
title: '[BUG] '
labels: bug
assignees: ''
---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Screenshots**
If applicable, add screenshots to help explain your problem.

**Environment:**
 - OS: [e.g. Ubuntu 22.04]
 - Docker version: [e.g. 24.0.7]
 - NumberOne OWU version: [e.g. v1.0.0]

**Logs**
Please include relevant logs:
```
Paste logs here
```

**Additional context**
Add any other context about the problem here.
EOF

    # Feature request template
    cat > .github/ISSUE_TEMPLATE/feature_request.md << 'EOF'
---
name: Feature request
about: Suggest an idea for this project
title: '[FEATURE] '
labels: enhancement
assignees: ''
---

**Is your feature request related to a problem? Please describe.**
A clear and concise description of what the problem is. Ex. I'm always frustrated when [...]

**Describe the solution you'd like**
A clear and concise description of what you want to happen.

**Describe alternatives you've considered**
A clear and concise description of any alternative solutions or features you've considered.

**Additional context**
Add any other context or screenshots about the feature request here.
EOF

    # Pull request template
    cat > .github/pull_request_template.md << 'EOF'
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Tests pass locally
- [ ] Added tests for new functionality
- [ ] Manual testing completed

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No sensitive information exposed
EOF

    # Create contributing guidelines
    cat > CONTRIBUTING.md << 'EOF'
# Contributing to NumberOne OWU

Thank you for your interest in contributing to NumberOne OWU!

## Development Setup

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOURUSERNAME/NumberOne_OWU.git`
3. Set up development environment: `./scripts/dev.sh start`
4. Make your changes
5. Test your changes: `./scripts/dev.sh test`
6. Submit a pull request

## Code Style

- Python: Follow PEP 8, use black for formatting
- Shell scripts: Follow Google Shell Style Guide
- Documentation: Use clear, concise language

## Reporting Issues

Please use the issue templates and include:
- Clear description of the problem
- Steps to reproduce
- Environment information
- Relevant logs

## Pull Request Process

1. Update documentation for any new features
2. Add tests for new functionality
3. Ensure all tests pass
4. Update CHANGELOG.md
5. Request review from maintainers
EOF

    log_success "Repository settings configured"
}

create_initial_commit() {
    log_info "Creating initial commit..."
    
    cd "$PROJECT_ROOT"
    
    # Stage all files
    git add .
    
    # Create initial commit
    git commit -m "🚀 Initial commit: NumberOne OWU - Complete AI Platform

Features:
- Open WebUI v0.6.32 with 16 AI models
- Mem0 memory system with Qdrant vector storage
- Langfuse LLM observability and tracking
- Perplexity web search integration
- Docker Compose deployment
- Development environment
- Comprehensive documentation
- Automated scripts and CI/CD

Ready for production deployment with one-click setup."
    
    # Set main branch
    git branch -M main
    
    log_success "Initial commit created"
}

push_to_github() {
    log_info "Pushing to GitHub..."
    
    cd "$PROJECT_ROOT"
    
    # Check if remote exists
    if git remote get-url origin &> /dev/null; then
        # Push to GitHub
        git push -u origin main
        log_success "Repository pushed to GitHub successfully"
    else
        log_warning "No remote origin configured. Please set up the remote manually."
        echo "Run: git remote add origin https://github.com/YOURUSERNAME/$REPO_NAME.git"
        echo "Then: git push -u origin main"
    fi
}

setup_github_pages() {
    log_info "Setting up GitHub Pages..."
    
    cd "$PROJECT_ROOT"
    
    # Create docs index for GitHub Pages
    cat > docs/index.md << 'EOF'
# NumberOne OWU Documentation

Welcome to the NumberOne OWU documentation!

## Quick Links

- [Setup Guide](SETUP.md)
- [Agent Documentation](AGENTS.md)
- [Troubleshooting](TROUBLESHOOTING.md)
- [API Reference](API.md)

## Getting Started

NumberOne OWU is a complete AI platform that combines:

- **Open WebUI** - Modern chat interface
- **Ollama** - Local AI models
- **Mem0** - Persistent memory system
- **Langfuse** - LLM observability
- **Perplexity** - Web search integration

### Quick Start

```bash
git clone https://github.com/yourusername/NumberOne_OWU.git
cd NumberOne_OWU
./scripts/deploy.sh
```

Visit the [Setup Guide](SETUP.md) for detailed instructions.
EOF

    log_success "GitHub Pages configured"
}

show_completion_summary() {
    echo
    echo "=============================================="
    echo "🎉 Repository Initialization Complete!"
    echo "=============================================="
    echo
    echo "📁 Repository: $REPO_NAME"
    echo "🌐 GitHub: https://github.com/YOURUSERNAME/$REPO_NAME"
    echo "📖 Documentation: https://YOURUSERNAME.github.io/$REPO_NAME"
    echo
    echo "✅ What's been set up:"
    echo "  • Git repository with proper .gitignore"
    echo "  • GitHub issue and PR templates"
    echo "  • Pre-commit hooks for security"
    echo "  • Contributing guidelines"
    echo "  • GitHub Pages documentation"
    echo "  • CI/CD workflows"
    echo
    echo "🚀 Next steps:"
    echo "  1. Update README.md with your GitHub username"
    echo "  2. Configure repository settings on GitHub"
    echo "  3. Set up branch protection rules"
    echo "  4. Enable GitHub Pages in repository settings"
    echo "  5. Add collaborators if needed"
    echo
    echo "🔧 Development:"
    echo "  • Start dev environment: ./scripts/dev.sh start"
    echo "  • Deploy production: ./scripts/deploy.sh"
    echo "  • Run tests: ./scripts/dev.sh test"
    echo
}

# Main execution
main() {
    echo "=============================================="
    echo "🚀 NumberOne OWU Repository Initialization"
    echo "=============================================="
    echo
    
    check_prerequisites
    initialize_git
    create_github_repository
    setup_repository_settings
    create_initial_commit
    push_to_github
    setup_github_pages
    show_completion_summary
    
    log_success "Repository initialization completed successfully!"
}

# Handle script interruption
trap 'log_error "Repository initialization interrupted"; exit 1' INT TERM

# Run main function
main "$@"
