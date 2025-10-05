# 🎨 Image Generation Setup for Open WebUI

## 🚀 Quick Setup Guide

Your Open WebUI is now configured with **image generation support enabled**! Here's how to set it up:

### Option 1: OpenAI DALL-E (Recommended - Easiest)

1. **Get OpenAI API Key**:
   - Go to https://platform.openai.com/api-keys
   - Create a new API key
   - Copy the key (starts with `sk-`)

2. **Configure in Open WebUI**:
   - Open http://localhost:3000
   - Go to **Admin Panel** → **Settings** → **Images**
   - Set **Image Generation Engine** to **"Open AI"**
   - Enter your **OpenAI API Key**
   - Choose model:
     - **DALL-E 3**: Best quality (1024x1024, 1792x1024, 1024x1792)
     - **DALL-E 2**: Faster/cheaper (256x256, 512x512, 1024x1024)
     - **GPT-Image-1**: Latest model (auto, 1024x1024, 1536x1024, 1024x1536)

3. **Test Image Generation**:
   - Toggle **Image Generation** switch to **ON**
   - Type: "A beautiful sunset over mountains"
   - Click **Send**
   - Image will generate and appear in chat!

### Option 2: Local Image Generation (Advanced)

For completely local image generation without API costs:

#### A. Automatic1111 Setup
```bash
# Install Automatic1111
git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git
cd stable-diffusion-webui

# Launch with API enabled
./webui.sh --api --listen --port 7860
```

**Configure in Open WebUI**:
- **Image Generation Engine**: "Default (Automatic1111)"
- **API URL**: `http://localhost:7860/`

#### B. ComfyUI Setup
```bash
# Install ComfyUI
git clone https://github.com/comfyanonymous/ComfyUI.git
cd ComfyUI

# Launch ComfyUI
python main.py --listen --port 8188
```

**Configure in Open WebUI**:
- **Image Generation Engine**: "ComfyUI"
- **API URL**: `http://localhost:8188/`

### Option 3: Image Router (Multiple Models)

For access to multiple image generation models:

1. **Get Image Router API Key**:
   - Go to https://imagerouter.io
   - Sign up and get API key

2. **Configure in Open WebUI**:
   - **Image Generation Engine**: "Open AI"
   - **API URL**: `https://api.imagerouter.io/v1/openai`
   - **API Key**: Your Image Router key
   - **Model**: Enter model name (e.g., "flux-1-dev", "midjourney", "stable-diffusion-xl")

## 🎯 How to Use Image Generation

### Method 1: Direct Generation
1. Toggle **Image Generation** switch to **ON**
2. Type your image prompt
3. Click **Send**
4. Wait for image to generate

### Method 2: From Chat Response
1. Chat with any AI model normally
2. After getting a text response, click the **🖼️ Picture icon**
3. Edit the prompt if needed
4. Generate image

### Method 3: Edit and Generate
1. Get a text response from AI
2. Click **Edit** on the response
3. Replace text with image prompt
4. Generate image from edited prompt

## 💡 Pro Tips

### Best Prompts for Image Generation:
- **Detailed descriptions**: "A photorealistic portrait of a cat wearing a red hat, sitting on a wooden table, soft lighting, 4K"
- **Style specifications**: "Digital art style", "Oil painting", "Photorealistic", "Cartoon style"
- **Lighting/mood**: "Golden hour lighting", "Dramatic shadows", "Soft ambient light"
- **Camera angles**: "Close-up", "Wide angle", "Bird's eye view", "Low angle"

### DALL-E 3 Specific Tips:
- More natural language works better
- Can handle complex scenes and compositions
- Excellent at text in images
- Best for photorealistic and artistic styles

### Cost Considerations:
- **DALL-E 3**: ~$0.04 per image (1024x1024)
- **DALL-E 2**: ~$0.02 per image (1024x1024)
- **Local generation**: Free after setup (requires GPU)

## 🔧 Troubleshooting

### Common Issues:

1. **"Image generation not available"**:
   - Check if `ENABLE_IMAGE_GENERATION=True` is set
   - Restart Open WebUI container
   - Verify API key is correct

2. **"API connection failed"**:
   - Check API URL format
   - Verify service is running (for local setups)
   - Check firewall/network settings

3. **"Quota exceeded"**:
   - Check OpenAI billing/usage limits
   - Consider switching to local generation

4. **Slow generation**:
   - DALL-E: Usually 10-30 seconds
   - Local: Depends on GPU (30 seconds - 5 minutes)
   - Try smaller image sizes for faster generation

### Performance Tips:
- **For local generation**: Use GPU with 8GB+ VRAM
- **For DALL-E**: Consider DALL-E 2 for faster/cheaper generation
- **Batch generation**: Generate multiple variations of same prompt

## 🎨 Example Prompts to Try

### Photorealistic:
- "A professional headshot of a business person in a modern office"
- "A steaming cup of coffee on a wooden table with morning sunlight"
- "A golden retriever playing in a field of sunflowers"

### Artistic:
- "A cyberpunk cityscape at night with neon lights, digital art style"
- "An abstract representation of music with flowing colors and shapes"
- "A fantasy castle on a floating island, oil painting style"

### Technical/Diagrams:
- "A simple flowchart showing the software development process"
- "An infographic about renewable energy sources"
- "A technical diagram of a computer network"

## 🚀 Next Steps

1. **Test the setup** with simple prompts
2. **Experiment** with different models and styles
3. **Integrate** image generation into your workflows
4. **Consider local setup** for privacy and cost savings
5. **Explore advanced features** like inpainting and outpainting

Your Open WebUI now has powerful image generation capabilities! Start creating amazing visuals to enhance your AI conversations. 🎨✨
