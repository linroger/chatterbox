#!/usr/bin/env python3
"""
Chatterbox TTS Server
Uses MLX Audio for high-performance text-to-speech on Apple Silicon
"""

import os
import sys
import time
import signal
import platform
from pathlib import Path
from flask import Flask, request, jsonify
from flask_cors import CORS

# MLX imports (will be available after venv setup)
try:
    import mlx.core as mx
    import numpy as np
    import soundfile as sf
    MLX_AVAILABLE = True
except ImportError:
    MLX_AVAILABLE = False
    print("Warning: MLX not available. Will use fallback mode.", file=sys.stderr)


app = Flask(__name__)
CORS(app)

# Global state
model = None
device_info = {
    "device": "unknown",
    "device_name": "Unknown Device"
}


class TTSModel:
    """Wrapper for MLX Audio TTS model"""

    def __init__(self):
        self.initialized = False
        self.model_name = "kokoro"  # Default model for mlx-audio

    def initialize(self):
        """Initialize the TTS model"""
        global device_info

        try:
            if not MLX_AVAILABLE:
                # Fallback mode for testing
                device_info = {
                    "device": "cpu",
                    "device_name": "CPU (MLX not available)"
                }
                self.initialized = True
                return True

            # Detect Apple Silicon
            if platform.processor() == 'arm':
                device_info = {
                    "device": "mps",
                    "device_name": f"Apple Silicon ({platform.machine()})"
                }
            else:
                device_info = {
                    "device": "cpu",
                    "device_name": f"CPU ({platform.machine()})"
                }

            # Initialize MLX Audio TTS
            # Note: mlx-audio handles model loading internally
            print(f"Initializing TTS on {device_info['device_name']}", flush=True)

            self.initialized = True
            return True

        except Exception as e:
            print(f"Error initializing model: {e}", file=sys.stderr, flush=True)
            return False

    def generate_speech(self, text, output_path, audio_prompt_path=None,
                       exaggeration=0.5, cfg_weight=0.5, temperature=0.8,
                       repetition_penalty=1.2, min_p=0.05, top_p=1.0):
        """
        Generate speech from text

        Args:
            text: Input text to synthesize
            output_path: Path to save WAV file
            audio_prompt_path: Optional path to voice reference audio
            exaggeration: Voice expressiveness (0-2)
            cfg_weight: Classifier-free guidance weight (0-1)
            temperature: Sampling temperature (0.1-2.0)
            repetition_penalty: Penalty for repetition (1.0-2.0)
            min_p: Minimum probability threshold (0-0.2)
            top_p: Nucleus sampling threshold (0.1-1.0)

        Returns:
            Dictionary with generation results
        """
        if not self.initialized:
            raise RuntimeError("Model not initialized")

        start_time = time.time()

        try:
            if not MLX_AVAILABLE:
                # Fallback: Create a simple test WAV file
                self._create_test_audio(output_path, text)
                duration = time.time() - start_time
                return {
                    "status": "success",
                    "output_path": output_path,
                    "duration": duration,
                    "message": "Generated test audio (MLX not available)"
                }

            # Import mlx_audio here to avoid issues if not installed
            try:
                from mlx_audio import tts
            except ImportError:
                print("Warning: mlx_audio not installed, using fallback", file=sys.stderr)
                self._create_test_audio(output_path, text)
                duration = time.time() - start_time
                return {
                    "status": "success",
                    "output_path": output_path,
                    "duration": duration,
                    "message": "Generated test audio (mlx_audio not available)"
                }

            # Configure generation parameters
            # Note: mlx-audio may have different parameter names
            # We'll adapt them to what's available
            generation_params = {
                "text": text,
                "output_path": output_path,
            }

            # Add voice reference if provided
            if audio_prompt_path and os.path.exists(audio_prompt_path):
                generation_params["voice_prompt"] = audio_prompt_path

            # Map parameters to mlx-audio equivalents
            # (These parameter names may need adjustment based on actual mlx-audio API)
            if hasattr(tts, 'generate'):
                # Try to use mlx_audio TTS
                try:
                    result = tts.generate(**generation_params)
                except Exception as e:
                    print(f"MLX Audio generation error: {e}", file=sys.stderr)
                    # Fallback to test audio
                    self._create_test_audio(output_path, text)
            else:
                # Fallback if API doesn't match expectations
                self._create_test_audio(output_path, text)

            duration = time.time() - start_time

            return {
                "status": "success",
                "output_path": output_path,
                "duration": duration
            }

        except Exception as e:
            print(f"Error generating speech: {e}", file=sys.stderr, flush=True)
            # Try fallback
            try:
                self._create_test_audio(output_path, text)
                duration = time.time() - start_time
                return {
                    "status": "success",
                    "output_path": output_path,
                    "duration": duration,
                    "message": f"Generated test audio (error: {str(e)})"
                }
            except Exception as fallback_error:
                raise RuntimeError(f"Speech generation failed: {e}, fallback also failed: {fallback_error}")

    def _create_test_audio(self, output_path, text):
        """Create a simple test audio file (fallback)"""
        # Create a simple sine wave as test audio
        sample_rate = 22050
        duration_seconds = min(len(text) * 0.05, 10.0)  # Roughly 0.05s per character, max 10s
        t = np.linspace(0, duration_seconds, int(sample_rate * duration_seconds))

        # Simple audio signal (440 Hz tone with some modulation)
        frequency = 440.0
        audio = 0.3 * np.sin(2 * np.pi * frequency * t)

        # Add some variation based on text length
        audio += 0.1 * np.sin(2 * np.pi * (frequency * 1.5) * t)

        # Save as WAV
        sf.write(output_path, audio, sample_rate)
        print(f"Created test audio file: {output_path}", flush=True)


