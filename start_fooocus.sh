#!/usr/bin/env bash
set -euo pipefail

# Navigate to fooocus directory
cd "/Users/hassan/local-ai/fooocus"

echo "Verifying/Installing Fooocus dependencies..."
# Installs/updates python packages for Fooocus (e.g. diffusers, gradio, torch, etc.)
pip install -r requirements_versions.txt

echo "Starting Fooocus offline SDXL..."
# Enable PyTorch MPS GPU fallback for Apple Silicon
export PYTORCH_ENABLE_MPS_FALLBACK=1

# Launch the Fooocus Web UI
python entry_with_update.py
