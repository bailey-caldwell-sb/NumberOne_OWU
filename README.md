# 🚀 NumberOne OWU - Complete AI Platform

**NumberOne Open WebUI** is a comprehensive, self-hosted AI platform that combines the power of Open WebUI with advanced memory, observability, and web search capabilities. Built for privacy, performance, and extensibility.

## 🌟 Features

### 🧠 **Advanced AI Capabilities**
- **19 Local Models**: Including 3 ultra-fast models (qwen2.5:0.5b, tinyllama, llama3.2:1b)
- **Lightning-Fast Responses**: Sub-second inference with optimized small models
- **Image Generation**: DALL-E, Automatic1111, ComfyUI, and Image Router support
- **Persistent Memory**: Mem0 integration with vector storage for cross-conversation memory
- **Web Search**: Perplexity API integration for real-time information retrieval
- **Multi-Modal Support**: Text, voice, images, and document processing

### 📊 **Observability & Analytics**
- **LLM Tracking**: Langfuse integration for comprehensive AI interaction monitoring
- **Performance Metrics**: Response times, token usage, and model performance
- **Cost Analysis**: Track usage across different models and providers
- **Real-time Dashboards**: Monitor system health and usage patterns

### 🔧 **Infrastructure**
- **Docker Compose**: One-command deployment of the entire stack
- **Custom Pipelines**: Extensible filter system for AI processing
- **Vector Database**: Qdrant for efficient similarity search
- **Auto-scaling**: Intelligent resource management

### 🛡️ **Privacy & Security**
- **Local-First**: All models run locally via Ollama
- **Data Sovereignty**: Your data never leaves your infrastructure
- **Encrypted Storage**: Optional conversation encryption
- **Access Control**: User management and permissions

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose
- 16GB+ RAM (recommended)
- NVIDIA GPU (optional, for faster inference)

> **🍎 macOS Users**: See [macOS Setup Guide](docs/MACOS_SETUP.md) for platform-specific instructions

### 1. Clone & Setup
```bash
git clone https://github.com/yourusername/NumberOne_OWU.git
cd NumberOne_OWU
cp .env.example .env
# Edit .env with your API keys (optional)
```

### 2. Deploy Everything
```bash
# Start the complete stack
./scripts/deploy.sh

# Or manually with Docker Compose
docker-compose up -d
```

### 3. Install Fast Models (Optional)
```bash
# Install 3 ultra-fast models for instant responses
./scripts/install-fast-models.sh
```

### 4. Configure Image Generation (Optional)
```bash
# Test image generation setup
./scripts/test-image-generation.py
```
See [Image Generation Setup Guide](docs/IMAGE_GENERATION_SETUP.md) for detailed configuration.

## 📦 Installation

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

### 3. Access Services
- **Open WebUI**: http://localhost:3000
- **Langfuse**: http://localhost:3003
- **Qdrant Dashboard**: http://localhost:6333/dashboard
- **System Dashboard**: http://localhost:8080

### 4. First Time Setup
1. Create account in Open WebUI
2. Enable Mem0 memory pipeline in Admin → Pipelines
3. Configure Perplexity API key (optional)
4. Start chatting with any of the 16 available models!

## 📁 Project Structure

```
NumberOne_OWU/
├── 🐳 docker/                    # Docker configurations
│   ├── docker-compose.yml        # Main stack deployment
│   ├── docker-compose.dev.yml    # Development environment
│   └── services/                 # Individual service configs
├── 🔧 pipelines/                 # Open WebUI pipelines
│   ├── mem0_memory_filter.py     # Memory integration
│   ├── langfuse_tracking.py      # LLM observability
│   └── perplexity_search.py      # Web search integration
├── 📊 monitoring/                # Observability stack
│   ├── langfuse/                 # LLM tracking configuration
│   └── dashboards/               # Grafana dashboards
├── 🤖 models/                    # AI model configurations
│   ├── ollama/                   # Local model definitions
│   └── configs/                  # Model-specific settings
├── 🛠️ scripts/                   # Automation scripts
│   ├── deploy.sh                 # One-click deployment
│   ├── backup.sh                 # Data backup utility
│   └── update.sh                 # System update script
├── 📚 docs/                      # Documentation
│   ├── SETUP.md                  # Detailed setup guide
│   ├── AGENTS.md                 # AI agent documentation
│   ├── API.md                    # API reference
│   └── TROUBLESHOOTING.md        # Common issues & solutions
└── 🔐 config/                    # Configuration files
    ├── .env.example              # Environment template
    └── settings/                 # Service configurations
```

## 🧠 AI Agents & Models

