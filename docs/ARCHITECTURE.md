# 🏗️ NumberOne OWU - Architecture Documentation

## Overview

NumberOne OWU is a microservices-based AI platform designed for privacy, performance, and extensibility. The architecture follows a layered approach with clear separation of concerns.

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Layer                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  Web Browser │  │   API Client │  │  Mobile App  │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
└─────────┼──────────────────┼──────────────────┼─────────────────┘
          │                  │                  │
          └──────────────────┼──────────────────┘
                             │
┌────────────────────────────┼─────────────────────────────────────┐
│                    Presentation Layer                            │
│                   ┌────────▼──────────┐                          │
│                   │   Open WebUI      │  Port: 3000              │
│                   │   (UI Frontend)   │                          │
│                   └────────┬──────────┘                          │
└─────────────────────────────┼───────────────────────────────────┘
                              │
┌─────────────────────────────┼───────────────────────────────────┐
│                    Application Layer                             │
│          ┌──────────────────┼──────────────────┐                │
│          │                  │                  │                │
│   ┌──────▼──────┐  ┌───────▼────────┐  ┌──────▼──────┐        │
│   │  Pipelines  │  │   Dashboard    │  │  Langfuse   │        │
│   │  (Filters)  │  │  (Monitoring)  │  │ (Analytics) │        │
│   │ Port: 9099  │  │  Port: 8080    │  │ Port: 3003  │        │
│   └──────┬──────┘  └────────────────┘  └──────┬──────┘        │
│          │                                     │                │
└──────────┼─────────────────────────────────────┼────────────────┘
           │                                     │
┌──────────┼─────────────────────────────────────┼────────────────┐
│          │         Processing Layer            │                │
│   ┌──────▼──────┐                       ┌──────▼──────┐        │
│   │   Ollama    │                       │  Langfuse   │        │
│   │   (Models)  │                       │  Services   │        │
│   │ Port: 11434 │                       │             │        │
│   └──────┬──────┘                       └──────┬──────┘        │
└──────────┼─────────────────────────────────────┼────────────────┘
           │                                     │
