# Chatterbox Quick Start Guide

Get up and running with Chatterbox in 5 minutes!

## Prerequisites

- macOS 12.0+ (Monterey or later)
- Python 3.9+ (check with: `python3 --version`)
- Xcode 15.0+ (for building the app)
- Apple Silicon Mac recommended (M1/M2/M3/M4)

## Quick Setup

### 1. First-Time Setup

```bash
# Clone or navigate to the repository
cd chatterbox

# The Python virtual environment will be set up automatically
# when you first run the app, but you can do it manually:
python3 setup_venv.py
```

This will:
- Create a virtual environment in `./venv`
- Install MLX and mlx-audio
- Install all required dependencies
- Take 2-5 minutes on first run

### 2. Run the App

#### Option A: Using Xcode (Recommended)

```bash
# Open in Xcode
open chatterbox.xcodeproj

# Press Cmd+R to build and run
```

#### Option B: Pre-built App

If you have a pre-built .app file:
```bash
# Just double-click the app or:
open Chatterbox.app
```

### 3. First Use

1. **Wait for Initialization** (30-60 seconds on first launch)
   - The app downloads ML models on first run
   - Status will show "Model initialized" when ready

2. **Generate Your First Speech**
   - Type some text in the input field
   - Press **Cmd+Return** or click "Generate Speech"
   - Audio will play automatically

## Common Issues

### Issue: "Server script not found"
**Solution**: Make sure you're running from the project directory that contains `chatterbox_server.py`

### Issue: "Virtual environment setup failed"
**Solution**:
```bash
# Manually set up the environment
rm -rf venv venv_config.json
python3 setup_venv.py
```

### Issue: Server won't start
**Solution**:
```bash
# Check Python version
python3 --version  # Should be 3.9+

# Check if port 8765 is in use
lsof -i :8765

# If in use, kill the process:
kill -9 <PID>
```

### Issue: Model initialization takes forever
**Solution**: First run downloads models (~500MB-2GB). Ensure good internet connection.

## Testing the Backend Manually

Want to test the Python server independently?

```bash
# Activate virtual environment
source venv/bin/activate

# Start server
python chatterbox_server.py
```

In another terminal:
```bash
# Test health endpoint
curl http://localhost:8765/health

# Expected response:
# {"status": "success", "message": "Server is running"}

# Test initialization
curl -X POST http://localhost:8765 \
  -H "Content-Type: application/json" \
  -d '{"command": "init"}'

# Expected response:
# {"status": "success", "device": "mps", "device_name": "Apple Silicon (arm64)"}
```

## Quick Tips

### Keyboard Shortcuts
- **Cmd+Return**: Generate speech
- **Cmd+Space**: Play/pause
- **Cmd+K**: Clear text

### Best Practices
1. Keep text under 1,000 characters
2. Use presets for quick parameter adjustments
3. For voice cloning, use clear 3-10 second audio samples
4. Close resource-intensive apps for best performance

### Voice Presets

Try these built-in presets:
- **Natural**: Balanced, everyday speech
- **Energetic**: Upbeat, enthusiastic
- **Calm**: Soothing, relaxed
- **Professional**: Clear, formal
- **Storyteller**: Expressive, dramatic

## Performance Notes

### Apple Silicon (Recommended)
- M1/M2/M3/M4 Macs: 2-5 seconds per generation
- Optimized for Metal Performance Shaders
- Up to 40% faster than traditional frameworks

### Intel Macs
- Will work but significantly slower
- May fall back to CPU-only mode
- Consider upgrading to Apple Silicon for best experience

## Next Steps

1. **Explore Advanced Settings**: Fine-tune exaggeration, temperature, etc.
2. **Try Voice Cloning**: Upload a voice sample for custom voices
3. **Export Audio**: Save generated speech as WAV files
4. **Adjust Presets**: Create your perfect voice profile

## Getting Help

- Check the full [README.md](README.md) for detailed documentation
- Review [CHANGELOG.md](CHANGELOG.md) for version history
- Report issues on GitHub

## Development Mode

Building from source:

```bash
# Debug build
xcodebuild -project chatterbox.xcodeproj \
  -scheme chatterbox \
  -configuration Debug

# Release build
xcodebuild -project chatterbox.xcodeproj \
  -scheme chatterbox \
  -configuration Release
```

---

**Happy Speech Generating!** 🎙️

For questions or issues, refer to the troubleshooting section in README.md
