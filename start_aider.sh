#!/usr/bin/env bash
set -euo pipefail

# Source environment variables for LLM keys (like GEMINI_API_KEY)
if [ -f "/Users/hassan/local-ai/.env" ]; then
    export $(grep -v '^#' /Users/hassan/local-ai/.env | xargs)
fi

# Ensure log directory exists
mkdir -p /Users/hassan/local-ai/logs

# Use Gemini 2.5 Flash by default
DEFAULT_MODEL="gemini/gemini-2.5-flash"

if [[ "${1:-}" == "--gui" ]]; then
    echo "Starting Aider Web GUI in the background..."
    # Launch Aider GUI headlessly in the background, letting Streamlit open the browser automatically
    /opt/miniconda3/bin/aider --model "$DEFAULT_MODEL" --gui > /Users/hassan/local-ai/logs/aider_gui.log 2>&1 &
    echo "✔ Aider GUI started!"
    echo "  - Logs: /Users/hassan/local-ai/logs/aider_gui.log"
else
    echo "Starting Aider CLI pair programmer..."
    echo "Type /exit to return to launcher menu."
    # Launch Aider CLI in the foreground
    /opt/miniconda3/bin/aider --model "$DEFAULT_MODEL"
fi