### Local Models (Ollama)
- **qwen3:8b** - Latest generation with MoE capabilities
- **gemma3:4b** - Google's most capable single-GPU model  
- **phi4:14b** - Microsoft's latest 14B parameter model
- **codellama:13b** - Specialized for code generation
- **qwen2.5:7b** - Balanced performance for general tasks
- **And 11 more models** for specialized use cases

### ⚡ Ultra-Fast Models (NEW!)
- **qwen2.5:0.5b** (397 MB): Lightning-fast responses in ~0.16s
- **tinyllama** (637 MB): Efficient for simple conversations
- **llama3.2:1b** (1.3 GB): Best speed/quality balance
- **Perfect for**: Quick questions, rapid prototyping, instant responses

### 🎨 Image Generation (NEW!)
- **DALL-E Integration**: OpenAI DALL-E 2, 3, and GPT-Image-1 support
- **Local Generation**: Automatic1111 and ComfyUI compatibility
- **Image Router**: Access to multiple image generation models
- **Seamless Integration**: Generate images directly in chat conversations

### Memory System (Mem0)
- **Cross-Conversation Memory**: Remember context across chats
- **User-Specific Storage**: Isolated memories per user
- **Vector Search**: Semantic similarity matching
- **Automatic Triggers**: Store memories every 3 messages

### Web Search (Perplexity)
- **Real-Time Information**: Access current web data
- **Smart Routing**: AI decides when search is needed
- **Source Citations**: Transparent information sourcing
- **Domain Filtering**: Target specific websites

## 📈 Monitoring & Analytics

### Langfuse Integration
- **Token Usage Tracking**: Monitor consumption across models
- **Response Quality**: Rate and analyze AI outputs
- **Performance Metrics**: Track latency and throughput
- **Cost Analysis**: Understand usage patterns

### System Monitoring
- **Health Checks**: Automated service monitoring
- **Resource Usage**: CPU, memory, and GPU utilization
- **Error Tracking**: Comprehensive logging and alerting
- **Usage Analytics**: User interaction patterns

## 🔧 Configuration

### Environment Variables
```bash
# AI Provider APIs (Optional)
ANTHROPIC_API_KEY=your_key_here
OPENAI_API_KEY=your_key_here
PERPLEXITY_API_KEY=your_key_here

# Ollama Configuration
OLLAMA_HOST=localhost:11434
OLLAMA_KEEP_ALIVE=5m

# Memory Configuration
MEM0_USER=your_username
MEM0_STORE_CYCLES=3

# Monitoring
LANGFUSE_SECRET_KEY=your_secret
LANGFUSE_PUBLIC_KEY=your_public_key
```

### Pipeline Configuration
Each pipeline can be configured via the Open WebUI interface:
- **Memory Settings**: Adjust storage frequency and retrieval
- **Search Parameters**: Configure web search behavior
- **Tracking Options**: Customize observability settings

## 🚀 Advanced Features

### Custom Pipelines
Create your own AI processing pipelines:
```python
class CustomPipeline:
    def __init__(self):
        self.type = "filter"
        self.name = "Custom Filter"
    
    async def inlet(self, body: dict, user: dict = None) -> dict:
        # Process incoming messages
        return body
    
    async def outlet(self, body: dict, user: dict = None) -> dict:
        # Process outgoing responses
        return body
```

### API Integration
Access the platform programmatically:
```python
import requests

# Chat with any model
response = requests.post("http://localhost:3000/api/chat", {
    "model": "qwen3:8b",
    "messages": [{"role": "user", "content": "Hello!"}]
})
```

## 🛠️ Development

### Local Development
```bash
# Start development environment
docker-compose -f docker-compose.dev.yml up -d

# Watch logs
docker-compose logs -f

# Access development tools
# - Hot reload enabled
# - Debug logging active
# - Development APIs exposed
```

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📚 Documentation

- **[Setup Guide](docs/SETUP.md)** - Detailed installation instructions
- **[Agent Documentation](docs/AGENTS.md)** - AI agent system overview
- **[API Reference](docs/API.md)** - Complete API documentation
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions

## 🤝 Support

- **GitHub Issues**: Report bugs and request features
- **Discussions**: Community support and ideas
- **Documentation**: Comprehensive guides and references

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

Built on the shoulders of giants:
- **Open WebUI** - Modern AI chat interface
- **Ollama** - Local LLM runtime
- **Mem0** - AI memory framework
- **Langfuse** - LLM observability platform
- **Qdrant** - Vector database
- **Perplexity** - Web search API

---

**NumberOne OWU** - Where AI meets privacy, performance, and possibility. 🚀
