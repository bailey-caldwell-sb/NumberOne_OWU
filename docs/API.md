# 🔌 NumberOne OWU - API Reference

## Overview

NumberOne OWU provides multiple API endpoints for interacting with the AI platform programmatically. This document covers all available APIs and their usage.

## 🌐 Service Endpoints

### Core Services

| Service | Port | Endpoint | Description |
|---------|------|----------|-------------|
| Open WebUI | 3000 | http://localhost:3000 | Main AI chat interface |
| Ollama | 11434 | http://localhost:11434 | Local LLM API |
| Qdrant | 6333 | http://localhost:6333 | Vector database |
| Langfuse | 3003 | http://localhost:3003 | LLM observability |
| Pipelines | 9099 | http://localhost:9099 | AI processing filters |
| Dashboard | 8080 | http://localhost:8080 | System monitoring |

## 🤖 Open WebUI API

### Authentication

```bash
# Get API token (after login)
curl -X POST http://localhost:3000/api/v1/auths/signin \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "password"}'
```

### Chat Completions

```bash
# Send chat message
curl -X POST http://localhost:3000/api/chat/completions \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5:7b",
    "messages": [
      {"role": "user", "content": "Hello, how are you?"}
    ],
    "stream": false
  }'
```

### Models

```bash
# List available models
curl -X GET http://localhost:3000/api/models \
  -H "Authorization: Bearer YOUR_TOKEN"

# Get model details
curl -X GET http://localhost:3000/api/models/qwen2.5:7b \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Conversations

```bash
# List conversations
curl -X GET http://localhost:3000/api/chats \
  -H "Authorization: Bearer YOUR_TOKEN"

# Get conversation history
curl -X GET http://localhost:3000/api/chats/CHAT_ID \
  -H "Authorization: Bearer YOUR_TOKEN"

# Delete conversation
curl -X DELETE http://localhost:3000/api/chats/CHAT_ID \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 🧠 Ollama API

### Models Management

```bash
# List installed models
curl http://localhost:11434/api/tags

# Pull a model
curl -X POST http://localhost:11434/api/pull \
  -d '{"name": "qwen2.5:7b"}'

# Delete a model
curl -X DELETE http://localhost:11434/api/delete \
  -d '{"name": "model_name"}'
```

### Generate Completions

```bash
# Generate text
curl -X POST http://localhost:11434/api/generate \
  -d '{
    "model": "qwen2.5:7b",
    "prompt": "Why is the sky blue?",
    "stream": false
  }'

# Chat format
curl -X POST http://localhost:11434/api/chat \
  -d '{
    "model": "qwen2.5:7b",
    "messages": [
      {"role": "user", "content": "Hello!"}
    ]
  }'
```

### Embeddings

```bash
# Generate embeddings
curl -X POST http://localhost:11434/api/embeddings \
  -d '{
    "model": "nomic-embed-text",
    "prompt": "The sky is blue because of Rayleigh scattering"
  }'
```

## 🔍 Qdrant API

### Collections

```bash
# List collections
curl http://localhost:6333/collections

# Get collection info
curl http://localhost:6333/collections/memories

# Create collection
curl -X PUT http://localhost:6333/collections/my_collection \
  -H "Content-Type: application/json" \
  -d '{
    "vectors": {
      "size": 768,
      "distance": "Cosine"
    }
  }'
```

### Points (Vectors)

```bash
# Search vectors
curl -X POST http://localhost:6333/collections/memories/points/search \
  -H "Content-Type: application/json" \
  -d '{
    "vector": [0.1, 0.2, 0.3, ...],
    "limit": 5
  }'

# Insert points
curl -X PUT http://localhost:6333/collections/memories/points \
  -H "Content-Type: application/json" \
  -d '{
    "points": [
      {
        "id": 1,
        "vector": [0.1, 0.2, 0.3, ...],
        "payload": {"text": "Sample text"}
      }
    ]
  }'
```

## 📊 Langfuse API

### Authentication

```bash
# Set environment variables
export LANGFUSE_SECRET_KEY="sk-lf-..."
export LANGFUSE_PUBLIC_KEY="pk-lf-..."
```

### Traces

```bash
# Create trace
curl -X POST http://localhost:3003/api/public/traces \
  -H "Authorization: Bearer $LANGFUSE_SECRET_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "chat-completion",
    "userId": "user123",
    "metadata": {"model": "qwen2.5:7b"}
  }'

# Get traces
curl -X GET http://localhost:3003/api/public/traces \
  -H "Authorization: Bearer $LANGFUSE_SECRET_KEY"
```

### Generations

```bash
# Create generation
curl -X POST http://localhost:3003/api/public/generations \
  -H "Authorization: Bearer $LANGFUSE_SECRET_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "traceId": "trace-id",
    "name": "llm-generation",
    "model": "qwen2.5:7b",
    "input": "Hello, how are you?",
    "output": "I am doing well, thank you!",
    "usage": {
      "input": 5,
      "output": 8,
      "total": 13
    }
  }'
```

## 🔧 Pipelines API

### Pipeline Management

```bash
# List pipelines
curl -H "Authorization: Bearer 0p3n-w3bu!" \
  http://localhost:9099/pipelines

# Get pipeline details
curl -H "Authorization: Bearer 0p3n-w3bu!" \
  http://localhost:9099/pipelines/mem0_memory_filter

# Update pipeline valves
curl -X POST http://localhost:9099/pipelines/mem0_memory_filter/valves/update \
  -H "Authorization: Bearer 0p3n-w3bu!" \
  -H "Content-Type: application/json" \
  -d '{
    "store_cycles": 5,
    "mem_zero_user": "new_user"
  }'
```

