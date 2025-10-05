# 🔧 NumberOne OWU - Troubleshooting Guide

## Common Issues and Solutions

### 🚀 Deployment Issues

#### Services Not Starting

**Problem**: Docker containers fail to start or exit immediately.

**Solutions**:
```bash
# Check Docker status
sudo systemctl status docker

# Check available resources
docker system df
df -h

# Check logs for specific service
docker-compose logs servicename

# Restart Docker daemon
sudo systemctl restart docker

# Clean restart all services
docker-compose down -v
docker-compose up -d
```

**Common Causes**:
- Insufficient disk space (need 50+ GB)
- Port conflicts (check with `netstat -tulpn`)
- Docker daemon not running
- Corrupted Docker images

#### Port Conflicts

**Problem**: "Port already in use" errors.

**Solutions**:
```bash
# Check what's using the port
sudo netstat -tulpn | grep :3000
sudo lsof -i :3000

# Kill process using port
sudo kill -9 <PID>

# Change ports in docker-compose.yml
# Example: "3001:8080" instead of "3000:8080"
```

**Default Ports**:
- Open WebUI: 3000
- Langfuse: 3003
- Ollama: 11434
- Qdrant: 6333, 6334
- Pipelines: 9099
- Dashboard: 8080

### 🤖 Ollama Issues

#### Models Not Loading

**Problem**: Ollama models fail to download or load.

**Solutions**:
```bash
# Check Ollama status
docker exec numberone-ollama ollama list

# Check available space
docker exec numberone-ollama df -h

# Manually pull model
docker exec numberone-ollama ollama pull qwen2.5:7b

# Check Ollama logs
docker-compose logs ollama

# Restart Ollama
docker-compose restart ollama
```

#### Slow Model Performance

**Problem**: Models respond very slowly.

**Solutions**:
```bash
# Check if GPU is being used
nvidia-smi

# Verify GPU support in container
docker exec numberone-ollama nvidia-smi

# Adjust keep-alive setting
# In .env: OLLAMA_KEEP_ALIVE=10m

# Use smaller models for faster responses
# qwen2.5:7b instead of phi4:14b
```

#### Out of Memory Errors

**Problem**: Ollama crashes with OOM errors.

**Solutions**:
```bash
# Check memory usage
docker stats

# Reduce concurrent models
# Set OLLAMA_KEEP_ALIVE=1m in .env

# Use smaller models
# Switch from 14B to 7B models

# Increase system swap
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### 🧠 Memory Pipeline Issues

#### Memory Not Working

**Problem**: Mem0 pipeline not storing or retrieving memories.

**Solutions**:
```bash
# Check Qdrant connection
curl http://localhost:6333/health

# Check pipeline logs
docker-compose logs pipelines | grep mem0

# Verify Mem0 installation
docker exec numberone-pipelines pip list | grep mem0

# Check Qdrant collections
curl http://localhost:6333/collections

# Restart pipelines
docker-compose restart pipelines
```

#### Memory Storage Errors

**Problem**: Errors when storing memories.

**Solutions**:
```bash
# Check Qdrant storage space
docker exec numberone-qdrant df -h

# Verify embedding model
docker exec numberone-ollama ollama list | grep nomic-embed

# Check pipeline configuration
# Verify store_cycles and user settings in pipeline valves

# Clear corrupted memories
curl -X DELETE http://localhost:6333/collections/memories
```

**Common Error Messages**:

**"Connection refused to Qdrant"**:
```bash
# Verify Qdrant is running
docker-compose ps qdrant

# Check Qdrant logs
docker-compose logs qdrant

# Verify network connectivity
docker exec numberone-pipelines ping -c 3 qdrant

# Restart Qdrant
docker-compose restart qdrant
```

**"Embedding model not found"**:
```bash
# Pull the embedding model
docker exec numberone-ollama ollama pull nomic-embed-text:latest

# Verify model installed
docker exec numberone-ollama ollama list | grep nomic-embed

# Check model dimensions match (768)
# Verify vector_store_qdrant_dims in pipeline valves
```

**"Memory thread timeout"**:
```bash
# Check if previous memory operation is stuck
docker-compose logs pipelines | grep -i "memory"

# Restart pipelines service
docker-compose restart pipelines

# Reduce store_cycles in pipeline settings (e.g., from 3 to 5)
```

### 🔍 Search Pipeline Issues

#### Perplexity Search Not Working

**Problem**: Web search functionality not responding.

**Solutions**:
```bash
# Verify API key
echo $PERPLEXITY_API_KEY

# Test API connection
curl -H "Authorization: Bearer $PERPLEXITY_API_KEY" \
     https://api.perplexity.ai/chat/completions

# Check pipeline logs
docker-compose logs pipelines | grep perplexity

# Verify search triggers
# Try explicit search: "search: latest AI news"
```

#### Search Rate Limiting

**Problem**: Search requests being rate limited.

**Solutions**:
```bash
# Check API usage in Perplexity dashboard
# Reduce search frequency in pipeline settings
# Implement request queuing in pipeline

