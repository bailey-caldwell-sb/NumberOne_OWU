# ❓ NumberOne OWU - Frequently Asked Questions

## General Questions

### What is NumberOne OWU?

NumberOne OWU (Open WebUI) is a self-hosted, privacy-focused AI platform that combines Open WebUI with advanced features like persistent memory (Mem0), LLM observability (Langfuse), and web search capabilities (Perplexity). All models run locally on your infrastructure via Ollama.

### Why should I use NumberOne OWU instead of ChatGPT or other cloud AI services?

**Privacy & Control**:
- All data stays on your infrastructure
- No third-party data sharing
- Full control over AI models and settings

**Cost**:
- No per-token pricing after initial setup
- Unlimited usage with local models
- Optional cloud API integration when needed

**Customization**:
- Custom pipelines for specific workflows
- Persistent memory across conversations
- Extensible architecture

### Is this free to use?

Yes, NumberOne OWU is open-source (MIT License) and free to use. You only need:
- Hardware to run it (or cloud hosting costs)
- Optional API keys for external services (Perplexity, OpenAI, Anthropic)

### How does it compare to Open WebUI?

NumberOne OWU is built on Open WebUI and adds:
- **Mem0 Integration**: Persistent cross-conversation memory
- **Langfuse Tracking**: Comprehensive observability
- **Perplexity Search**: Real-time web search
- **Pre-configured Stack**: Docker Compose deployment
- **19 Models**: Curated model collection
- **Documentation**: Extensive guides and tutorials

## Installation & Setup

### What are the system requirements?

**Minimum** (for development/testing):
- CPU: 4 cores
- RAM: 16 GB
- Storage: 100 GB free space
- OS: Linux, macOS, or Windows with WSL2

**Recommended** (for production):
- CPU: 8+ cores
- RAM: 32 GB
- Storage: 200+ GB SSD
- GPU: NVIDIA GPU with 8+ GB VRAM

