# Chatterbox - macOS Text-to-Speech App

A native macOS application for high-quality text-to-speech synthesis powered by Apple's MLX framework and mlx-audio, optimized for Apple Silicon.

## Features

- **High-Quality TTS**: Uses MLX Audio for fast, natural-sounding speech generation
- **Apple Silicon Optimized**: Up to 40% faster than traditional frameworks on M-series chips
- **Voice Cloning**: Clone voices from 3-10 second audio samples
- **Advanced Parameters**: Fine-tune speech with exaggeration, temperature, CFG weight, and more
- **Voice Presets**: 5 professionally tuned presets (Natural, Energetic, Calm, Professional, Storyteller)
- **Native macOS UI**: Built with SwiftUI following Apple Human Interface Guidelines
- **Keyboard Shortcuts**: Cmd+Return to generate, Cmd+Space to play/pause, Cmd+K to clear
- **Real-time Status**: Live progress indicators and status updates

## System Requirements

- **macOS**: 12.0 (Monterey) or later
- **Hardware**: Apple Silicon (M1/M2/M3/M4) recommended for optimal performance
- **Python**: 3.9 or later
- **Xcode**: 15.0 or later (for building the app)

## Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd chatterbox
```

### 2. Set Up Python Backend

The app requires a Python backend server. The virtual environment will be automatically created when you first run the app, but you can set it up manually:

```bash
# Make setup script executable
chmod +x setup_venv.py

# Run setup (optional - app will do this automatically)
python3 setup_venv.py
```

This will:
- Create a virtual environment in `./venv`
- Install all required Python packages
- Generate `venv_config.json` with configuration

### 3. Build the macOS App

#### Option A: Using Xcode

1. Open `chatterbox.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Build and run (Cmd+R)

#### Option B: Using Command Line

```bash
xcodebuild -project chatterbox.xcodeproj -scheme chatterbox -configuration Release build
```

## Usage

### First Launch

1. Launch the Chatterbox app
2. Wait for the Python backend to initialize (first launch may take 30-60 seconds)
3. The status indicator will turn green when ready

### Basic Text-to-Speech

1. Enter text in the input field (max 1,000 characters)
2. Click "Generate Speech" or press Cmd+Return
3. The generated speech will play automatically
4. Use the Play/Pause button or Cmd+Space to control playback

### Voice Cloning

1. Click "Choose Audio File" under Voice Configuration
2. Select a 3-10 second audio file with clear speech
3. Generate speech - it will use the voice from your sample

### Using Presets

1. Click the "Presets" button to open the presets panel
2. Select a preset (Natural, Energetic, Calm, Professional, or Storyteller)
3. The parameters will automatically adjust
4. Click "Reset to Defaults" to restore default settings

### Advanced Settings

Fine-tune speech generation with these parameters:

- **Exaggeration** (0.0-2.0): Voice expressiveness and emotion
- **CFG Weight** (0.0-1.0): Classifier-free guidance strength
- **Temperature** (0.1-2.0): Randomness in generation
- **Repetition Penalty** (1.0-2.0): Reduces repetitive patterns
- **Min P** (0.0-0.2): Minimum probability threshold
- **Top P** (0.1-1.0): Nucleus sampling threshold

### Keyboard Shortcuts

- **Cmd+Return**: Generate speech
- **Cmd+Space**: Play/pause audio
- **Cmd+K**: Clear text input

## Project Structure

```
chatterbox/
├── chatterbox/                 # Swift source code
│   ├── chatterboxApp.swift    # App entry point
│   ├── ContentView.swift      # Main UI
│   ├── TTSManager.swift       # TTS business logic
│   ├── ServerManager.swift    # Python backend manager
│   └── VoicePreset.swift      # Voice presets
├── chatterbox_server.py       # Python TTS server
├── setup_venv.py              # Virtual environment setup
├── requirements.txt           # Python dependencies
├── CHANGELOG.md              # Version history
└── README.md                 # This file
```

## Architecture

The app uses a client-server architecture:

- **Swift Frontend**: Native macOS UI built with SwiftUI
- **Python Backend**: Flask server running MLX Audio for TTS generation
- **Communication**: HTTP/JSON API on localhost:8765

### API Endpoints

- `GET /health` - Health check
- `POST /` - Command endpoint
  - `init` - Initialize TTS model
  - `generate` - Generate speech from text
  - `shutdown` - Gracefully shutdown server

## Python Backend Details

### Dependencies

- **mlx**: Apple's ML framework for Apple Silicon
- **mlx-audio**: TTS library built on MLX
- **flask**: Web server framework
- **numpy, soundfile, scipy**: Audio processing
- **transformers, huggingface-hub**: Model handling

### Manual Backend Testing

You can test the Python backend independently:

```bash
# Activate virtual environment
source venv/bin/activate

# Run server
python chatterbox_server.py

# Test health endpoint (in another terminal)
curl http://localhost:8765/health

# Test initialization
curl -X POST http://localhost:8765 \
  -H "Content-Type: application/json" \
  -d '{"command": "init"}'
```

## Troubleshooting

### Server Won't Start

1. Check Python installation: `python3 --version`
2. Verify virtual environment exists: `ls venv/`
3. Reinstall dependencies: `rm -rf venv && python3 setup_venv.py`
4. Check server logs in Xcode console

### Model Initialization Fails

1. Ensure you have enough disk space (models ~500MB-2GB)
2. Check internet connection (first run downloads models)
3. Verify Apple Silicon compatibility
4. Check Python backend logs

### Audio Doesn't Play

1. Check macOS audio output settings
2. Verify audio permissions in System Settings
3. Try restarting the app
4. Check for errors in status section

### Performance Issues

1. Close other resource-intensive apps
2. Ensure running on Apple Silicon (not Rosetta)
3. Check Activity Monitor for CPU/memory usage
4. Consider using shorter text segments

## Development

### Building from Source

```bash
# Install Python dependencies
python3 setup_venv.py

# Build with Xcode
xcodebuild -project chatterbox.xcodeproj \
  -scheme chatterbox \
  -configuration Debug \
  build
```

### Running Tests

```bash
# Swift tests
xcodebuild test -project chatterbox.xcodeproj \
  -scheme chatterbox

# Python tests (if you add them)
source venv/bin/activate
pytest tests/
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Known Issues

- First launch may be slow while downloading ML models
- Voice cloning quality depends on reference audio quality
- Maximum text length limited to 1,000 characters

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and release notes.

## License

[Add your license here]

## Credits

- Built with Apple's MLX framework
- Uses mlx-audio for TTS synthesis
- UI design follows Apple Human Interface Guidelines

## Support

For issues and questions:
- Open an issue on GitHub
- Check existing issues for solutions
- Review troubleshooting section above

---

**Note**: This app requires Apple Silicon for optimal performance. While it may run on Intel Macs, performance will be significantly reduced.
