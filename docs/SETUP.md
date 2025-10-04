# 🚀 NumberOne OWU - Complete Setup Guide

## Prerequisites

### System Requirements

**Minimum Requirements:**
- **OS**: Linux, macOS, or Windows with WSL2
- **RAM**: 16 GB (32 GB recommended)
- **Storage**: 100 GB free space
- **CPU**: 4+ cores (8+ recommended)
- **Network**: Stable internet connection

**Recommended Requirements:**
- **RAM**: 32 GB or more
- **GPU**: NVIDIA GPU with 8+ GB VRAM (optional but recommended)
- **Storage**: SSD with 200+ GB free space
- **CPU**: 8+ cores with high single-thread performance

### Software Dependencies

**Required:**
- **Docker**: Version 20.10 or later
- **Docker Compose**: Version 2.0 or later
- **Git**: For repository management

**Optional:**
- **NVIDIA Docker**: For GPU acceleration
- **Make**: For build automation

## 🔧 Installation

### 1. Clone Repository

```bash
# Clone the repository
git clone https://github.com/yourusername/NumberOne_OWU.git
cd NumberOne_OWU

# Make scripts executable
chmod +x scripts/*.sh
```

### 2. Environment Configuration

```bash
# Copy environment template
cp .env.example .env

# Edit configuration (see Configuration section below)
nano .env
```

### 3. Quick Start Deployment

```bash
# One-command deployment
./scripts/deploy.sh

# Or manually with Docker Compose
cd docker
docker-compose up -d
```

### 4. Verify Installation

```bash
# Check service status
docker-compose ps

# View logs
docker-compose logs -f

# Test services
curl http://localhost:3000  # Open WebUI
curl http://localhost:3003  # Langfuse
curl http://localhost:6333/dashboard  # Qdrant
```

## ⚙️ Configuration

### Environment Variables

Edit `.env` file with your specific settings:

```bash
# =============================================================================
# API Keys (Optional - for cloud models)
# =============================================================================

# Perplexity API for web search
PERPLEXITY_API_KEY=your_perplexity_api_key_here

# Anthropic Claude API
ANTHROPIC_API_KEY=your_anthropic_api_key_here

# OpenAI API
OPENAI_API_KEY=your_openai_api_key_here

# =============================================================================
# Core Configuration
# =============================================================================

# Memory system user identifier
MEM0_USER=your_username

# Number of messages before storing to memory
MEM0_STORE_CYCLES=3

# Langfuse tracking keys (generate random strings)
LANGFUSE_SECRET=your-secret-key-32-chars-minimum
LANGFUSE_SALT=your-salt-16-chars-minimum

# WebUI customization
WEBUI_NAME=NumberOne OWU
WEBUI_SECRET_KEY=your-webui-secret-key

# =============================================================================
# Performance Settings
# =============================================================================

# How long to keep models in memory
OLLAMA_KEEP_ALIVE=5m

# Enable features
ENABLE_RAG_HYBRID_SEARCH=true
ENABLE_RAG_WEB_LOADER=true
```

### GPU Configuration (Optional)

For NVIDIA GPU acceleration:

```bash
# Install NVIDIA Docker
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# Verify GPU access
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
```

## 🚀 First Time Setup

### 1. Access Open WebUI

1. Navigate to http://localhost:3000
2. Create your admin account (first user becomes admin)
3. Complete the initial setup wizard

### 2. Download AI Models

```bash
# Connect to Ollama container
docker exec -it numberone-ollama ollama pull qwen3:8b
docker exec -it numberone-ollama ollama pull gemma3:4b
docker exec -it numberone-ollama ollama pull phi4:14b
docker exec -it numberone-ollama ollama pull codellama:13b
docker exec -it numberone-ollama ollama pull qwen2.5:7b
docker exec -it numberone-ollama ollama pull nomic-embed-text:latest

# Or use the automated script
./scripts/download-models.sh
```

### 3. Configure Pipelines

1. Go to **Admin Panel** → **Settings** → **Pipelines**
2. Verify pipelines are loaded:
   - ✅ Memory Filter (Mem0)
   - ✅ Perplexity Search
   - ✅ Langfuse Tracking
3. Configure pipeline settings via the **Valves** interface

### 4. Setup Langfuse Tracking

1. Navigate to http://localhost:3003
2. Create your Langfuse account
3. Generate API keys in **Settings** → **API Keys**
4. Update `.env` with your Langfuse keys:
   ```bash
   LANGFUSE_SECRET_KEY=sk-lf-your-secret-key
   LANGFUSE_PUBLIC_KEY=pk-lf-your-public-key
   ```
5. Restart the pipelines container:
   ```bash
   docker-compose restart pipelines
   ```

### 5. Test Memory System

1. Start a new chat in Open WebUI
2. Send 3 test messages to trigger memory storage
3. Start a new conversation and ask "What do you remember about me?"
4. Verify memories are working