┌──────────┼─────────────────────────────────────┼────────────────┐
│          │           Data Layer                │                │
│   ┌──────▼──────┐  ┌──────────────┐  ┌────────▼────────┐      │
│   │   Qdrant    │  │  PostgreSQL  │  │   ClickHouse    │      │
│   │  (Vectors)  │  │  (Langfuse)  │  │   (Analytics)   │      │
│   │ Port: 6333  │  │  Port: 5434  │  │   Port: 8124    │      │
│   └─────────────┘  └──────────────┘  └─────────────────┘      │
└─────────────────────────────────────────────────────────────────┘
```

## Component Descriptions

### Presentation Layer

#### Open WebUI
- **Purpose**: User interface for AI interactions
- **Technology**: Next.js/React frontend
- **Port**: 3000 (external) → 8080 (internal)
- **Key Features**:
  - Multi-model chat interface
  - Pipeline management UI
  - User authentication
  - RAG document upload
  - Image generation interface

### Application Layer

#### Pipelines Service
- **Purpose**: AI request/response filtering and enhancement
- **Technology**: Python with Open WebUI Pipelines framework
- **Port**: 9099
- **Components**:
  - **Memory Filter**: Mem0 integration for persistent memory
  - **Langfuse Tracking**: Observability and analytics
  - **Perplexity Search**: Web search integration
- **Flow**: Inlet (pre-process) → Model → Outlet (post-process)

#### Dashboard Service
- **Purpose**: System monitoring and health checks
- **Technology**: Custom web application
- **Port**: 8080
- **Features**:
  - Service status monitoring
  - Resource usage visualization
  - Quick access to all services

#### Langfuse Service
- **Purpose**: LLM observability and analytics
- **Technology**: Next.js application
- **Port**: 3003
- **Features**:
  - Token usage tracking
  - Response time analytics
  - Cost calculation
  - User interaction patterns

### Processing Layer

#### Ollama
- **Purpose**: Local LLM inference engine
- **Technology**: Go-based model runtime
- **Port**: 11434
- **Capabilities**:
  - 19 local models
  - GPU acceleration (NVIDIA)
  - Concurrent model loading
  - Keep-alive optimization
- **Models**:
  - **Ultra-fast**: qwen2.5:0.5b, tinyllama, llama3.2:1b
  - **General**: qwen2.5:7b, gemma3:4b, phi4:14b
  - **Specialized**: codellama:13b, deepseek-coder
  - **Embedding**: nomic-embed-text

### Data Layer

#### Qdrant
- **Purpose**: Vector database for memory and embeddings
- **Technology**: Rust-based vector search engine
- **Ports**: 6333 (HTTP), 6334 (gRPC)
- **Usage**:
  - Mem0 memory storage
  - Semantic search
  - Cross-conversation context
- **Collections**:
  - `memories`: User conversation memories
  - (Custom collections as needed)

#### PostgreSQL
- **Purpose**: Relational database for Langfuse
- **Technology**: PostgreSQL 15
- **Port**: 5434 (external) → 5432 (internal)
- **Data**:
  - User accounts
  - Traces and generations
  - API keys
  - Session data

#### ClickHouse
- **Purpose**: Analytics database for Langfuse
- **Technology**: Column-oriented DBMS
- **Ports**: 8124 (HTTP), 9001 (Native)
- **Data**:
  - Time-series metrics
  - Usage analytics
  - Performance data

## Data Flow

### Chat Request Flow

```
User Input → Open WebUI → Pipelines (Inlet)
                              ↓
                    Memory Retrieval (Qdrant)
                              ↓
                    Context Enhancement
                              ↓
                          Ollama (LLM)
                              ↓
Pipelines (Outlet) → Langfuse Tracking
       ↓                      ↓
Memory Storage          Analytics DB
       ↓                      ↓
  Open WebUI ← Response ← User
```

### Detailed Request Processing

1. **User Input** (Open WebUI)
   - User sends message via web interface
   - Authentication and authorization check
   - Request formatted as chat completion

2. **Inlet Processing** (Pipelines)
   - Memory Filter: Retrieves relevant memories from Qdrant
   - Context injection: Adds memory to system prompt
   - Langfuse: Starts trace/generation tracking
   - Perplexity: Triggers web search if needed

3. **Model Inference** (Ollama)
   - Model loaded (or kept alive from previous request)
   - GPU/CPU inference based on availability
   - Streaming response generation

4. **Outlet Processing** (Pipelines)
   - Memory Filter: Stores new conversation context
   - Langfuse: Completes trace with metrics
   - Response formatting and cleanup

5. **Response Delivery** (Open WebUI)
   - Streaming response to user
   - UI updates with formatted response
   - User feedback collection

## Network Architecture

### Docker Network: `numberone-network`

All services communicate on a bridge network:

```
numberone-network (172.18.0.0/16)
├── open-webui (172.18.0.10)
├── pipelines (172.18.0.11)
├── ollama (172.18.0.12)
├── qdrant (172.18.0.13)
├── langfuse (172.18.0.14)
├── langfuse-db (172.18.0.15)
├── clickhouse (172.18.0.16)
└── dashboard (172.18.0.17)
```

**Service Discovery**:
- Services reference each other by name (e.g., `http://ollama:11434`)
- Docker DNS resolution handles name-to-IP mapping
- No hardcoded IPs required

**External Access**:
- Only specified ports exposed to host
- Internal ports remain isolated
- Reverse proxy recommended for production

## Storage Architecture

### Docker Volumes

