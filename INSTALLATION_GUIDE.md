# 🚀 NumberOne OWU - Installation Guide for macOS

## ✅ Project Successfully Cloned!

Your NumberOne OWU project has been cloned to:
```
/Users/baileycaldwell/Documents/augment-projects/GENAI/NumberOne_OWU
```

## 📋 What is NumberOne OWU?

**NumberOne OWU** is a comprehensive, self-hosted AI platform that combines:
- 🧠 **19 Local AI Models** via Ollama (including ultra-fast 0.5B-1B models)
- 💾 **Persistent Memory** with Mem0 integration
- 🔍 **Web Search** via Perplexity API
- 📊 **LLM Observability** with Langfuse tracking
- 🎨 **Image Generation** support (DALL-E, Automatic1111, ComfyUI)
- 🐳 **Docker-based** deployment (one-command setup)

## ⚠️ Important: Docker Desktop Required

This project requires **Docker Desktop for Mac** to run. You currently have Docker CLI installed, but need Docker Desktop.

### Install Docker Desktop

**Option 1: Download from Docker (Recommended)**
1. Visit: https://www.docker.com/products/docker-desktop/
2. Download for your Mac (Intel or Apple Silicon)
3. Drag to Applications folder
4. Launch Docker Desktop
5. Complete the setup wizard

**Option 2: Install via Homebrew**
```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
brew install --cask docker
open -a Docker
```

### Configure Docker Desktop

Once Docker Desktop is running:
1. Open Docker Desktop
2. Go to **Settings** → **Resources**
3. Allocate resources:
   - **CPUs**: 6-8 cores
   - **Memory**: 16-24 GB (for 32GB Mac)
   - **Disk**: 100 GB+
4. Go to **Settings** → **General**
5. Enable:
   - ✅ Start Docker Desktop when you log in
   - ✅ Use Docker Compose V2
6. Click **Apply & Restart**

## 🚀 Installation Steps

### Step 1: Verify Docker is Running

```bash
cd /Users/baileycaldwell/Documents/augment-projects/GENAI/NumberOne_OWU

# Check Docker
docker --version
# Should show: Docker version 28.5.1 or later

# Check Docker Compose
docker compose version
# Should show: Docker Compose version v2.0 or later

# Test Docker
docker run hello-world
# Should download and run successfully
```

### Step 2: Configure Environment

The `.env` file has already been created from `.env.example`.

**Optional: Add API Keys** (for cloud models)
```bash
# Edit the .env file
nano .env

# Add your API keys (optional):
# ANTHROPIC_API_KEY=your_key
# OPENAI_API_KEY=your_key
# PERPLEXITY_API_KEY=your_key
```

### Step 3: Make Scripts Executable

```bash
chmod +x scripts/*.sh
```

### Step 4: Deploy the Stack

```bash
# Option A: Use the deployment script (recommended)
./scripts/deploy.sh

# Option B: Manual deployment with Docker Compose
docker compose -f docker/docker-compose.yml up -d
```

**First-time deployment takes 45-60 minutes:**
- 15-20 minutes: Pulling Docker images
- 20-40 minutes: Downloading AI models
- 5-10 minutes: Starting services

### Step 5: Verify Installation

```bash
# Check all services are running
docker compose -f docker/docker-compose.yml ps

# Expected: All services should show "Up" status
```

### Step 6: Access the Services

Open these URLs in your browser:

- **Open WebUI** (Main AI Chat): http://localhost:3000
- **Langfuse** (LLM Tracking): http://localhost:3003
- **Qdrant Dashboard** (Vector DB): http://localhost:6333/dashboard
- **System Dashboard**: http://localhost:8080

### Step 7: First-Time Setup in Open WebUI

1. Go to http://localhost:3000
2. Create your admin account
3. Log in
4. Go to **Admin Panel** → **Settings** → **Models**
5. Select a fast model as default (recommended: **llama3.2:1b**)
6. Go to **Admin Panel** → **Pipelines**
7. Enable pipelines:
   - ✅ Memory Filter (Mem0)
   - ✅ Langfuse Tracking (optional)
   - ⚠️ Perplexity Search (requires API key)

