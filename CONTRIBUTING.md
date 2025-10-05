# 🤝 Contributing to NumberOne OWU

Thank you for your interest in contributing to NumberOne OWU! This guide will help you get started.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Contributing Workflow](#contributing-workflow)
- [Code Style Guidelines](#code-style-guidelines)
- [Testing Guidelines](#testing-guidelines)
- [Documentation Guidelines](#documentation-guidelines)
- [Reporting Issues](#reporting-issues)
- [Pull Request Process](#pull-request-process)
- [Community](#community)

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive environment. We expect all contributors to:
- Be respectful and considerate
- Accept constructive criticism gracefully
- Focus on what's best for the community
- Show empathy towards other community members

### Unacceptable Behavior

- Harassment, trolling, or discriminatory language
- Personal attacks or insults
- Publishing others' private information
- Other unprofessional conduct

## Getting Started

### Prerequisites

Before you begin, ensure you have:
- **Git**: Version control
- **Docker**: 20.10+ and Docker Compose 2.0+
- **Python**: 3.10+ (for pipeline development)
- **Code Editor**: VS Code, PyCharm, or your preferred editor
- **GitHub Account**: For submitting contributions

### First-Time Contributors

New to open source? Here's how to get started:

1. **Find an Issue**: Look for issues tagged `good-first-issue` or `help-wanted`
2. **Ask Questions**: Comment on the issue to express interest
3. **Start Small**: Begin with documentation or minor bug fixes
4. **Learn**: Read existing code and documentation

## Development Setup

### 1. Fork and Clone

```bash
# Fork the repository on GitHub, then clone your fork
git clone https://github.com/YOUR-USERNAME/NumberOne_OWU.git
cd NumberOne_OWU

# Add upstream remote
git remote add upstream https://github.com/bailey-caldwell-sb/NumberOne_OWU.git

# Verify remotes
git remote -v
```

### 2. Set Up Development Environment

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your development settings
# Use test API keys or leave optional services blank

# Start development stack
./scripts/dev.sh start

# Alternatively, use Docker Compose directly
docker-compose -f docker/docker-compose.dev.yml up -d
```

### 3. Verify Installation

```bash
# Check all services are running
docker-compose ps

# Test Open WebUI
curl http://localhost:3000/health

# Test Ollama
curl http://localhost:11434/api/tags

# Test Pipelines
curl http://localhost:9099/health
```

### 4. Development Tools Setup

**Python Environment** (for pipeline development):
```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install development dependencies
pip install -r requirements-dev.txt

# Install pre-commit hooks (optional)
pre-commit install
```

**Editor Setup** (VS Code example):
```json
// .vscode/settings.json
{
  "python.linting.enabled": true,
  "python.linting.pylintEnabled": false,
  "python.linting.flake8Enabled": true,
  "python.formatting.provider": "black",
  "editor.formatOnSave": true
}
```

## Contributing Workflow

### Branch Strategy

```bash
# Always work on a feature branch
git checkout -b feature/your-feature-name

# Keep your branch up to date
git fetch upstream
git rebase upstream/main

# Push your branch
git push origin feature/your-feature-name
```

### Branch Naming Convention

- `feature/` - New features (e.g., `feature/add-redis-cache`)
- `fix/` - Bug fixes (e.g., `fix/memory-leak-pipelines`)
- `docs/` - Documentation (e.g., `docs/improve-setup-guide`)
- `refactor/` - Code refactoring (e.g., `refactor/pipeline-structure`)
- `test/` - Adding tests (e.g., `test/add-pipeline-tests`)
- `chore/` - Maintenance tasks (e.g., `chore/update-dependencies`)

### Commit Message Guidelines

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, no logic change)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples**:
```bash
feat(pipelines): add Redis caching for memory queries

Implement Redis-based caching layer for frequently accessed
memories to reduce Qdrant query load and improve response times.

Closes #123
```

```bash
fix(docker): resolve Qdrant connection timeout on startup

Add health check retry logic and increase startup grace period
for Qdrant service to prevent pipeline initialization failures.

Fixes #456
```

## Code Style Guidelines

### Python (Pipelines)

**PEP 8 Compliance**:
```python
# Good: Clear, descriptive names
def retrieve_memories_from_qdrant(user_id: str, query: str) -> List[Dict]:
    """Retrieve relevant memories for a user query."""
    pass

# Bad: Unclear, abbreviated names
def get_mem(u, q):
    pass
```

**Type Hints**:
```python
from typing import List, Dict, Optional

def process_message(
    message: str,
    user_id: Optional[str] = None,
    max_tokens: int = 1000
) -> Dict[str, Any]:
    """Process a user message with optional user context."""
    pass
```

**Formatting with Black**:
```bash
# Format all Python files
black pipelines/

# Check formatting without changes
black --check pipelines/
```

**Linting with Flake8**:
```bash
# Run linter
flake8 pipelines/ --max-line-length=88 --extend-ignore=E203
```

**Docstrings** (Google Style):
```python
def add_memory(data: str, user_id: str) -> bool:
    """Store a new memory for a user.

    Args:
        data: The memory content to store
        user_id: Unique identifier for the user

    Returns:
        True if memory was stored successfully, False otherwise

    Raises:
        ConnectionError: If unable to connect to Qdrant
        ValueError: If data is empty or user_id is invalid
    """
    pass
```

### Shell Scripts

**ShellCheck Compliance**:
```bash
#!/usr/bin/env bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Good: Quoted variables
readonly SERVICE_NAME="numberone-ollama"
docker exec "${SERVICE_NAME}" ollama list

# Bad: Unquoted variables (can break with spaces)
docker exec $SERVICE_NAME ollama list
```

**Error Handling**:
```bash
# Check command success
if ! docker-compose ps >/dev/null 2>&1; then
    echo "Error: Docker Compose not running" >&2
    exit 1
fi

# Use trap for cleanup
cleanup() {
    echo "Cleaning up..."
    docker-compose down
}
trap cleanup EXIT
```

### Docker & YAML

**Docker Compose**:
```yaml
# Use consistent formatting
services:
  service-name:
    image: imagename:tag
    container_name: project-servicename
    restart: unless-stopped
    networks:
      - project-network
    ports:
      - "external:internal"
    environment:
      - KEY=value
    depends_on:
      dependency:
        condition: service_healthy
```

### Documentation (Markdown)

**Structure**:
- Use clear headings (`#`, `##`, `###`)
- Include code blocks with language tags
- Add examples for clarity
- Link to related documentation

**Code Blocks**:
````markdown
```bash
# Good: Specify language for syntax highlighting
docker-compose up -d
```

```
Bad: No language specified
docker-compose up -d
```
````

## Testing Guidelines

### Manual Testing

**Before Submitting a PR**:
```bash
# 1. Start fresh environment
docker-compose down -v
docker-compose up -d

# 2. Test basic functionality
curl http://localhost:3000/health
curl http://localhost:11434/api/tags

# 3. Test your specific changes
# (Run relevant commands for your feature)

# 4. Check logs for errors
docker-compose logs | grep -i error
```

### Pipeline Testing

**Create Test File**:
```python
# tests/test_memory_pipeline.py
import pytest
from pipelines.mem0_memory_filter import Pipeline

def test_pipeline_initialization():
    """Test pipeline initializes correctly."""
    pipeline = Pipeline()
    assert pipeline.name == "Memory Filter"
    assert pipeline.type == "filter"

def test_memory_retrieval():
    """Test memory retrieval from Qdrant."""
    # Add your test logic
    pass
```

**Run Tests**:
```bash
# Install pytest
pip install pytest pytest-asyncio

# Run tests
pytest tests/ -v

# Run with coverage
pytest tests/ --cov=pipelines --cov-report=html
```

### Integration Testing

**Test Docker Stack**:
```bash
# Run deployment script
./scripts/deploy.sh

# Wait for services to be healthy
sleep 30

# Test service connectivity
docker exec numberone-pipelines curl http://qdrant:6333/health
docker exec numberone-openwebui curl http://ollama:11434/api/tags

# Test end-to-end flow
# (Manual chat test in Open WebUI)
```

## Documentation Guidelines

### What to Document

**Required for New Features**:
1. **README.md**: Update feature list if applicable
2. **CHANGELOG.md**: Add entry under "Unreleased"
3. **API Docs**: Document new endpoints/functions
4. **Setup Guides**: Add configuration steps
5. **Troubleshooting**: Add common issues

**Code Documentation**:
- All public functions need docstrings
- Complex logic needs inline comments
- Configuration options need descriptions

### Documentation Structure

**For New Files**:
```python
"""
title: Feature Name
author: Your Name
date: YYYY-MM-DD
version: 1.0
license: MIT
description: Brief description of the feature
requirements: package1, package2, package3
"""
```

## Reporting Issues

### Before Creating an Issue

1. **Search Existing Issues**: Check if it's already reported
2. **Verify It's a Bug**: Test on a clean installation
3. **Collect Information**: Logs, system info, steps to reproduce

### Issue Templates

**Bug Report**:
```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce:
1. Go to '...'
2. Click on '....'
3. See error

**Expected behavior**
What you expected to happen.

**Environment**
- OS: [e.g., Ubuntu 22.04]
- Docker version: [e.g., 20.10.21]
- NumberOne OWU version: [e.g., 1.1.0]

**Logs**
```
Paste relevant logs here
```

**Feature Request**:
```markdown
**Feature Description**
Clear description of the feature.

**Use Case**
Why is this feature needed?

**Proposed Solution**
How you envision this working.

**Alternatives Considered**
Other approaches you've thought about.
```

## Pull Request Process

### 1. Pre-Submit Checklist

Before creating a PR, ensure:

- [ ] Code follows style guidelines
- [ ] All tests pass (if applicable)
- [ ] Documentation is updated
- [ ] CHANGELOG.md is updated
- [ ] Commit messages follow convention
- [ ] Branch is up to date with main
- [ ] No merge conflicts

### 2. Create Pull Request

**PR Title Format**:
```
<type>(<scope>): Brief description

Examples:
feat(pipelines): Add Redis caching layer
fix(docker): Resolve Qdrant startup timeout
docs(architecture): Add deployment diagrams
```

**PR Description Template**:
```markdown
## Description
Brief description of changes.

## Motivation
Why is this change needed?

## Changes Made
- Change 1
- Change 2
- Change 3

## Testing
How was this tested?

## Screenshots (if applicable)
Add screenshots for UI changes.

## Related Issues
Closes #123
Relates to #456

## Checklist
- [ ] Code follows style guidelines
- [ ] Documentation updated
- [ ] Tests added/updated
- [ ] CHANGELOG.md updated
```

### 3. Review Process

**What to Expect**:
1. Maintainers will review within 3-7 days
2. You may receive feedback or change requests
3. Address feedback and push updates
4. Once approved, your PR will be merged

**Responding to Feedback**:
```bash
# Make requested changes
git add .
git commit -m "fix: address review feedback"

# Push updates
git push origin feature/your-feature-name

# PR automatically updates
```

### 4. After Merge

```bash
# Update your local main
git checkout main
git pull upstream main

# Delete feature branch
git branch -d feature/your-feature-name
git push origin --delete feature/your-feature-name
```

## Community

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and ideas
- **Pull Requests**: Code contributions and reviews

### Getting Help

If you're stuck:
1. Check the [documentation](docs/)
2. Search [existing issues](https://github.com/bailey-caldwell-sb/NumberOne_OWU/issues)
3. Ask in [GitHub Discussions](https://github.com/bailey-caldwell-sb/NumberOne_OWU/discussions)
4. Create a new issue with detailed information

### Recognition

Contributors are recognized in:
- CHANGELOG.md for their contributions
- GitHub Contributors page
- Release notes for significant features

## Development Tips

### Quick Commands

```bash
# Restart specific service after code changes
docker-compose restart pipelines

# View logs in real-time
docker-compose logs -f pipelines

# Execute commands in container
docker exec -it numberone-pipelines bash

# Clean and restart
docker-compose down -v && docker-compose up -d
```

### Common Development Tasks

**Adding a New Pipeline**:
1. Create file in `pipelines/` directory
2. Implement `Pipeline` class with `inlet`/`outlet` methods
3. Add documentation header
4. Test in development environment
5. Update documentation

**Modifying Docker Compose**:
1. Edit `docker/docker-compose.yml`
2. Validate with: `docker-compose config`
3. Test changes: `docker-compose up -d --force-recreate service-name`
4. Document in CHANGELOG.md

**Updating Documentation**:
1. Edit relevant `.md` files in `docs/`
2. Preview locally (use VS Code Markdown preview)
3. Check links and formatting
4. Commit with `docs:` prefix

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to NumberOne OWU! Your efforts help make this project better for everyone. 🚀
