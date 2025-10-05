#!/bin/bash

# 🚀 Install Fast Ollama Models Script
# This script installs the 3 fastest local Ollama models for lightning-fast responses

set -e

echo "🚀 Installing the 3 Fastest Ollama Models..."
echo "=============================================="

# Check if Ollama is installed and running
if ! command -v ollama &> /dev/null; then
    echo "❌ Ollama is not installed or not in PATH"
    echo "Please install Ollama first: https://ollama.ai"
    exit 1
fi

# Check if Ollama service is running
if ! ollama list &> /dev/null; then
    echo "❌ Ollama service is not running"
    echo "Please start Ollama service first"
    exit 1
fi

echo "✅ Ollama is installed and running"
echo ""

# Function to install model with progress
install_model() {
    local model=$1
    local description=$2
    local size=$3
    
    echo "📦 Installing $model ($description - $size)..."
    if ollama pull "$model"; then
        echo "✅ Successfully installed $model"
    else
        echo "❌ Failed to install $model"
        return 1
    fi
    echo ""
}

# Install the 3 fastest models
echo "Installing ultra-fast models for instant responses..."
echo ""

# 1. Qwen2.5 0.5B - Smallest and fastest
install_model "qwen2.5:0.5b" "Ultra Fast" "397 MB"

# 2. TinyLlama - Very fast and efficient
install_model "tinyllama" "Very Fast" "637 MB"

# 3. Llama3.2 1B - Best balance of speed and quality
install_model "llama3.2:1b" "Fast & Quality" "1.3 GB"

echo "🎉 All fast models installed successfully!"
echo ""

# Test the models
echo "🧪 Testing model response times..."
echo "=================================="

test_model() {
    local model=$1
    local description=$2
    
    echo "Testing $model ($description)..."
    start_time=$(date +%s.%N)
    
    if ollama run "$model" "Say hello in one sentence" >/dev/null 2>&1; then
        end_time=$(date +%s.%N)
        duration=$(echo "$end_time - $start_time" | bc -l)
        printf "✅ %s: %.2f seconds\n" "$description" "$duration"
    else
        echo "❌ $description: Test failed"
    fi
}

# Test all models
test_model "qwen2.5:0.5b" "Qwen2.5 0.5B"
test_model "tinyllama" "TinyLlama"
test_model "llama3.2:1b" "Llama3.2 1B"

echo ""
echo "📊 Model Summary:"
echo "┌─────────────────┬──────────┬─────────────────────────────┐"
echo "│ Model           │ Size     │ Best Use Case               │"
echo "├─────────────────┼──────────┼─────────────────────────────┤"
echo "│ qwen2.5:0.5b    │ 397 MB   │ Instant responses           │"
echo "│ tinyllama       │ 637 MB   │ Simple conversations        │"
echo "│ llama3.2:1b     │ 1.3 GB   │ Best speed/quality balance  │"
echo "└─────────────────┴──────────┴─────────────────────────────┘"

echo ""
echo "🎯 Usage Tips:"
echo "• Use qwen2.5:0.5b for quick questions and instant responses"
echo "• Use tinyllama for simple tasks and rapid prototyping"
echo "• Use llama3.2:1b for the best balance of speed and quality"
echo ""
echo "🚀 All models are now available in Open WebUI!"
echo "Switch between them in the model selector for different use cases."
echo ""
echo "✨ Installation complete! Enjoy lightning-fast AI responses! ⚡"
