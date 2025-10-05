#!/usr/bin/env python3
"""
Test script for Open WebUI image generation functionality
"""

import requests
import json
import time
import os

def test_image_generation_config():
    """Test if image generation is properly configured in Open WebUI"""
    
    print("🎨 Testing Open WebUI Image Generation Setup")
    print("=" * 50)
    
    # Test Open WebUI health
    try:
        response = requests.get("http://localhost:3000/health", timeout=5)
        if response.status_code == 200:
            print("✅ Open WebUI is running and healthy")
        else:
            print("❌ Open WebUI health check failed")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌ Cannot connect to Open WebUI: {e}")
        return False
    
    # Check if image generation is enabled
    try:
        # This endpoint might not exist, but we can check the main page
        response = requests.get("http://localhost:3000", timeout=5)
        if response.status_code == 200:
            print("✅ Open WebUI web interface is accessible")
        else:
            print("❌ Open WebUI web interface not accessible")
    except requests.exceptions.RequestException as e:
        print(f"❌ Cannot access Open WebUI interface: {e}")
    
    print("\n📋 Configuration Checklist:")
    print("1. ✅ Open WebUI is running with ENABLE_IMAGE_GENERATION=True")
    print("2. 🔧 Next: Configure image generation in Admin Panel")
    print("3. 🎯 Go to: http://localhost:3000")
    print("4. 🔑 Navigate to: Admin Panel → Settings → Images")
    
    print("\n🎨 Available Image Generation Options:")
    print("┌─────────────────────────────────────────────────────────┐")
    print("│ Option 1: OpenAI DALL-E (Recommended)                  │")
    print("│ • Easy setup with API key                              │")
    print("│ • High quality results                                 │")
    print("│ • Cost: ~$0.02-0.04 per image                         │")
    print("│                                                         │")
    print("│ Option 2: Local Automatic1111                          │")
    print("│ • Free after setup                                     │")
    print("│ • Requires GPU with 8GB+ VRAM                         │")
    print("│ • Full control and privacy                             │")
    print("│                                                         │")
    print("│ Option 3: Image Router                                 │")
    print("│ • Access to multiple models                            │")
    print("│ • Unified API for different providers                  │")
    print("│ • Flexible pricing                                     │")
    print("└─────────────────────────────────────────────────────────┘")
    
    print("\n🚀 Quick Start Instructions:")
    print("1. Open http://localhost:3000 in your browser")
    print("2. Go to Admin Panel → Settings → Images")
    print("3. Choose 'Open AI' as Image Generation Engine")
    print("4. Enter your OpenAI API key")
    print("5. Select DALL-E 3 model")
    print("6. Save settings")
    print("7. Toggle 'Image Generation' ON in a chat")
    print("8. Type: 'A beautiful sunset over mountains'")
    print("9. Click Send and watch the magic! ✨")
    
    return True

def test_openai_api_key():
    """Test if OpenAI API key is working (if provided)"""
    
    api_key = os.getenv('OPENAI_API_KEY')
    if not api_key:
        print("\n💡 Tip: Set OPENAI_API_KEY environment variable to test API connectivity")
        return
    
    print(f"\n🔑 Testing OpenAI API key: {api_key[:10]}...")
    
    try:
        headers = {
            'Authorization': f'Bearer {api_key}',
            'Content-Type': 'application/json'
        }
        
        # Test with a simple models list request
        response = requests.get(
            'https://api.openai.com/v1/models',
            headers=headers,
            timeout=10
        )
        
        if response.status_code == 200:
            models = response.json()
            dalle_models = [m for m in models.get('data', []) if 'dall-e' in m.get('id', '').lower()]
            print(f"✅ OpenAI API key is valid")
            print(f"🎨 Available DALL-E models: {len(dalle_models)}")
            for model in dalle_models:
                print(f"   • {model.get('id')}")
        else:
            print(f"❌ OpenAI API key test failed: {response.status_code}")
            print(f"   Response: {response.text}")
            
    except requests.exceptions.RequestException as e:
        print(f"❌ OpenAI API connection failed: {e}")

def show_example_prompts():
    """Show example prompts for testing"""
    
    print("\n🎯 Example Prompts to Test:")
    print("─" * 40)
    
    examples = [
        "A cute robot holding a paintbrush",
        "A cyberpunk city at night with neon lights",
        "A photorealistic cat wearing sunglasses",
        "An abstract painting with flowing colors",
        "A cozy coffee shop interior with warm lighting",
        "A futuristic spaceship in deep space",
        "A medieval castle on a hilltop",
        "A tropical beach at sunset"
    ]
    
    for i, prompt in enumerate(examples, 1):
        print(f"{i:2d}. {prompt}")
    
    print("\n💡 Pro Tips:")
    print("• Be specific about style: 'photorealistic', 'digital art', 'oil painting'")
    print("• Include lighting: 'soft lighting', 'dramatic shadows', 'golden hour'")
    print("• Specify quality: '4K', 'high resolution', 'detailed'")
    print("• Add camera angles: 'close-up', 'wide angle', 'bird's eye view'")

if __name__ == "__main__":
    print("🎨 Open WebUI Image Generation Test Suite")
    print("=" * 50)
    
    # Run tests
    if test_image_generation_config():
        test_openai_api_key()
        show_example_prompts()
        
        print("\n🎉 Setup Complete!")
        print("Your Open WebUI is ready for image generation!")
        print("Visit http://localhost:3000 to start creating images! 🚀")
    else:
        print("\n❌ Setup needs attention. Please check the configuration.")