### 6. Test Web Search

1. Ask a question about current events: "What's the latest news about AI?"
2. Or use explicit search: "search: latest developments in quantum computing"
3. Verify search results include citations

## 🔧 Advanced Configuration

### Custom Model Addition

```bash
# Add a custom model to Ollama
docker exec -it numberone-ollama ollama pull your-custom-model:latest

# Verify it's available
docker exec -it numberone-ollama ollama list
```

### Pipeline Customization

Create custom pipelines in the `pipelines/` directory:

```python
# pipelines/custom_pipeline.py
class Pipeline:
    def __init__(self):
        self.type = "filter"
        self.name = "Custom Pipeline"
    
    async def inlet(self, body: dict, user: dict = None) -> dict:
        # Process incoming messages
        return body
    
    async def outlet(self, body: dict, user: dict = None) -> dict:
        # Process outgoing responses
        return body
```

### Resource Limits

Adjust Docker resource limits in `docker-compose.yml`:

```yaml
services:
  ollama:
    deploy:
      resources:
        limits:
          memory: 16G
          cpus: '8'
        reservations:
          memory: 8G
          cpus: '4'
```

## 🔍 Troubleshooting

### Common Issues

**1. Services Not Starting**
```bash
# Check Docker status
sudo systemctl status docker

# Check logs
docker-compose logs servicename

# Restart services
docker-compose restart
```

**2. Models Not Loading**
```bash
# Check Ollama status
docker exec -it numberone-ollama ollama list

# Check available space
df -h

# Manually pull models
docker exec -it numberone-ollama ollama pull qwen2.5:7b
```

**3. Memory Pipeline Not Working**
```bash
# Check Qdrant connection
curl http://localhost:6333/health

# Check pipeline logs
docker-compose logs pipelines

# Verify Mem0 installation
docker exec -it numberone-pipelines pip list | grep mem0
```

**4. Search Not Working**
```bash
# Verify Perplexity API key
echo $PERPLEXITY_API_KEY

# Test API connection
curl -H "Authorization: Bearer $PERPLEXITY_API_KEY" \
     https://api.perplexity.ai/chat/completions
```

**5. Langfuse Not Tracking**
```bash
# Check Langfuse service
curl http://localhost:3003/api/public/health

# Verify API keys in pipeline
docker-compose logs pipelines | grep langfuse
```

### Performance Optimization

**1. Memory Usage**
```bash
# Monitor memory usage
docker stats

# Adjust model keep-alive
# In .env: OLLAMA_KEEP_ALIVE=1m  # Shorter for less memory usage
```

**2. Response Speed**
```bash
# Use smaller models for faster responses
# qwen2.5:7b instead of phi4:14b for general tasks

# Enable GPU acceleration (if available)
# Ensure NVIDIA Docker is properly configured
```

**3. Storage Management**
```bash
# Clean up unused Docker resources
docker system prune -a

# Monitor disk usage
du -sh docker/volumes/*

# Backup and clean old data
./scripts/backup.sh
```

### Health Checks

```bash
# Check all services
./scripts/health-check.sh

# Individual service checks
curl http://localhost:3000/health      # Open WebUI
curl http://localhost:3003/api/public/health  # Langfuse
curl http://localhost:6333/health      # Qdrant
curl http://localhost:11434/api/tags   # Ollama
curl http://localhost:9099/health      # Pipelines
```

## 🔄 Updates and Maintenance

### Updating the System

```bash
# Pull latest changes
git pull origin main

# Update containers
docker-compose pull
docker-compose up -d

# Update models
./scripts/update-models.sh
```

### Backup and Restore

```bash
# Create backup
./scripts/backup.sh

# Restore from backup
./scripts/restore.sh backup-2024-12-04.tar.gz
```

### Monitoring

```bash
# View system dashboard
open http://localhost:8080

# Monitor logs
docker-compose logs -f --tail=100

# Check resource usage
docker stats
```

## 📞 Support

### Getting Help

1. **Documentation**: Check the `docs/` directory
2. **GitHub Issues**: Report bugs and request features
3. **Discussions**: Community support and ideas
4. **Logs**: Always include relevant logs when reporting issues

### Useful Commands

```bash
# Quick status check
docker-compose ps

# View all logs
docker-compose logs

# Restart everything
docker-compose restart

# Clean restart
docker-compose down && docker-compose up -d

# Emergency stop
docker-compose down
```

### Log Locations

- **Open WebUI**: `docker-compose logs open-webui`
- **Ollama**: `docker-compose logs ollama`
- **Pipelines**: `docker-compose logs pipelines`
- **Langfuse**: `docker-compose logs langfuse`
- **Qdrant**: `docker-compose logs qdrant`

This setup guide should get you up and running with NumberOne OWU. For additional help, refer to the other documentation files or open an issue on GitHub.