# Temporary workaround: disable auto-search
# Set enable_auto_search: false in pipeline valves
```

### 📊 Langfuse Issues

#### Tracking Not Working

**Problem**: LLM interactions not being tracked.

**Solutions**:
```bash
# Check Langfuse service
curl http://localhost:3003/api/public/health

# Verify API keys
echo $LANGFUSE_SECRET_KEY
echo $LANGFUSE_PUBLIC_KEY

# Check pipeline configuration
docker-compose logs pipelines | grep langfuse

# Restart Langfuse stack
docker-compose restart langfuse langfuse-db clickhouse
```

#### Database Connection Errors

**Problem**: Langfuse can't connect to database.

**Solutions**:
```bash
# Check PostgreSQL status
docker-compose logs langfuse-db

# Check ClickHouse status
docker-compose logs clickhouse

# Verify database connectivity
docker exec numberone-langfuse-db pg_isready

# Reset database (WARNING: loses data)
docker-compose down
docker volume rm langfuse_db_data clickhouse_data
docker-compose up -d
```

### 🌐 Open WebUI Issues

#### Can't Access Interface

**Problem**: Open WebUI not accessible at localhost:3000.

**Solutions**:
```bash
# Check service status
docker-compose ps open-webui

# Check logs
docker-compose logs open-webui

# Verify port mapping
docker port numberone-openwebui

# Test internal connectivity
docker exec numberone-openwebui curl localhost:8080

# Check firewall settings
sudo ufw status
```

#### Pipeline Not Detected

**Problem**: Pipelines not showing in Open WebUI.

**Solutions**:
```bash
# Verify pipeline connection
curl -H "Authorization: Bearer 0p3n-w3bu!" \
     http://localhost:9099/pipelines

# Check network connectivity
docker exec numberone-openwebui \
     curl http://pipelines:9099/health

# Verify environment variables
docker exec numberone-openwebui env | grep OPENAI_API

# Restart Open WebUI
docker-compose restart open-webui
```

#### Authentication Issues

**Problem**: Can't log in or create account.

**Solutions**:
```bash
# Reset Open WebUI data
docker-compose down
docker volume rm openwebui_data
docker-compose up -d open-webui

# Check authentication settings
# Verify WEBUI_AUTH environment variable

# Create admin user manually
docker exec -it numberone-openwebui \
     python -c "from apps.webui.models.users import Users; Users.insert_new_user('admin@example.com', 'admin', 'password', 'admin')"
```

### 🔧 Performance Issues

#### High CPU Usage

**Problem**: System using too much CPU.

**Solutions**:
```bash
# Check which containers are using CPU
docker stats

# Limit CPU usage in docker-compose.yml
deploy:
  resources:
    limits:
      cpus: '4.0'

# Use smaller models
# Reduce concurrent requests
# Increase OLLAMA_KEEP_ALIVE to reduce model loading
```

#### High Memory Usage

**Problem**: System running out of memory.

**Solutions**:
```bash
# Check memory usage
free -h
docker stats

# Limit memory in docker-compose.yml
deploy:
  resources:
    limits:
      memory: 8G

# Clear unused Docker resources
docker system prune -a

# Restart services to clear memory leaks
docker-compose restart
```

#### Slow Response Times

**Problem**: AI responses are very slow.

**Solutions**:
```bash
# Check system load
top
htop

# Use GPU acceleration
# Verify NVIDIA Docker setup

# Use smaller, faster models
# qwen2.5:7b instead of phi4:14b

# Optimize pipeline processing
# Disable unnecessary pipelines

