#!/usr/bin/env bash

# Local AI Workspace Startup Script
# Renamed and configured for /Users/hassan/local-ai

set -euo pipefail

# HSL customized color palette for console logging
BOLD="\033[1m"
GREEN="\033[32m"
BLUE="\033[34m"
YELLOW="\033[33m"
RED="\033[31m"
NC="\033[0m" # No Color

echo -e "${BOLD}${BLUE}===========================================${NC}"
echo -e "${BOLD}${BLUE}   Starting Local AI Workspace Dashboard   ${NC}"
echo -e "${BOLD}${BLUE}===========================================${NC}"

# 1. Verify Docker is running
echo -e "\n${BOLD}${BLUE}[1/4] Checking Docker Status...${NC}"
if ! docker info >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Docker is not running! Launching Docker Desktop...${NC}"
    open -a "Docker"
    echo -n "Waiting for Docker daemon to start"
    while ! docker info >/dev/null 2>&1; do
        echo -n "."
        sleep 2
    done
    echo -e "\n${GREEN}✔ Docker is now running!${NC}"
else
    echo -e "${GREEN}✔ Docker is active.${NC}"
fi

# 2. Verify Ollama is running
echo -e "\n${BOLD}${BLUE}[2/4] Checking Ollama Service...${NC}"
if ! curl -s http://localhost:11434 >/dev/null; then
    echo -e "${YELLOW}⚠️  Ollama is not running! Starting Ollama...${NC}"
    open -a "Ollama"
    echo -n "Waiting for Ollama API to respond"
    while ! curl -s http://localhost:11434 >/dev/null; do
        echo -n "."
        sleep 1
    done
    echo -e "\n${GREEN}✔ Ollama is now active!${NC}"
else
    echo -e "${GREEN}✔ Ollama service is active.${NC}"
fi

# 3. Start Odysseus containers
echo -e "\n${BOLD}${BLUE}[3/4] Launching Odysseus Docker Stack...${NC}"
cd "/Users/hassan/local-ai/odysseus"

# Execute docker compose
docker compose up -d --build

# 4. Open dashboard
echo -e "\n${BOLD}${BLUE}[4/4] Opening Local AI Dashboard...${NC}"
echo -e "${GREEN}✔ Odysseus UI is starting up!${NC}"
echo -e "${BOLD}Dashboard URL:${NC} http://localhost:7070"

# Wait a couple of seconds for container binding
sleep 3
open "http://localhost:7070"

echo -e "\n${BOLD}${GREEN}===========================================${NC}"
echo -e "${BOLD}${GREEN}   Setup complete! Enjoy your local AI.     ${NC}"
echo -e "${BOLD}${GREEN}===========================================${NC}"