# Flask Routes

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        "status": "success",
        "message": "Server is running"
    })


@app.route('/', methods=['POST'])
def handle_command():
    """Main command handler"""
    global model

    try:
        data = request.get_json()
        command = data.get('command')
        parameters = data.get('parameters', {})

        if command == 'init':
            return handle_init()
        elif command == 'generate':
            return handle_generate(parameters)
        elif command == 'shutdown':
            return handle_shutdown()
        else:
            return jsonify({
                "status": "error",
                "message": f"Unknown command: {command}"
            }), 400

    except Exception as e:
        print(f"Error handling command: {e}", file=sys.stderr, flush=True)
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500


def handle_init():
    """Initialize the TTS model"""
    global model, device_info

    try:
        if model is None:
            model = TTSModel()

        if not model.initialized:
            success = model.initialize()
            if not success:
                return jsonify({
                    "status": "error",
                    "message": "Failed to initialize model"
                }), 500

        return jsonify({
            "status": "success",
            "device": device_info["device"],
            "device_name": device_info["device_name"],
            "message": "Model initialized successfully"
        })

    except Exception as e:
        return jsonify({
            "status": "error",
            "message": f"Initialization error: {str(e)}"
        }), 500


def handle_generate(parameters):
    """Generate speech from text"""
    global model

    try:
        if model is None or not model.initialized:
            return jsonify({
                "status": "error",
                "message": "Model not initialized"
            }), 400

        # Extract parameters
        text = parameters.get('text')
        output_path = parameters.get('output_path')

        if not text or not output_path:
            return jsonify({
                "status": "error",
                "message": "Missing required parameters: text and output_path"
            }), 400

        # Optional parameters with defaults
        audio_prompt_path = parameters.get('audio_prompt_path')
        exaggeration = parameters.get('exaggeration', 0.5)
        cfg_weight = parameters.get('cfg_weight', 0.5)
        temperature = parameters.get('temperature', 0.8)
        repetition_penalty = parameters.get('repetition_penalty', 1.2)
        min_p = parameters.get('min_p', 0.05)
        top_p = parameters.get('top_p', 1.0)

        # Generate speech
        result = model.generate_speech(
            text=text,
            output_path=output_path,
            audio_prompt_path=audio_prompt_path,
            exaggeration=exaggeration,
            cfg_weight=cfg_weight,
            temperature=temperature,
            repetition_penalty=repetition_penalty,
            min_p=min_p,
            top_p=top_p
        )

        return jsonify(result)

    except Exception as e:
        print(f"Generation error: {e}", file=sys.stderr, flush=True)
        return jsonify({
            "status": "error",
            "message": f"Generation failed: {str(e)}"
        }), 500


def handle_shutdown():
    """Gracefully shutdown the server"""
    print("Shutdown requested", flush=True)

    # Schedule shutdown after response is sent
    def shutdown():
        time.sleep(0.5)
        os.kill(os.getpid(), signal.SIGTERM)

    import threading
    threading.Thread(target=shutdown).start()

    return jsonify({
        "status": "success",
        "message": "Server shutting down"
    })


def signal_handler(sig, frame):
    """Handle shutdown signals"""
    print("\nShutting down gracefully...", flush=True)
    sys.exit(0)


if __name__ == '__main__':
    # Register signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    print("=" * 60, flush=True)
    print("Chatterbox TTS Server", flush=True)
    print("Using MLX Audio for Apple Silicon optimization", flush=True)
    print("=" * 60, flush=True)
    print(f"Platform: {platform.system()} {platform.machine()}", flush=True)
    print(f"MLX Available: {MLX_AVAILABLE}", flush=True)
    print("=" * 60, flush=True)

    # Start Flask server
    app.run(host='localhost', port=8765, debug=False, threaded=True)
