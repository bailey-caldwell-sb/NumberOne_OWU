# 🍎 NumberOne OWU - macOS Setup Guide

## Overview

This guide provides macOS-specific instructions for setting up and running NumberOne OWU. While the platform is fully compatible with macOS, there are some platform-specific considerations.

## ⚠️ Important macOS Considerations

### GPU Support
**macOS does NOT support NVIDIA GPU acceleration** due to:
- No NVIDIA drivers for modern macOS
- Docker Desktop for Mac doesn't support GPU passthrough
- Apple Silicon (M1/M2/M3) has no CUDA support

**Impact**: All AI models will run on CPU, which is slower but functional.

### Performance Expectations

**Intel Mac** (CPU-only):
- Ultra-fast models (0.5B-1B): 2-5 seconds per response
- 7B models: 10-30 seconds per response
- 13B+ models: 30-60+ seconds per response

**Apple Silicon Mac** (M1/M2/M3):
- Better performance than Intel due to unified memory
- Ultra-fast models: 1-3 seconds per response
- 7B models: 5-15 seconds per response
- Performance via Rosetta 2 (Docker runs x86_64)

### Recommended Hardware

**Minimum**:
- Mac (2018 or newer)
- 16 GB RAM
- 100 GB free disk space
- macOS 12 (Monterey) or later

**Recommended**:
- Mac Studio / MacBook Pro (M1/M2/M3)
- 32 GB+ RAM
- 200 GB+ SSD storage
- macOS 13 (Ventura) or later

## Prerequisites

### 1. Install Homebrew

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Verify installation
brew --version
```

### 2. Install Docker Desktop for Mac

**Option A: Download from Docker**
1. Visit https://www.docker.com/products/docker-desktop/
2. Download Docker Desktop for Mac (Intel or Apple Silicon)
3. Install by dragging to Applications folder
4. Launch Docker Desktop
5. Follow the setup wizard

**Option B: Install via Homebrew**
```bash
# Install Docker Desktop
brew install --cask docker

# Launch Docker Desktop (first time)
open -a Docker
```

**Configure Docker Desktop**:
1. Open Docker Desktop
2. Go to **Settings** → **Resources**
3. Allocate resources:
   - **CPUs**: 6-8 cores (leave 2 for macOS)
   - **Memory**: 16-24 GB (for 32GB Mac)
   - **Swap**: 2 GB
   - **Disk**: 100 GB+

4. Go to **Settings** → **General**
5. Enable:
   - ✅ Start Docker Desktop when you log in
   - ✅ Use Docker Compose V2

6. Click **Apply & Restart**

### 3. Install Git

```bash
# Install Git via Homebrew
brew install git

# Verify installation
git --version
```

### 4. Verify Installation

```bash
# Check Docker
docker --version
# Expected: Docker version 24.0+ or later

# Check Docker Compose
docker compose version
# Expected: Docker Compose version v2.0+ or later

# Test Docker
docker run hello-world
# Should download and run successfully
```

## Installation

### Step 1: Clone Repository

```bash
# Choose installation directory
cd ~/Projects  # or your preferred location

# Clone repository
git clone https://github.com/bailey-caldwell-sb/NumberOne_OWU.git
cd NumberOne_OWU
```

### Step 2: Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit environment file
open -e .env  # Opens in TextEdit
# Or use your preferred editor:
# nano .env
# vim .env
# code .env  # VS Code
```

**Minimal Configuration** for macOS:
```bash
# Optional API Keys (can add later)
ANTHROPIC_API_KEY=
OPENAI_API_KEY=
PERPLEXITY_API_KEY=

# Security (CHANGE THESE!)
LANGFUSE_SECRET=$(openssl rand -hex 32)
LANGFUSE_SALT=$(openssl rand -hex 16)
WEBUI_SECRET_KEY=$(openssl rand -hex 32)

# PostgreSQL (CHANGE DEFAULT PASSWORD)
POSTGRES_PASSWORD=$(openssl rand -base64 24)
```

