#!/usr/bin/env bash

# Local AI Workspace Shutdown Script
# Shuts down all containers and local servers to free up RAM and CPU.

set -euo pipefail

BOLD="\033[1m"
GREEN="\033[32m"
BLUE="\033[34m"
YELLOW="\033[33m"
NC="\033[0m"

echo -e "${BOLD}${BLUE}===========================================${NC}"
echo -e "${BOLD}${BLUE}   Shutting Down Local AI Tools Suite       ${NC}"
echo -e "${BOLD}${BLUE}===========================================${NC}"

# 1. Stop Single-Container Docker Tools Stack
echo -e "\n${BOLD}${BLUE}[1/5] Stopping Open WebUI, Stirling-PDF, n8n, and Langflow...${NC}"
docker compose -f /Users/hassan/local-ai/docker-compose.tools.yml down || true

# 2. Stop Dify Stack
echo -e "\n${BOLD}${BLUE}[2/5] Stopping Dify application stack...${NC}"
if [ -d "/Users/hassan/local-ai/dify/docker" ]; then
    docker compose -f /Users/hassan/local-ai/dify/docker/docker-compose.yaml down || true
else
    echo "Dify directory not found, skipping."
fi

# 3. Stop Maxun Stack
echo -e "\n${BOLD}${BLUE}[3/5] Stopping Maxun point-and-click scraper...${NC}"
if [ -d "/Users/hassan/local-ai/maxun" ]; then
    docker compose -f /Users/hassan/local-ai/maxun/docker-compose.yml down || true
else
    echo "Maxun directory not found, skipping."
fi

# 4. Stop OpenHands Container
echo -e "\n${BOLD}${BLUE}[4/5] Stopping OpenHands coding agent...${NC}"
if docker ps -a --format '{{.Names}}' | grep -Eq "^openhands$"; then
    docker stop openhands || true
    docker rm openhands || true
    echo -e "${GREEN}✔ OpenHands stopped and removed.${NC}"
else
    echo "OpenHands container not running."
fi

# 5. Shut Down Local Ollama (Optional - but good for memory)
echo -e "\n${BOLD}${BLUE}[5/5] Checking Ollama status...${NC}"
if pgrep -x "Ollama" > /dev/null; then
    echo -e "${YELLOW}Ollama background service is still running in menu bar.${NC}"
    echo -e "You can quit it manually from the macOS status bar to reclaim memory."
fi

echo -e "\n${BOLD}${GREEN}===========================================${NC}"
echo -e "${BOLD}${GREEN}   All containers stopped. Memory cleared!  ${NC}"
echo -e "${BOLD}${GREEN}===========================================${NC}"