### Health Check

```bash
# Check pipeline health
curl http://localhost:9099/health
```

## 📈 Dashboard API

### System Status

```bash
# Get system status
curl http://localhost:8080/api/status

# Get service health
curl http://localhost:8080/api/services

# Get system metrics
curl http://localhost:8080/api/system
```

### Real-time Updates

```javascript
// WebSocket connection for real-time updates
const ws = new WebSocket('ws://localhost:8081');

ws.onmessage = function(event) {
    const data = JSON.parse(event.data);
    console.log('System update:', data);
};
```

## 🔍 Perplexity Search API

### Direct API Usage

```bash
# Search with Perplexity API
curl -X POST https://api.perplexity.ai/chat/completions \
  -H "Authorization: Bearer $PERPLEXITY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama-3.1-sonar-large-128k-online",
    "messages": [
      {"role": "user", "content": "What are the latest developments in AI?"}
    ]
  }'
```

### Through Pipeline

```bash
# Trigger search through Open WebUI
curl -X POST http://localhost:3000/api/chat/completions \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5:7b",
    "messages": [
      {"role": "user", "content": "search: latest AI developments"}
    ]
  }'
```

## 🐍 Python SDK Examples

### Open WebUI Client

```python
import requests

class OpenWebUIClient:
    def __init__(self, base_url="http://localhost:3000", token=None):
        self.base_url = base_url
        self.token = token
        self.headers = {"Authorization": f"Bearer {token}"} if token else {}
    
    def chat(self, message, model="qwen2.5:7b"):
        response = requests.post(
            f"{self.base_url}/api/chat/completions",
            headers=self.headers,
            json={
                "model": model,
                "messages": [{"role": "user", "content": message}],
                "stream": False
            }
        )
        return response.json()
    
    def list_models(self):
        response = requests.get(
            f"{self.base_url}/api/models",
            headers=self.headers
        )
        return response.json()

# Usage
client = OpenWebUIClient(token="your_token")
response = client.chat("Hello, how are you?")
print(response)
```

### Ollama Client

```python
import requests

class OllamaClient:
    def __init__(self, base_url="http://localhost:11434"):
        self.base_url = base_url
    
    def generate(self, model, prompt):
        response = requests.post(
            f"{self.base_url}/api/generate",
            json={
                "model": model,
                "prompt": prompt,
                "stream": False
            }
        )
        return response.json()
    
    def list_models(self):
        response = requests.get(f"{self.base_url}/api/tags")
        return response.json()

# Usage
ollama = OllamaClient()
result = ollama.generate("qwen2.5:7b", "Explain quantum computing")
print(result["response"])
```

### Qdrant Client

```python
from qdrant_client import QdrantClient

# Connect to Qdrant
client = QdrantClient(host="localhost", port=6333)

# Search for similar vectors
results = client.search(
    collection_name="memories",
    query_vector=[0.1, 0.2, 0.3, ...],  # Your query vector
    limit=5
)

print(results)
```

### Langfuse Client

```python
from langfuse import Langfuse

# Initialize Langfuse
langfuse = Langfuse(
    secret_key="sk-lf-...",
    public_key="pk-lf-...",
    host="http://localhost:3003"
)

# Create a trace
trace = langfuse.trace(
    name="chat-completion",
    user_id="user123"
)

# Add generation
generation = trace.generation(
    name="llm-call",
    model="qwen2.5:7b",
    input="Hello!",
    output="Hi there!"
)

# Finalize
generation.end()
```

## 🔐 Authentication & Security

### API Key Management

```bash
# Generate API key for Open WebUI
curl -X POST http://localhost:3000/api/v1/auths/api_key \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"comment": "API access"}'
```

### Rate Limiting

Most APIs implement rate limiting:
- Open WebUI: 100 requests/minute per user
- Ollama: No built-in limits (hardware dependent)
- Qdrant: 1000 requests/second
- Langfuse: 1000 requests/minute

### CORS Configuration

```javascript
// Frontend CORS setup
const response = await fetch('http://localhost:3000/api/models', {
    method: 'GET',
    headers: {
        'Authorization': 'Bearer ' + token,
        'Content-Type': 'application/json'
    },
    mode: 'cors'
});
```

## 📝 Response Formats

### Standard Response

```json
{
    "success": true,
    "data": {...},
    "message": "Operation completed successfully",
    "timestamp": "2024-12-04T10:30:00Z"
}
```

### Error Response

```json
{
    "success": false,
    "error": {
        "code": "INVALID_REQUEST",
        "message": "Invalid model specified",
        "details": {...}
    },
    "timestamp": "2024-12-04T10:30:00Z"
}
```

## 🔧 Troubleshooting API Issues

### Common HTTP Status Codes

- `200` - Success
- `400` - Bad Request (invalid parameters)
- `401` - Unauthorized (invalid token)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found (resource doesn't exist)
- `429` - Too Many Requests (rate limited)
- `500` - Internal Server Error

### Debug API Calls

```bash
# Enable verbose curl output
curl -v -X GET http://localhost:3000/api/models

# Check service health
curl http://localhost:3000/health
curl http://localhost:11434/api/tags
curl http://localhost:6333/health
```

This API reference provides comprehensive coverage of all NumberOne OWU endpoints. For additional examples and advanced usage, refer to the other documentation files.