**Generate secure passwords**:
```bash
# Run these commands and copy output to .env
echo "LANGFUSE_SECRET=$(openssl rand -hex 32)"
echo "LANGFUSE_SALT=$(openssl rand -hex 16)"
echo "WEBUI_SECRET_KEY=$(openssl rand -hex 32)"
echo "POSTGRES_PASSWORD=$(openssl rand -base64 24)"
```

### Step 3: macOS-Specific Docker Compose Adjustments

The default `docker-compose.yml` includes GPU configuration that won't work on macOS. We need to comment it out:

```bash
# Create macOS-specific compose file
cp docker/docker-compose.yml docker/docker-compose.mac.yml

# Edit the file to remove GPU configuration
# We'll use the standard file but Docker will ignore GPU settings on macOS
```

**Note**: The deployment script will automatically detect macOS and skip GPU configuration.

### Step 4: Deploy

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Deploy using the deployment script
./scripts/deploy.sh
```

**What happens during deployment**:
1. ✅ Checks Docker is running
2. ✅ Creates necessary directories
3. ✅ Pulls Docker images (15-20 minutes first time)
4. ✅ Starts all services
5. ✅ Waits for services to be healthy
6. ⚠️ Skips GPU check (not available on macOS)
7. ✅ Downloads essential AI models (20-40 minutes)

**Total first-time setup**: 45-60 minutes

### Step 5: Verify Installation

```bash
# Check all services are running
docker compose -f docker/docker-compose.yml ps

# Expected output: All services should show "Up" status
```

Access services:
- **Open WebUI**: http://localhost:3000
- **Langfuse**: http://localhost:3003
- **Qdrant Dashboard**: http://localhost:6333/dashboard
- **System Dashboard**: http://localhost:8080

### Step 6: Install Fast Models

For better performance on macOS, use the ultra-fast models:

```bash
# Install models optimized for CPU performance
./scripts/install-fast-models.sh
```

This installs:
- **qwen2.5:0.5b** (397 MB) - Fastest, instant responses
- **tinyllama** (637 MB) - Very fast, good for simple tasks
- **llama3.2:1b** (1.3 GB) - Best speed/quality balance

### Step 7: First-Time Setup

1. Open http://localhost:3000 in your browser
2. Create your admin account
3. Log in
4. Go to **Admin Panel** → **Settings** → **Models**
5. Select a fast model as default (recommended: **llama3.2:1b**)
6. Go to **Admin Panel** → **Pipelines**
7. Enable pipelines:
   - ✅ Memory Filter (Mem0)
   - ✅ Langfuse Tracking (optional)
   - ⚠️ Perplexity Search (requires API key)

## macOS-Specific Troubleshooting

### Docker Desktop Not Starting

**Problem**: Docker Desktop fails to start or crashes.

**Solutions**:
```bash
# Reset Docker Desktop
# 1. Quit Docker Desktop
# 2. From menu bar: Docker icon → Troubleshoot → Reset to factory defaults

# Or via command line:
rm -rf ~/Library/Group\ Containers/group.com.docker
rm -rf ~/Library/Containers/com.docker.docker
rm -rf ~/.docker

# Reinstall Docker Desktop
brew reinstall --cask docker
```

### Port Already in Use

**Problem**: "Port 3000 is already in use"

**Check what's using the port**:
```bash
# Find process using port
lsof -i :3000

# Kill process (replace PID)
kill -9 <PID>

# Or change port in docker-compose.yml
# Edit: ports: "3001:8080" instead of "3000:8080"
```

### Disk Space Issues

**Problem**: Docker running out of disk space.

```bash
# Check Docker disk usage
docker system df

# Clean up unused images and containers
docker system prune -a

# Increase Docker Desktop disk size:
# Docker Desktop → Settings → Resources → Disk image size → 150 GB

# Check macOS disk space
df -h
```

### Performance Issues

**Problem**: Very slow model responses.

**Solutions**:

1. **Use smaller models**:
```bash
# Remove large models
docker exec numberone-ollama ollama rm phi4:14b
docker exec numberone-ollama ollama rm codellama:13b

