#!/usr/bin/env python3
"""
Virtual Environment Setup Script for Chatterbox
Creates a Python virtual environment and installs required dependencies
"""

import os
import sys
import subprocess
import json
from pathlib import Path


def print_status(message):
    """Print status message with flush to ensure it's visible in real-time"""
    print(message, flush=True)


def run_command(cmd, description):
    """Run a command and handle errors"""
    print_status(f"{description}...")
    try:
        result = subprocess.run(
            cmd,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        return True
    except subprocess.CalledProcessError as e:
        print_status(f"Error: {e.stderr}")
        return False


def main():
    """Main setup function"""
    # Get the directory where this script is located
    script_dir = Path(__file__).parent.absolute()
    venv_dir = script_dir / "venv"
    requirements_file = script_dir / "requirements.txt"
    config_file = script_dir / "venv_config.json"

    print_status("=== Chatterbox Virtual Environment Setup ===")

    # Check if Python 3 is available
    try:
        python_version = subprocess.run(
            [sys.executable, "--version"],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        print_status(f"Using Python: {python_version.stdout.strip()}")
    except subprocess.CalledProcessError:
        print_status("Error: Python 3 not found")
        sys.exit(1)

    # Remove old venv if it exists
    if venv_dir.exists():
        print_status("Removing old virtual environment...")
        import shutil
        shutil.rmtree(venv_dir)

    # Create virtual environment
    if not run_command(
        [sys.executable, "-m", "venv", str(venv_dir)],
        "Creating virtual environment"
    ):
        sys.exit(1)

    # Determine the Python executable path in venv
    if sys.platform == "win32":
        python_executable = venv_dir / "Scripts" / "python.exe"
        pip_executable = venv_dir / "Scripts" / "pip.exe"
    else:
        python_executable = venv_dir / "bin" / "python"
        pip_executable = venv_dir / "bin" / "pip"

    # Upgrade pip
    if not run_command(
        [str(python_executable), "-m", "pip", "install", "--upgrade", "pip"],
        "Upgrading pip"
    ):
        print_status("Warning: Failed to upgrade pip, continuing anyway...")

    # Install requirements
    if requirements_file.exists():
        print_status("Installing dependencies from requirements.txt...")
        print_status("This may take several minutes...")

        if not run_command(
            [str(pip_executable), "install", "-r", str(requirements_file)],
            "Installing Python packages"
        ):
            print_status("Error: Failed to install requirements")
            sys.exit(1)
    else:
        print_status(f"Warning: requirements.txt not found at {requirements_file}")
        sys.exit(1)

    # Save configuration
    config = {
        "python_executable": str(python_executable),
        "venv_path": str(venv_dir),
        "requirements_file": str(requirements_file)
    }

    with open(config_file, "w") as f:
        json.dump(config, f, indent=2)

    print_status(f"Configuration saved to {config_file}")
    print_status("=== Setup Complete! ===")
    print_status(f"Virtual environment created at: {venv_dir}")
    print_status(f"Python executable: {python_executable}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