See [DEPLOYMENT.md](DEPLOYMENT.md#system-requirements) for details.

### Do I need a GPU?

**Not required**, but highly recommended:
- **Without GPU**: Models run on CPU, slower inference (10-30s per response)
- **With GPU**: Much faster inference (0.5-3s per response)

**Compatible GPUs**: NVIDIA GPUs with CUDA support (RTX 20/30/40 series, Tesla T4, etc.)

### How long does installation take?

- **Setup**: 5-10 minutes (cloning, configuration)
- **First deployment**: 30-60 minutes (downloading Docker images, models)
- **Subsequent starts**: 1-2 minutes (services starting)

### Can I run this on Windows?

Yes, using **Windows Subsystem for Linux 2 (WSL2)**:

1. Install WSL2 with Ubuntu
2. Install Docker Desktop for Windows
3. Enable WSL2 integration in Docker Desktop
4. Follow Linux installation instructions in WSL2

### Can I run this on a Mac?

Yes! Full macOS support with **Docker Desktop for Mac**:
- ✅ Works on both Intel and Apple Silicon (M1/M2/M3)
- ✅ All features functional
- ⚠️ GPU acceleration not available on macOS
- ⚠️ Slower inference (CPU-only, 3-10x slower than GPU)

**See detailed setup guide**: [MACOS_SETUP.md](MACOS_SETUP.md)

**Performance Tips for macOS**:
- Use ultra-fast models (qwen2.5:0.5b, llama3.2:1b)
- Allocate 20-24GB RAM to Docker Desktop
- Keep models loaded (`OLLAMA_KEEP_ALIVE=10m`)
- Apple Silicon performs better than Intel Macs

## Models & Performance

### Which models are included?

**19 models across different categories**:

**Ultra-Fast** (sub-second responses):
- qwen2.5:0.5b (397 MB)
- tinyllama (637 MB)
- llama3.2:1b (1.3 GB)

**General Purpose**:
- qwen2.5:7b, qwen3:8b
- gemma3:4b
- phi4:14b

**Code Specialized**:
- codellama:13b
- deepseek-coder

**Embedding**:
- nomic-embed-text

See [README.md](../README.md#local-models-ollama) for complete list.

### How do I add more models?

```bash
# List available models
docker exec numberone-ollama ollama list

# Pull a model
docker exec numberone-ollama ollama pull llama3.2:3b

# Remove a model
docker exec numberone-ollama ollama rm unused-model
```

Browse all available models at [ollama.com/library](https://ollama.com/library).

### How much disk space do models require?

**Storage by model size**:
- 0.5B-1B models: ~0.4-1.3 GB
- 3B-4B models: ~2-3 GB
- 7B-8B models: ~4-5 GB
- 13B-14B models: ~8-9 GB

**Total for all 19 models**: ~60-80 GB

### What's the difference between the ultra-fast models?

| Model | Size | Speed | Quality | Best For |
|-------|------|-------|---------|----------|
| qwen2.5:0.5b | 397 MB | 0.16s | Basic | Quick questions, prototyping |
| tinyllama | 637 MB | 0.3s | Moderate | Simple conversations |
| llama3.2:1b | 1.3 GB | 0.5s | Good | Best speed/quality balance |

### How fast are the responses?

**With GPU** (NVIDIA RTX 3090):
- Ultra-fast models: 0.1-0.5s
- 7B models: 0.5-2s
- 13B+ models: 2-5s

**Without GPU** (CPU only):
- Ultra-fast models: 2-5s
- 7B models: 10-30s
- 13B+ models: 30-60s+

Performance varies by hardware, model size, and prompt complexity.

### Can I use OpenAI/Anthropic models?

Yes! Add API keys to `.env`:

```bash
OPENAI_API_KEY=your_openai_key
ANTHROPIC_API_KEY=your_anthropic_key
```

These models will appear alongside local Ollama models in the UI.

## Features & Functionality

### What is the Memory (Mem0) feature?

**Mem0** provides persistent memory across conversations:
- Stores important facts about users
- Retrieves relevant context automatically
- Uses vector similarity search
- Isolated per user

**Example**:
- Conversation 1: "I live in New York and work as a software engineer"
- Conversation 2: "What's the weather like today?" → AI remembers you're in New York

### How do I enable/disable memory?

1. Navigate to **Open WebUI** → **Admin Panel** → **Pipelines**
2. Find "Memory Filter" pipeline
3. Toggle enable/disable
4. Configure settings (store cycles, user ID, etc.)

### What is Langfuse and do I need it?

**Langfuse** provides LLM observability:
- Tracks token usage
- Monitors response times
- Analyzes costs
- Stores conversation traces

**You don't need it**, but it's helpful for:
- Understanding usage patterns
- Debugging issues
- Optimizing performance
- Cost analysis (for cloud APIs)

### How does web search work?

**Perplexity integration**:
1. Add `PERPLEXITY_API_KEY` to `.env`
2. Enable Perplexity pipeline in Open WebUI
3. AI automatically triggers search when needed
4. Or explicitly request: "search: latest AI news"

**Cost**: Perplexity offers free tier with limited searches, paid plans for more.

### Can I generate images?

Yes! Configure image generation:

**DALL-E** (easiest):
1. Add `OPENAI_API_KEY` to `.env`
2. Enable image generation in Open WebUI settings

**Local generation** (free but complex):
- ComfyUI or Automatic1111 integration
- See [IMAGE_GENERATION_SETUP.md](IMAGE_GENERATION_SETUP.md)

### Can I upload documents for RAG?

Yes! Open WebUI supports:
- PDF, DOCX, TXT uploads
- Document parsing and indexing
- Retrieval-Augmented Generation
- Per-conversation or global knowledge base

Enable in **Settings** → **RAG**.

## Configuration & Customization

### How do I change ports?

Edit `docker/docker-compose.yml`:

```yaml
services:
  open-webui:
    ports:
      - "3001:8080"  # Change 3000 to 3001
```

Restart: `docker compose down && docker compose up -d`

### Can I disable certain features?

Yes, via `.env`:

```bash
ENABLE_IMAGE_GENERATION=false
ENABLE_RAG_WEB_LOADER=false
ENABLE_COMMUNITY_SHARING=false
```

Or disable pipelines in the UI:
**Admin Panel** → **Pipelines** → Toggle off

### How do I add custom pipelines?

1. Create pipeline in `pipelines/` directory
2. Implement `Pipeline` class with `inlet`/`outlet` methods
3. Restart pipelines service: `docker compose restart pipelines`
4. Enable in Open WebUI → Admin → Pipelines

See [CONTRIBUTING.md](../CONTRIBUTING.md#adding-a-new-pipeline) for details.

### Can I use this with multiple users?

Yes! Open WebUI supports:
- Multi-user authentication
- Per-user permissions (admin, user, pending)
- User-specific memories
- Shared or private conversations

Configure in **Admin Panel** → **Settings** → **Users**.

### How do I change the admin password?

**After first setup**, change password in:
- **Settings** → **Account** → **Change Password**

**Before setup** (or reset):
```bash
# Reset Open WebUI data (WARNING: deletes all data)
docker compose down
docker volume rm openwebui_data
docker compose up -d
```

## Troubleshooting

### Services won't start - what do I do?

```bash
# Check service status
docker compose ps

# View logs
docker compose logs

# Common fixes:
# 1. Port conflicts
sudo netstat -tulpn | grep -E '(3000|11434|6333)'

# 2. Insufficient resources
docker system df
free -h

# 3. Restart Docker
sudo systemctl restart docker
docker compose up -d
```

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed solutions.

### Models are slow or timing out

**Solutions**:
1. **Use smaller models**: qwen2.5:7b instead of phi4:14b
2. **Increase timeout**: Adjust in Open WebUI settings
3. **Enable GPU**: Install NVIDIA Docker if available
4. **Increase KEEP_ALIVE**: In `.env`, set `OLLAMA_KEEP_ALIVE=10m`
5. **Add more RAM**: Ensure 16GB+ available

### Memory (Mem0) isn't working

**Common issues**:
```bash
# 1. Verify Qdrant is running
curl http://localhost:6333/health

# 2. Check embedding model installed
docker exec numberone-ollama ollama list | grep nomic-embed

# 3. Pull embedding model if missing
docker exec numberone-ollama ollama pull nomic-embed-text:latest

# 4. Restart pipelines
docker compose restart pipelines
```

### Can't access Open WebUI

**Check**:
1. Service running: `docker compose ps open-webui`
2. Logs: `docker compose logs open-webui`
3. Port available: `curl http://localhost:3000/health`
4. Firewall: Allow port 3000
5. Correct URL: http://localhost:3000 (not https)

### Running out of disk space

```bash
# Check disk usage
df -h
docker system df

# Clean up
docker system prune -a  # Remove unused images
docker volume prune     # Remove unused volumes

# Remove specific models
docker exec numberone-ollama ollama rm large-model

# Move data to larger disk
# See DEPLOYMENT.md for volume migration
```

## Maintenance & Operations

### How do I update NumberOne OWU?

```bash
# Backup first
./scripts/backup.sh

# Pull latest changes
git pull origin main

# Rebuild and restart
docker compose down
docker compose up -d --build

# Verify
docker compose ps
```

### How do I backup my data?

```bash
# Manual backup
./scripts/backup.sh

# Backups saved to ./backups/
# Includes: conversations, memories, settings, analytics

# Restore from backup
./scripts/restore.sh backups/backup-2025-01-05.tar.gz
```

Enable automated backups in `.env`:
```bash
BACKUP_ENABLED=true
BACKUP_SCHEDULE=0 2 * * *  # Daily at 2 AM
```

### What data is stored where?

**Docker volumes**:
- `openwebui_data`: User accounts, conversations, uploads
- `qdrant_data`: Vector embeddings, memories
- `ollama_data`: Downloaded models
- `langfuse_db_data`: Analytics, traces
- `clickhouse_data`: Time-series metrics

**Location**: `/var/lib/docker/volumes/` (Linux)

### How do I monitor system health?

**Built-in**:
- Dashboard: http://localhost:8080 (aggregated health)
- Langfuse: http://localhost:3003 (LLM metrics)
- Qdrant: http://localhost:6333/dashboard (vector DB)

**Command-line**:
```bash
# Check all services
docker compose ps

# Resource usage
docker stats

# Health checks
curl http://localhost:3000/health
curl http://localhost:11434/api/tags
```

### Can I run this in production?

Yes, but follow security best practices:

1. **Change default credentials** (`.env`)
2. **Use reverse proxy** (Nginx with SSL)
3. **Enable firewall** (UFW, iptables)
4. **Set resource limits** (docker-compose.yml)
5. **Enable backups** (automated)
6. **Monitor health** (automated checks)
7. **Keep updated** (regular updates)

See [DEPLOYMENT.md](DEPLOYMENT.md#production-deployment) for detailed guide.

## Performance & Optimization

### How can I make responses faster?

1. **Use smaller models**: qwen2.5:0.5b for instant responses
2. **Enable GPU acceleration**: Install NVIDIA Docker
3. **Increase KEEP_ALIVE**: Keep models loaded in memory
4. **Add more RAM**: 32GB+ recommended
5. **Use SSD storage**: Faster model loading
6. **Disable unnecessary pipelines**: Reduce processing overhead

### How much does it cost to run?

**Self-hosted** (one-time + ongoing):
- Hardware: $500-$2000 (one-time, or existing PC)
- Electricity: ~$5-20/month (depends on usage)
- Optional APIs: $0-50/month (Perplexity, OpenAI)

**Cloud hosted** (monthly):
- AWS g4dn.xlarge: ~$400/month
- DigitalOcean GPU Droplet: ~$250/month
- Spot instances: 50-70% cheaper

**vs ChatGPT Plus**: $20/month (but limited usage)

### Can I run this on a Raspberry Pi?

**Not recommended**. Raspberry Pi 4/5 has insufficient RAM for most models:
- 8GB RAM: Only smallest models (0.5B)
- Very slow CPU inference (minutes per response)
- No GPU acceleration

**Better alternatives**:
- Used desktop with GPU (~$500)
- Cloud instance with GPU
- Mini PC with 32GB RAM

## Advanced Topics

### Can I use this with Docker Swarm or Kubernetes?

Yes, but requires configuration changes:

**Docker Swarm**:
```bash
docker stack deploy -c docker-compose.yml numberone
```

**Kubernetes**: Convert to K8s manifests using Kompose or write custom manifests.

Community contributions welcome for K8s deployments!

### How do I contribute to the project?

See [CONTRIBUTING.md](../CONTRIBUTING.md):

1. Fork repository
2. Create feature branch
3. Make changes
4. Test thoroughly
5. Submit pull request

Contributions welcome: features, bug fixes, documentation, tests.

### Is there a community or support forum?

- **GitHub Issues**: Bug reports, feature requests
- **GitHub Discussions**: Questions, ideas, community support
- **Documentation**: Comprehensive guides in `docs/`

### What's the roadmap for future features?

**Planned enhancements**:
- Redis caching layer
- Additional pipeline integrations
- Enhanced monitoring (Prometheus/Grafana)
- Multi-host deployment guides
- Kubernetes manifests
- Mobile app integration

See [GitHub Issues](https://github.com/bailey-caldwell-sb/NumberOne_OWU/issues) for current roadmap.

### How can I help improve NumberOne OWU?

**Ways to contribute**:
- Report bugs
- Suggest features
- Improve documentation
- Write tutorials
- Create custom pipelines
- Test on different platforms
- Spread the word

Every contribution helps! See [CONTRIBUTING.md](../CONTRIBUTING.md).

## Getting Help

### Where should I ask questions?

1. **Check documentation**: Start with [README.md](../README.md)
2. **Search issues**: May already be answered
3. **GitHub Discussions**: For general questions
4. **GitHub Issues**: For bugs or feature requests

### How do I report a bug?

1. Check it's reproducible on clean install
2. Search existing issues
3. Create new issue with:
   - Clear description
   - Steps to reproduce
   - Environment details
   - Relevant logs

See [CONTRIBUTING.md](../CONTRIBUTING.md#reporting-issues) for template.

### What logs should I provide for debugging?

```bash
# Collect comprehensive logs
mkdir debug-logs
docker compose logs > debug-logs/all-services.log
docker stats --no-stream > debug-logs/resource-usage.txt
docker system df > debug-logs/disk-usage.txt

# Create archive
tar -czf debug-$(date +%Y%m%d).tar.gz debug-logs/
```

Include this archive when reporting issues.

---

**Still have questions?** Check the full documentation in the [docs/](../docs/) directory or open a [GitHub Discussion](https://github.com/bailey-caldwell-sb/NumberOne_OWU/discussions).