# Use fast models only
docker exec numberone-ollama ollama pull qwen2.5:0.5b
docker exec numberone-ollama ollama pull llama3.2:1b
```

2. **Increase Docker resources**:
   - Docker Desktop → Settings → Resources
   - Increase Memory to 20-24 GB
   - Increase CPUs to 8 cores

3. **Enable VirtioFS** (better file sharing):
   - Docker Desktop → Settings → General
   - Enable "VirtioFS accelerated directory sharing"
   - Restart Docker

4. **Reduce concurrent operations**:
   - Disable unnecessary pipelines
   - Set `OLLAMA_KEEP_ALIVE=10m` in `.env` (keeps models loaded)

### Services Won't Start

**Problem**: Some services show "Exited" status.

```bash
# Check logs for specific service
docker compose -f docker/docker-compose.yml logs ollama
docker compose -f docker/docker-compose.yml logs qdrant
docker compose -f docker/docker-compose.yml logs open-webui

# Restart specific service
docker compose -f docker/docker-compose.yml restart ollama

# Full restart
docker compose -f docker/docker-compose.yml down
docker compose -f docker/docker-compose.yml up -d
```

### Memory (Mem0) Issues

**Problem**: Memory pipeline not working.

```bash
# Check if Qdrant is running
docker compose -f docker/docker-compose.yml ps qdrant

# Check Qdrant health
curl http://localhost:6333/health

# Verify embedding model installed
docker exec numberone-ollama ollama list | grep nomic-embed

# Install if missing
docker exec numberone-ollama ollama pull nomic-embed-text:latest

# Restart pipelines
docker compose -f docker/docker-compose.yml restart pipelines
```

### Rosetta 2 Issues (Apple Silicon)

**Problem**: Docker containers failing on M1/M2/M3 Macs.

```bash
# Ensure Rosetta 2 is installed
softwareupdate --install-rosetta

# Enable Rosetta in Docker Desktop:
# Docker Desktop → Settings → General
# ✅ Use Rosetta for x86/amd64 emulation on Apple Silicon

# Restart Docker Desktop
```

## Performance Optimization for macOS

### 1. Model Selection Strategy

**For Quick Responses** (< 3 seconds):
```bash
# Use ultra-fast models
docker exec numberone-ollama ollama pull qwen2.5:0.5b
docker exec numberone-ollama ollama pull llama3.2:1b
```

**For Better Quality** (acceptable 5-15s latency):
```bash
# Use medium-sized models
docker exec numberone-ollama ollama pull qwen2.5:7b
docker exec numberone-ollama ollama pull gemma3:4b
```

**Avoid on macOS** (too slow):
- Models > 13B parameters
- Multiple concurrent large models

### 2. Docker Desktop Optimization

**File Sharing**:
```bash
# Docker Desktop → Settings → Resources → File Sharing
# Only share necessary directories:
# - /Users/yourusername/Projects/NumberOne_OWU
```

**Experimental Features**:
```bash
# Docker Desktop → Settings → Features in development
# Enable:
# ✅ Use new Virtualization framework
# ✅ VirtioFS accelerated directory sharing
```

### 3. Keep Models Loaded

Edit `.env`:
```bash
# Keep models in memory longer (reduces reload time)
OLLAMA_KEEP_ALIVE=10m  # or 15m for even better performance
```

### 4. Reduce Pipeline Overhead

Disable unused pipelines in Open WebUI:
- Admin → Pipelines
- Disable Langfuse if not needed
- Disable Perplexity if not using web search

## macOS-Specific Features

### Use macOS Native Tools

**Activity Monitor Integration**:
```bash
# Monitor Docker resource usage
open -a "Activity Monitor"
# Search for "Docker" or "com.docker"
```

**Quick Look for Logs**:
```bash
# Collect logs
mkdir ~/Desktop/numberone-logs
docker compose -f docker/docker-compose.yml logs > ~/Desktop/numberone-logs/all.log

# View with Quick Look
# Press Space on the file in Finder
```

### Spotlight Integration

```bash
# Make project easily accessible via Spotlight
# Add alias to your shell profile (~/.zshrc or ~/.bash_profile)
echo 'alias numberone="cd ~/Projects/NumberOne_OWU"' >> ~/.zshrc
source ~/.zshrc