```
Persistent Storage Strategy:
├── ollama_data (~50-100GB)
│   └── Models, configurations, cache
├── qdrant_data (~1-10GB)
│   └── Vector embeddings, collections
├── openwebui_data (~1-5GB)
│   └── User data, chat history, uploads
├── langfuse_db_data (~1-5GB)
│   └── PostgreSQL data
├── clickhouse_data (~5-20GB)
│   └── Analytics time-series data
└── pipelines_data (~100MB)
    └── Pipeline configurations, logs
```

**Backup Priority**:
1. **Critical**: `openwebui_data`, `qdrant_data` (user data)
2. **Important**: `langfuse_db_data` (analytics)
3. **Recoverable**: `ollama_data` (models can be re-downloaded)
4. **Transient**: `clickhouse_data` (can be regenerated)

## Security Architecture

### Authentication & Authorization

```
┌─────────────┐
│    User     │
└──────┬──────┘
       │ Username/Password
┌──────▼──────────┐
│  Open WebUI     │ JWT Token
│  Auth System    │
└──────┬──────────┘
       │ Authorized Requests
┌──────▼──────────┐
│   Pipelines     │ API Key: "0p3n-w3bu!"
└──────┬──────────┘
       │ Model Requests
┌──────▼──────────┐
│     Ollama      │ No Auth (internal network)
└─────────────────┘
```

**Security Layers**:
1. **User Authentication**: Open WebUI JWT-based auth
2. **API Authentication**: Pipeline API key validation
3. **Network Isolation**: Services only accessible within Docker network
4. **Data Encryption**: Optional at-rest encryption for volumes

### Current Security Considerations

⚠️ **Default Configuration Warnings**:
- PostgreSQL uses default passwords (`postgres/postgres`)
- Langfuse secret keys are placeholders
- Pipeline API key is static
- No TLS/SSL by default

🔒 **Production Recommendations**:
- Change all default passwords
- Use secrets management (Docker secrets, vault)
- Implement TLS with reverse proxy
- Enable firewall rules
- Regular security updates

## Scalability Considerations

### Horizontal Scaling Potential

**Stateless Services** (easy to scale):
- Open WebUI (with shared storage)
- Pipelines (load balance across instances)

**Stateful Services** (require clustering):
- Ollama (model sharding, request routing)
- Qdrant (cluster mode)
- PostgreSQL (replication)

### Vertical Scaling Recommendations

**Ollama** (most resource-intensive):
- CPU: 8+ cores preferred
- RAM: 16-32GB based on model size
- GPU: NVIDIA with 8-24GB VRAM
- Storage: SSD for model cache

**Qdrant**:
- CPU: 4+ cores
- RAM: 8-16GB (depends on vector count)
- Storage: SSD for performance

**Other Services**:
- Minimal resources (2 CPU, 4GB RAM each)

## Performance Optimization

### Model Loading Strategy

```
OLLAMA_KEEP_ALIVE settings:
├── 1m: Aggressive memory saving (frequent reloads)
├── 5m: Balanced (default, recommended)
├── 10m: Performance (keeps models warm)
└── -1: Maximum performance (always loaded)
```

### Caching Strategy

**Levels of Caching**:
1. **Model Cache** (Ollama): Loaded models in memory
2. **Vector Cache** (Qdrant): Hot vectors in RAM
3. **Database Cache** (PostgreSQL): Query results
4. **Application Cache** (Open WebUI): Session data

### Resource Allocation

**Recommended Docker Limits**:
```yaml
ollama:
  mem_limit: 16g
  cpus: 8

qdrant:
  mem_limit: 8g
  cpus: 4

open-webui:
  mem_limit: 2g
  cpus: 2
```

## Monitoring & Observability

### Health Check Architecture

```
Dashboard (Aggregator)
    ├── Open WebUI: /health
    ├── Ollama: /api/tags
    ├── Qdrant: /health
    ├── Langfuse: /api/public/health
    └── Pipelines: /health
```

**Health Check Intervals**:
- Critical services: 30s
- Databases: 30s
- Start period: 10-30s (service-dependent)

### Logging Strategy

