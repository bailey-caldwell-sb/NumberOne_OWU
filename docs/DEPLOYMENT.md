# 🚀 NumberOne OWU - Deployment Guide

## Overview

This guide covers various deployment scenarios for NumberOne OWU, from local development to production environments.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start (Local)](#quick-start-local)
- [Development Deployment](#development-deployment)
- [Production Deployment](#production-deployment)
- [Cloud Deployment](#cloud-deployment)
- [Advanced Configuration](#advanced-configuration)
- [Monitoring & Maintenance](#monitoring--maintenance)
- [Backup & Recovery](#backup--recovery)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### System Requirements

**Minimum** (Development):
- **CPU**: 4 cores
- **RAM**: 16 GB
- **Storage**: 100 GB free space (SSD recommended)
- **OS**: Linux, macOS, or Windows with WSL2

**Recommended** (Production):
- **CPU**: 8+ cores
- **RAM**: 32 GB
- **Storage**: 200+ GB SSD
- **GPU**: NVIDIA GPU with 8+ GB VRAM (optional but recommended)
- **OS**: Ubuntu 22.04 LTS or similar

### Software Requirements

**Required**:
- **Docker**: 20.10 or later
- **Docker Compose**: 2.0 or later
- **Git**: For repository management

**Optional**:
- **NVIDIA Docker**: For GPU acceleration
- **Nginx**: For reverse proxy
- **Certbot**: For SSL/TLS certificates

### Installation

**Docker on Ubuntu**:
```bash
# Update package index
sudo apt update

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt install docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER

# Verify installation
docker --version
docker compose version
```

**NVIDIA Docker (for GPU support)**:
```bash
# Add NVIDIA package repositories
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list

# Install NVIDIA Docker
sudo apt update
sudo apt install -y nvidia-docker2

# Restart Docker
sudo systemctl restart docker

# Test GPU access
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
```

## Quick Start (Local)

### 1. Clone Repository

```bash
git clone https://github.com/bailey-caldwell-sb/NumberOne_OWU.git
cd NumberOne_OWU
```

### 2. Configure Environment

```bash
# Copy example environment file
cp .env.example .env

# Edit .env with your preferred editor
nano .env  # or vim, code, etc.
```

**Minimal Configuration** (optional services):
```bash
# AI Provider API Keys (Optional)
ANTHROPIC_API_KEY=your_key_here
OPENAI_API_KEY=your_key_here
PERPLEXITY_API_KEY=your_key_here

# Security (Change these!)
LANGFUSE_SECRET=your-random-secret-32-chars
LANGFUSE_SALT=your-random-salt-16-chars
WEBUI_SECRET_KEY=your-webui-secret-key
```

### 3. Deploy

```bash
# Start all services
./scripts/deploy.sh

# Or manually
cd docker
docker compose up -d
```

### 4. Access Services

Wait 1-2 minutes for services to start, then access:

- **Open WebUI**: http://localhost:3000
- **Langfuse**: http://localhost:3003
- **Qdrant Dashboard**: http://localhost:6333/dashboard
- **System Dashboard**: http://localhost:8080

### 5. First-Time Setup

1. Navigate to http://localhost:3000
2. Create your admin account
3. Log in to Open WebUI
4. Navigate to **Admin Panel** → **Pipelines**
5. Enable desired pipelines:
   - Memory Filter (Mem0)
   - Langfuse Tracking
   - Perplexity Search (requires API key)

### 6. Install Models

```bash
# Install ultra-fast models for quick responses
./scripts/install-fast-models.sh

# Or manually install specific models
docker exec numberone-ollama ollama pull qwen2.5:7b
docker exec numberone-ollama ollama pull gemma3:4b
docker exec numberone-ollama ollama pull codellama:13b
```

## Development Deployment

### Development Environment

Use the development Docker Compose file for:
- Hot reload
- Debug logging
- Development tools
- No authentication (optional)

```bash
# Start development environment
docker compose -f docker/docker-compose.dev.yml up -d

# View logs in real-time
docker compose -f docker/docker-compose.dev.yml logs -f

# Stop development environment
docker compose -f docker/docker-compose.dev.yml down
```

### Development with Local Code

Mount local code for live editing:

```yaml
# docker/docker-compose.dev.yml additions
services:
  pipelines:
    volumes:
      - ../pipelines:/app/pipelines  # Mount local pipeline code
    environment:
      - DEBUG_MODE=true
      - LOG_LEVEL=DEBUG
```

### Development Workflow

```bash
# 1. Make code changes locally
vim pipelines/mem0_memory_filter.py

# 2. Restart affected service
docker compose restart pipelines

# 3. Check logs
docker compose logs -f pipelines

# 4. Test changes
curl http://localhost:9099/health
```

## Production Deployment

### Security Hardening

#### 1. Change Default Credentials

```bash
# Generate secure secrets
openssl rand -hex 32  # For LANGFUSE_SECRET
openssl rand -hex 16  # For LANGFUSE_SALT
openssl rand -hex 32  # For WEBUI_SECRET_KEY

# Update .env file
LANGFUSE_SECRET=<generated-secret-32-chars>
LANGFUSE_SALT=<generated-salt-16-chars>
WEBUI_SECRET_KEY=<generated-secret-32-chars>

# Update PostgreSQL password
POSTGRES_PASSWORD=<strong-password>
```

#### 2. Docker Secrets (Recommended)

Create Docker secrets for sensitive data:

```bash
# Create secrets
echo "your-secret-key" | docker secret create langfuse_secret -
echo "your-postgres-password" | docker secret create postgres_password -

# Update docker-compose.yml
services:
  langfuse:
    secrets:
      - langfuse_secret
    environment:
      - NEXTAUTH_SECRET_FILE=/run/secrets/langfuse_secret

secrets:
  langfuse_secret:
    external: true
  postgres_password:
    external: true
```

#### 3. Firewall Configuration

```bash
# Allow only necessary ports
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable

# Access services only via reverse proxy
# Do NOT expose Docker ports directly
```

### Reverse Proxy Setup

#### Nginx Configuration

```bash
# Install Nginx
sudo apt install nginx

# Create configuration
sudo nano /etc/nginx/sites-available/numberone-owu
```

```nginx
# /etc/nginx/sites-available/numberone-owu
upstream openwebui {
    server localhost:3000;
}

upstream langfuse {
    server localhost:3003;
}

# Open WebUI
server {
    listen 80;
    server_name your-domain.com;

    # Redirect to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;

    # Increase upload size for documents
    client_max_body_size 100M;

    location / {
        proxy_pass http://openwebui;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}

# Langfuse (subdomain)
server {
    listen 443 ssl http2;
    server_name langfuse.your-domain.com;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    location / {
        proxy_pass http://langfuse;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/numberone-owu /etc/nginx/sites-enabled/

# Test configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

#### SSL/TLS with Let's Encrypt

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx

# Obtain certificate
sudo certbot --nginx -d your-domain.com -d langfuse.your-domain.com

# Auto-renewal (check)
sudo certbot renew --dry-run
```

### Resource Limits

Add resource limits to prevent over-consumption:

```yaml
# docker/docker-compose.yml
services:
  ollama:
    deploy:
      resources:
        limits:
          cpus: '8.0'
          memory: 16G
        reservations:
          memory: 8G
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]

  qdrant:
    deploy:
      resources:
        limits:
          cpus: '4.0'
          memory: 8G

  open-webui:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
```

### Monitoring & Logging

#### Centralized Logging

```bash
# Configure Docker logging
# /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}

# Restart Docker
sudo systemctl restart docker
```

#### Health Monitoring

```bash
# Create monitoring script
cat > /usr/local/bin/numberone-health-check.sh << 'EOF'
#!/bin/bash
set -euo pipefail

SERVICES=(
  "http://localhost:3000/health"
  "http://localhost:11434/api/tags"
  "http://localhost:6333/health"
  "http://localhost:3003/api/public/health"
)

for service in "${SERVICES[@]}"; do
  if ! curl -sf "$service" >/dev/null; then
    echo "ALERT: Service $service is down!"
    # Send alert (email, Slack, etc.)
  fi
done
EOF

chmod +x /usr/local/bin/numberone-health-check.sh

# Add to crontab (check every 5 minutes)
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/numberone-health-check.sh") | crontab -
```

## Cloud Deployment

### AWS Deployment

#### EC2 Instance Setup

**Recommended Instance Type**: `g4dn.xlarge` (with GPU)
- 4 vCPUs
- 16 GB RAM
- 1x NVIDIA T4 GPU (16 GB)

```bash
# Launch EC2 instance with Ubuntu 22.04
# Configure Security Group:
# - SSH (22) from your IP
# - HTTP (80) from anywhere
# - HTTPS (443) from anywhere

# Install NVIDIA drivers
sudo apt update
sudo apt install -y nvidia-driver-535
sudo reboot

# Install Docker and NVIDIA Docker
curl -fsSL https://get.docker.com | sh
sudo apt install -y nvidia-docker2
sudo systemctl restart docker

# Clone and deploy
git clone https://github.com/bailey-caldwell-sb/NumberOne_OWU.git
cd NumberOne_OWU
./scripts/deploy.sh
```

#### EBS Volume for Data

```bash
# Create and attach EBS volume (200 GB)
# Mount at /data
sudo mkfs.ext4 /dev/xvdf
sudo mkdir /data
sudo mount /dev/xvdf /data

# Update docker-compose.yml to use /data
volumes:
  ollama_data:
    driver: local
    driver_opts:
      type: none
      device: /data/ollama
      o: bind
```

### Google Cloud Platform

**Recommended Instance**: `n1-standard-8` with T4 GPU

```bash
# Create instance with GPU
gcloud compute instances create numberone-owu \
  --zone=us-central1-a \
  --machine-type=n1-standard-8 \
  --accelerator=type=nvidia-tesla-t4,count=1 \
  --boot-disk-size=200GB \
  --boot-disk-type=pd-ssd \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --maintenance-policy=TERMINATE

# SSH into instance
gcloud compute ssh numberone-owu

# Install NVIDIA drivers
curl https://raw.githubusercontent.com/GoogleCloudPlatform/compute-gpu-installation/main/linux/install_gpu_driver.py --output install_gpu_driver.py
sudo python3 install_gpu_driver.py

# Deploy NumberOne OWU
git clone https://github.com/bailey-caldwell-sb/NumberOne_OWU.git
cd NumberOne_OWU
./scripts/deploy.sh
```

### DigitalOcean

**Recommended Droplet**: GPU Droplet (if available) or CPU Optimized

```bash
# Create Droplet (Ubuntu 22.04)
# SSH into droplet
ssh root@your-droplet-ip

# Install Docker
curl -fsSL https://get.docker.com | sh

# Deploy
git clone https://github.com/bailey-caldwell-sb/NumberOne_OWU.git
cd NumberOne_OWU
./scripts/deploy.sh

# Configure firewall
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
```

## Advanced Configuration

### Multi-Host Deployment

Separate compute-intensive services across multiple hosts:

**Host 1 (Frontend)**:
```yaml
services:
  open-webui:
    environment:
      - OLLAMA_BASE_URL=http://192.168.1.100:11434
      - OPENAI_API_BASE_URL=http://192.168.1.101:9099
```

**Host 2 (Compute)**:
```yaml
services:
  ollama:
    ports:
      - "192.168.1.100:11434:11434"
```

**Host 3 (Pipelines)**:
```yaml
services:
  pipelines:
    ports:
      - "192.168.1.101:9099:9099"
    environment:
      - QDRANT_HOST=192.168.1.102
```

### High Availability Setup

Use Docker Swarm or Kubernetes for HA:

**Docker Swarm Example**:
```bash
# Initialize swarm
docker swarm init

# Deploy stack
docker stack deploy -c docker-compose.yml numberone

# Scale services
docker service scale numberone_open-webui=3
```

### Load Balancing

Use HAProxy or Nginx for load balancing:

```nginx
upstream openwebui_backend {
    least_conn;
    server 192.168.1.10:3000;
    server 192.168.1.11:3000;
    server 192.168.1.12:3000;
}

server {
    listen 80;
    location / {
        proxy_pass http://openwebui_backend;
    }
}
```

## Monitoring & Maintenance

### Health Checks

```bash
# Check all services
docker compose ps

# Check health status
docker inspect --format='{{.State.Health.Status}}' numberone-openwebui

# View service logs
docker compose logs --tail=100 -f
```

### Performance Monitoring

```bash
# Monitor resource usage
docker stats

# Check disk usage
df -h
docker system df

# Monitor network traffic
docker network inspect numberone-network
```

### Updates & Upgrades

```bash
# Backup data first
./scripts/backup.sh

# Pull latest changes
git pull origin main

# Rebuild and restart
docker compose up -d --build

# Verify services
./scripts/validate.sh
```

## Backup & Recovery

### Automated Backups

```bash
# Enable automated backups
# Edit .env
BACKUP_ENABLED=true
BACKUP_SCHEDULE=0 2 * * *  # Daily at 2 AM
BACKUP_RETENTION_DAYS=30

# Manual backup
./scripts/backup.sh

# Backups stored in: ./backups/
```

### Backup Contents

Backups include:
- **Open WebUI data**: User accounts, conversations, uploads
- **Qdrant data**: Vector embeddings, memories
- **Langfuse data**: Analytics, traces
- **Configuration**: Environment files, settings

### Restore from Backup

```bash
# Stop services
docker compose down

# Restore data
./scripts/restore.sh backups/backup-2025-01-05.tar.gz

# Start services
docker compose up -d
```

## Troubleshooting

### Common Deployment Issues

**Services won't start**:
```bash
# Check Docker daemon
sudo systemctl status docker

# Check ports
sudo netstat -tulpn | grep -E '(3000|11434|6333)'

# View logs
docker compose logs
```

**GPU not detected**:
```bash
# Verify NVIDIA drivers
nvidia-smi

# Test GPU in Docker
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi

# Check Docker GPU support
docker info | grep -i runtime
```

**Out of disk space**:
```bash
# Check disk usage
df -h
docker system df

# Clean up
docker system prune -a
docker volume prune
```

For more troubleshooting, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## Support

- **Documentation**: Check [docs/](../docs/) directory
- **Issues**: [GitHub Issues](https://github.com/bailey-caldwell-sb/NumberOne_OWU/issues)
- **Architecture**: See [ARCHITECTURE.md](ARCHITECTURE.md)

---

**Next Steps**: After deployment, configure your [pipelines](SETUP.md#pipeline-configuration) and explore the [available models](AGENTS.md).
