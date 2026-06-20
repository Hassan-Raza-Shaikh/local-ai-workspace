#!/usr/bin/env bash
set -euo pipefail

# Navigate to comfyui directory
cd "/Users/hassan/local-ai/comfyui"

echo "Verifying/Installing ComfyUI dependencies..."
# Install the pre-downloaded comfyui_workflow_templates_media_api wheel if present
if [ -f "../comfyui_workflow_templates_media_api-0.3.80-py3-none-any.whl" ]; then
    echo "Found comfyui_workflow_templates_media_api wheel. Installing..."
    pip install "../comfyui_workflow_templates_media_api-0.3.80-py3-none-any.whl"
fi

# Installs/updates remaining python packages for ComfyUI
pip install -r requirements.txt

echo "Starting ComfyUI offline image generator..."
# Optimize memory management on macOS MPS
export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0

# Launch ComfyUI
python main.py --port 8188