**Log Levels by Service**:
- **Production**: INFO (errors, warnings, key events)
- **Development**: DEBUG (detailed traces)

**Log Destinations**:
- STDOUT: All container logs (Docker handles rotation)
- Langfuse: Application-level LLM interaction logs
- (Optional) External log aggregation (ELK, Loki)

## Deployment Patterns

### Single-Host Deployment (Current)

**Best for**:
- Development
- Personal use
- Small teams (1-10 users)

**Requirements**:
- 16-32GB RAM
- 8+ CPU cores
- 200GB storage

### Multi-Host Deployment (Future)

**Pattern**:
```
Host 1 (Frontend):
  - Open WebUI
  - Dashboard
  - Pipelines

Host 2 (Compute):
  - Ollama (with GPU)

Host 3 (Data):
  - Qdrant
  - PostgreSQL
  - ClickHouse
```

### Cloud Deployment

**Considerations**:
- Ollama requires GPU instances (AWS p3, GCP A2)
- Qdrant can use memory-optimized instances
- Storage on SSD-backed volumes
- VPC network isolation
- Load balancer for Open WebUI

## Integration Points

### External Integrations

1. **Anthropic API** (Optional)
   - Claude models for specialized tasks
   - Configured via `ANTHROPIC_API_KEY`

2. **OpenAI API** (Optional)
   - GPT models and DALL-E
   - Configured via `OPENAI_API_KEY`

3. **Perplexity API** (Optional)
   - Web search capabilities
   - Configured via `PERPLEXITY_API_KEY`

### API Endpoints

**Open WebUI**:
- `POST /api/chat/completions`: Chat completions
- `GET /api/models`: List available models
- `POST /api/pipelines`: Manage pipelines

**Ollama**:
- `POST /api/generate`: Text generation
- `POST /api/chat`: Chat completions
- `GET /api/tags`: List models
- `POST /api/pull`: Download models

**Langfuse**:
- `POST /api/public/ingestion`: Ingest traces
- `GET /api/public/traces`: Retrieve traces
- `POST /api/public/generations`: Log generations

## Development Architecture

### Development Mode Differences

**Docker Compose Dev**:
```yaml
services:
  open-webui:
    volumes:
      - ./local-dev:/app  # Hot reload
    environment:
      - DEBUG_MODE=true
      - LOG_LEVEL=DEBUG
```

**Features**:
- Hot reload for code changes
- Verbose logging
- Development API endpoints
- No authentication (optional)

## Future Architecture Enhancements

### Planned Improvements

1. **Service Mesh** (Istio/Linkerd)
   - Enhanced observability
   - Traffic management
   - Security policies

2. **Message Queue** (Redis/RabbitMQ)
   - Async processing
   - Request queuing
   - Load distribution

3. **Caching Layer** (Redis)
   - Response caching
   - Session management
   - Rate limiting

4. **API Gateway** (Kong/Traefik)
   - Unified API endpoint
   - Authentication/authorization
   - Rate limiting
   - Request routing

## Troubleshooting Architecture Issues

### Common Patterns

**Service Won't Start**:
1. Check dependencies (depends_on with health checks)
2. Verify port availability
3. Check volume permissions
4. Review environment variables

**Network Communication Failure**:
1. Verify services on same network
2. Check service names in configuration
3. Test with `docker exec ... curl`
4. Review network policies

**Performance Degradation**:
1. Check resource limits
2. Monitor with `docker stats`
3. Review Langfuse metrics
4. Analyze bottlenecks

## References

- [Open WebUI Documentation](https://docs.openwebui.com)
- [Ollama Documentation](https://ollama.ai/docs)
- [Mem0 Documentation](https://docs.mem0.ai)
- [Langfuse Documentation](https://langfuse.com/docs)
- [Qdrant Documentation](https://qdrant.tech/documentation)
- [Docker Compose Documentation](https://docs.docker.com/compose)