### Step 8: Install Fast Models (Optional but Recommended)

For better performance on macOS, install ultra-fast models:

```bash
./scripts/install-fast-models.sh
```

This installs:
- **qwen2.5:0.5b** (397 MB) - Fastest, instant responses
- **tinyllama** (637 MB) - Very fast, good for simple tasks
- **llama3.2:1b** (1.3 GB) - Best speed/quality balance

## 📊 Available Models

### Ultra-Fast Models (Recommended for macOS)
- **qwen2.5:0.5b** - ~0.16s response time
- **tinyllama** - ~0.5s response time
- **llama3.2:1b** - ~1-2s response time

### Standard Models
- **qwen3:8b** - Latest generation
- **gemma3:4b** - Google's capable model
- **phi4:14b** - Microsoft's latest
- **codellama:13b** - Code generation
- **qwen2.5:7b** - Balanced performance
- And 11 more...

## 🛠️ Common Commands

### Start/Stop Services

```bash
# Start all services
docker compose -f docker/docker-compose.yml up -d

# Stop all services
docker compose -f docker/docker-compose.yml down

# View logs
docker compose -f docker/docker-compose.yml logs -f

# Restart specific service
docker compose -f docker/docker-compose.yml restart ollama
```

### Manage Models

```bash
# List installed models
docker exec numberone-ollama ollama list

# Pull a new model
docker exec numberone-ollama ollama pull qwen2.5:7b

# Remove a model
docker exec numberone-ollama ollama rm phi4:14b
```

### Backup Data

```bash
./scripts/backup.sh
# Backups stored in: ./backups/
```

## ⚠️ macOS-Specific Considerations

### Performance
- **No GPU acceleration** available on macOS
- CPU-only inference is 3-10x slower than GPU
- Use smaller models (0.5B-7B) for acceptable performance
- Response times: 1-15 seconds depending on model size

### Disk Space
- Requires 100+ GB free space
- Each large model takes 5-15 GB
- Docker images take 20-30 GB

### Memory
- Minimum 16 GB RAM
- Recommended 32 GB RAM
- Monitor with: `docker stats`

### Troubleshooting

**Docker Desktop won't start:**
```bash
rm -rf ~/Library/Group\ Containers/group.com.docker
rm -rf ~/Library/Containers/com.docker.docker
brew reinstall --cask docker
```

**Port already in use:**
```bash
lsof -i :3000  # Find process
kill -9 <PID>  # Kill process
```

**Out of disk space:**
```bash
docker system df      # Check usage
docker system prune -a  # Clean up
```

**Services won't start:**
```bash
docker compose -f docker/docker-compose.yml logs ollama
docker compose -f docker/docker-compose.yml restart ollama
```

## 📚 Documentation

- **Main README**: [README.md](README.md)
- **macOS Setup**: [docs/MACOS_SETUP.md](docs/MACOS_SETUP.md)
- **Full Setup Guide**: [docs/SETUP.md](docs/SETUP.md)
- **Troubleshooting**: [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
- **API Reference**: [docs/API.md](docs/API.md)

## 🆘 Getting Help

1. Check [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
2. Check [docs/MACOS_SETUP.md](docs/MACOS_SETUP.md)
3. Review Docker logs: `docker compose logs -f`
4. Check GitHub Issues: https://github.com/bailey-caldwell-sb/NumberOne_OWU/issues

## 📝 Next Steps

1. **Install Docker Desktop** (if not already done)
2. **Start Docker Desktop** and wait for it to be ready
3. **Run deployment**: `./scripts/deploy.sh`
4. **Wait for setup** to complete (45-60 minutes)
5. **Access Open WebUI** at http://localhost:3000
6. **Create account** and start chatting!

---

**Project Location**: `/Users/baileycaldwell/Documents/augment-projects/GENAI/NumberOne_OWU`

**Happy AI-ing!** 🚀🤖
