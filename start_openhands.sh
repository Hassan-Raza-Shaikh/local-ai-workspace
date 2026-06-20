#!/usr/bin/env bash
set -euo pipefail

# Create workspace directory for OpenHands
WORKSPACE_DIR="/Users/hassan/local-ai/openhands_workspace"
mkdir -p "$WORKSPACE_DIR"

echo "Checking if there is an existing OpenHands container..."
if docker ps -a --format '{{.Names}}' | grep -Eq "^openhands$"; then
    echo "Stopping and removing old container..."
    docker stop openhands || true
    docker rm openhands || true
fi

echo "Starting OpenHands on http://localhost:3001..."
docker run -d \
  --name openhands \
  -p 3001:3000 \
  -e SANDBOX_USER_ID=$(id -u) \
  -e SANDBOX_VOLUMES="$WORKSPACE_DIR:/workspace:rw" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --pull=always \
  docker.openhands.dev/openhands/openhands:latest

echo "OpenHands container is starting up!"
echo "Access it at http://localhost:3001"