# Check network latency
ping ollama
ping pipelines
```

### 🗄️ Storage Issues

#### Disk Space Full

**Problem**: Running out of disk space.

**Solutions**:
```bash
# Check disk usage
df -h
du -sh docker/volumes/*

# Clean Docker resources
docker system prune -a
docker volume prune

# Remove unused models
docker exec numberone-ollama ollama rm unused-model

# Move data to larger disk
# Update volume mounts in docker-compose.yml
```

#### Backup/Restore Issues

**Problem**: Backup or restore operations failing.

**Solutions**:
```bash
# Check backup script permissions
chmod +x scripts/backup.sh

# Verify available space for backup
df -h backups/

# Test backup manually
./scripts/backup.sh

# Check restore script
tar -tzf backup.tar.gz | head -20

# Restore specific components only
# Extract and restore individual volumes
```

### 🔒 Security Issues

#### API Key Exposure

**Problem**: API keys visible in logs or environment.

**Solutions**:
```bash
# Check for exposed keys in logs
docker-compose logs | grep -i "api.*key"

# Use Docker secrets instead of environment variables
# Update .env file permissions
chmod 600 .env

# Rotate exposed API keys
# Update keys in provider dashboards
```

#### Network Security

**Problem**: Services exposed to internet.

**Solutions**:
```bash
# Check open ports
sudo netstat -tulpn | grep LISTEN

# Use firewall to restrict access
sudo ufw enable
sudo ufw allow from 192.168.1.0/24 to any port 3000

# Use reverse proxy with authentication
# Configure nginx with basic auth
```

## 🆘 Emergency Procedures

### Complete System Reset

```bash
# Stop all services
docker-compose down -v

# Remove all data (WARNING: DESTRUCTIVE)
docker volume prune -f
docker system prune -a -f

# Redeploy from scratch
./scripts/deploy.sh
```

### Service Recovery

```bash
# Restart specific service
docker-compose restart servicename

# Rebuild service
docker-compose up -d --force-recreate servicename

# Check service health
curl http://localhost:port/health
```

### Data Recovery

```bash
# Restore from backup
./scripts/restore.sh backup-file.tar.gz

# Recover specific volume
docker run --rm -v volume_name:/data -v $(pwd):/backup \
    alpine tar -xzf /backup/volume_backup.tar.gz -C /data
```

### 🖼️ Image Generation Issues

#### DALL-E Not Working

**Problem**: Image generation fails or returns errors.

**Solutions**:
```bash
# Verify OpenAI API key
echo $OPENAI_API_KEY

# Test API key
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY"

# Check Open WebUI image generation settings
# Admin → Settings → Images

# Verify ENABLE_IMAGE_GENERATION is true
docker exec numberone-openwebui env | grep IMAGE
```

**Common Errors**:

**"Invalid API key"**:
- Verify API key is correct in `.env`
- Restart Open WebUI: `docker-compose restart open-webui`
- Check API key has image generation permissions

**"Rate limit exceeded"**:
- Check OpenAI usage dashboard
- Implement request queuing
- Consider switching to local generation (ComfyUI/Automatic1111)

#### Local Image Generation (ComfyUI/Automatic1111)

**Problem**: Local image generation not connecting.

**Solutions**:
```bash
# Check if image generation service is running
docker-compose ps | grep -E "comfy|automatic"

# Verify network connectivity
docker exec numberone-openwebui curl http://comfyui:8188/health

# Check image generation logs
docker-compose logs comfyui

# Restart image generation services
docker-compose restart comfyui
```

### 🐳 Docker Issues

#### Container Keeps Restarting

**Problem**: Service enters restart loop.

**Solutions**:
```bash
# Check container status
docker-compose ps

# View recent logs (last 100 lines)
docker-compose logs --tail=100 servicename

# Check exit code
docker inspect numberone-servicename | grep ExitCode

# Disable restart to debug
docker-compose up --no-recreate servicename

# Common exit codes:
# 137: Out of memory (OOM killed)
# 139: Segmentation fault
# 1: General application error
```

#### Volume Permission Issues

**Problem**: Permission denied errors in containers.

**Solutions**:
```bash
# Check volume ownership
docker volume inspect volume_name

# Fix permissions (Linux)
sudo chown -R 1000:1000 /var/lib/docker/volumes/volume_name

# Fix permissions (macOS - usually not needed)
# Docker Desktop handles permissions automatically

# Recreate volume with correct permissions
docker-compose down
docker volume rm volume_name
docker-compose up -d
```

#### Network Issues

**Problem**: Containers can't communicate.

**Solutions**:
```bash
# List Docker networks
docker network ls

# Inspect network
docker network inspect numberone-network

# Verify all services on same network
docker network inspect numberone-network | grep -A 5 Containers

# Recreate network
docker-compose down
docker network rm numberone-network
docker-compose up -d

# Test connectivity between containers
docker exec numberone-openwebui ping -c 3 ollama
docker exec numberone-pipelines curl http://qdrant:6333/health
```

## 📞 Getting Help

### Log Collection

```bash
# Collect all logs
mkdir debug-logs
docker-compose logs > debug-logs/all-services.log
docker stats --no-stream > debug-logs/resource-usage.txt
df -h > debug-logs/disk-usage.txt
free -h > debug-logs/memory-usage.txt
docker network inspect numberone-network > debug-logs/network-info.txt

# Collect service-specific logs
docker-compose logs ollama > debug-logs/ollama.log
docker-compose logs pipelines > debug-logs/pipelines.log
docker-compose logs open-webui > debug-logs/open-webui.log

# Create debug archive
tar -czf debug-$(date +%Y%m%d_%H%M%S).tar.gz debug-logs/
```

### System Information

```bash
# System details
uname -a > system-info.txt
docker version >> system-info.txt
docker-compose version >> system-info.txt
nvidia-smi >> system-info.txt 2>/dev/null || echo "No NVIDIA GPU" >> system-info.txt
```

### Support Channels

1. **GitHub Issues**: Report bugs with logs and system info
2. **Documentation**: Check docs/ directory for detailed guides
3. **Community**: Join discussions for community support
4. **Emergency**: Use emergency procedures for critical issues

### Before Reporting Issues

1. ✅ Check this troubleshooting guide
2. ✅ Collect relevant logs
3. ✅ Try basic solutions (restart, clean, redeploy)
4. ✅ Include system information
5. ✅ Describe exact steps to reproduce

This troubleshooting guide covers the most common issues. For additional help, please refer to the other documentation files or open an issue on GitHub with detailed logs and system information.