# Now you can just type: numberone
```

### Automator Shortcuts

Create macOS shortcuts for common tasks:

**Start NumberOne OWU**:
1. Open Automator
2. New Document → Application
3. Add "Run Shell Script" action:
```bash
cd ~/Projects/NumberOne_OWU/docker
docker compose up -d
osascript -e 'display notification "NumberOne OWU started" with title "NumberOne OWU"'
```
4. Save as "Start NumberOne OWU.app"

**Stop NumberOne OWU**:
1. Same process, but use:
```bash
cd ~/Projects/NumberOne_OWU/docker
docker compose down
osascript -e 'display notification "NumberOne OWU stopped" with title "NumberOne OWU"'
```

## Maintenance

### Updates

```bash
# Pull latest changes
cd ~/Projects/NumberOne_OWU
git pull origin main

# Rebuild and restart
docker compose -f docker/docker-compose.yml down
docker compose -f docker/docker-compose.yml pull
docker compose -f docker/docker-compose.yml up -d --build
```

### Backups

```bash
# Create backup
./scripts/backup.sh

# Backups stored in: ./backups/
# Copy to external drive or cloud storage for safety
```

### Monitoring

```bash
# Check resource usage
docker stats

# Check service health
docker compose -f docker/docker-compose.yml ps

# View logs
docker compose -f docker/docker-compose.yml logs -f
```

## Uninstallation

### Complete Removal

```bash
# Stop and remove all containers
cd ~/Projects/NumberOne_OWU/docker
docker compose down -v

# Remove all data volumes
docker volume rm $(docker volume ls -q | grep numberone)

# Remove project directory
cd ~
rm -rf ~/Projects/NumberOne_OWU

# Optionally remove Docker Desktop
# Drag Docker from Applications to Trash
# Or: brew uninstall --cask docker
```

## Known Limitations on macOS

1. **No GPU Acceleration**: All inference runs on CPU
2. **Slower Performance**: 3-10x slower than GPU-accelerated Linux
3. **Docker Virtualization Overhead**: ~10-15% performance penalty
4. **No CUDA Support**: Can't use CUDA-optimized models
5. **Rosetta 2 on Apple Silicon**: Some performance impact

## Recommended Alternatives for Better Performance

If you need better performance on macOS:

1. **Use smaller models**: Stick to 0.5B-7B models
2. **Use cloud APIs**: OpenAI, Anthropic for production use
3. **Rent GPU server**: AWS, GCP for occasional heavy workloads
4. **Dual boot Linux**: If you have Intel Mac, dual boot for GPU support

## Getting Help

**macOS-Specific Issues**:
1. Check this guide first
2. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
3. Search [GitHub Issues](https://github.com/bailey-caldwell-sb/NumberOne_OWU/issues) with "macOS" tag
4. Create new issue with "macOS" label and system info

**System Information for Bug Reports**:
```bash
# Collect macOS system info
system_profiler SPHardwareDataType SPSoftwareDataType > ~/Desktop/mac-info.txt
docker version >> ~/Desktop/mac-info.txt
docker info >> ~/Desktop/mac-info.txt
```

## FAQ

**Q: Can I use my Mac's GPU?**
A: No, Docker Desktop for Mac doesn't support GPU passthrough, and modern macOS doesn't have NVIDIA drivers.

**Q: Will this work on M1/M2/M3 Macs?**
A: Yes, via Rosetta 2. Performance is good but not as fast as native ARM builds.

**Q: How much slower is macOS vs Linux with GPU?**
A: CPU-only Mac: 5-10x slower. Apple Silicon Mac: 3-5x slower than NVIDIA GPU.

**Q: Can I run this on older Macs?**
A: Yes, but 2018+ with 16GB+ RAM recommended. Older Macs will be very slow.

**Q: Does this drain my battery?**
A: Yes, AI inference is CPU-intensive. Use while plugged in for best results.

---

**Need more help?** Check the main [README.md](../README.md) and other documentation in [docs/](../docs/).
