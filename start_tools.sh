#!/usr/bin/env bash

# Local AI Workspace Launch Menu
# Starts individual tools or the whole suite on-demand to save RAM.

set -euo pipefail

BOLD="\033[1m"
GREEN="\033[32m"
BLUE="\033[34m"
YELLOW="\033[33m"
NC="\033[0m"

# Ensure Docker is running
verify_docker() {
    if ! docker info >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Docker is not running! Launching Docker Desktop...${NC}"
        open -a "Docker"
        echo -n "Waiting for Docker daemon to start"
        while ! docker info >/dev/null 2>&1; do
            echo -n "."
            sleep 2
        done
        echo -e "\n${GREEN}✔ Docker is active!${NC}"
    fi
}

show_menu() {
    clear
    echo -e "${BOLD}${BLUE}=================================================${NC}"
    echo -e "${BOLD}${BLUE}   Hassan's Next-Level Local AI Suite Launcher   ${NC}"
    echo -e "${BOLD}${BLUE}=================================================${NC}"
    echo -e "Choose an option to launch (or run ./stop_tools.sh to stop all):"
    echo -e ""
    echo -e "  ${BOLD}1)${NC} Open WebUI, Stirling-PDF, n8n, & Langflow  [Docker Stack]"
    echo -e "  ${BOLD}2)${NC} Dify Application Platform                  [Docker Stack]"
    echo -e "  ${BOLD}3)${NC} Maxun Point-and-Click Web Scraper          [Docker Stack]"
    echo -e "  ${BOLD}4)${NC} OpenHands Autonomous Developer Agent       [Docker Script]"
    echo -e "  ${BOLD}5)${NC} Fooocus Offline SDXL Image Generator       [Python Script]"
    echo -e "  ${BOLD}6)${NC} ComfyUI Offline Image Generator             [Python Script]"
    echo -e "  ${BOLD}7)${NC} Aider AI Pair Programmer (CLI)              [Python Script]"
    echo -e "  ${BOLD}8)${NC} Aider AI Web GUI (Browser Board)            [Python Script]"
    echo -e "  ${BOLD}9)${NC} Letta Stateful Agent Server                 [Python Script]"
    echo -e "  ${BOLD}10)${NC} Start ALL Tools                            [High Resource!]"
    echo -e "  ${BOLD}11)${NC} Stop ALL Tools                             [Free RAM]"
    echo -e "  ${BOLD}12)${NC} Exit"
    echo -e ""
    echo -n "Enter option [1-12]: "
}

launch_stack() {
    verify_docker
    echo -e "\n${BOLD}${BLUE}Starting Open WebUI, Stirling-PDF, n8n, and Langflow...${NC}"
    docker compose -f /Users/hassan/local-ai/docker-compose.tools.yml up -d
    echo -e "${GREEN}✔ Started!${NC}"
    echo -e "  - Open WebUI: http://localhost:3000"
    echo -e "  - Stirling-PDF: http://localhost:8082"
    echo -e "  - n8n: http://localhost:5678"
    echo -e "  - Langflow: http://localhost:7860"
}

launch_dify() {
    verify_docker
    echo -e "\n${BOLD}${BLUE}Starting Dify platform...${NC}"
    cd "/Users/hassan/local-ai/dify/docker"
    docker compose up -d
    echo -e "${GREEN}✔ Started!${NC}"
    echo -e "  - Dify Web Portal: http://localhost:8090"
}

launch_maxun() {
    verify_docker
    echo -e "\n${BOLD}${BLUE}Starting Maxun scraper...${NC}"
    cd "/Users/hassan/local-ai/maxun"
    docker compose up -d
    echo -e "${GREEN}✔ Started!${NC}"
    echo -e "  - Maxun UI: http://localhost:8086"
}

launch_openhands() {
    verify_docker
    echo -e "\n${BOLD}${BLUE}Launching OpenHands script...${NC}"
    /Users/hassan/local-ai/start_openhands.sh
}

launch_fooocus() {
    echo -e "\n${BOLD}${BLUE}Launching Fooocus script...${NC}"
    /Users/hassan/local-ai/start_fooocus.sh
}

launch_comfyui() {
    echo -e "\n${BOLD}${BLUE}Launching ComfyUI script...${NC}"
    /Users/hassan/local-ai/start_comfyui.sh
}

launch_aider_cli() {
    echo -e "\n${BOLD}${BLUE}Launching Aider CLI...${NC}"
    /Users/hassan/local-ai/start_aider.sh
}

launch_aider_gui() {
    echo -e "\n${BOLD}${BLUE}Launching Aider Web GUI...${NC}"
    /Users/hassan/local-ai/start_aider.sh --gui
}

launch_letta() {
    echo -e "\n${BOLD}${BLUE}Launching Letta Server...${NC}"
    /Users/hassan/local-ai/start_letta.sh
}

# Main process loop
if [[ "${1:-}" == "--all" ]]; then
    launch_stack
    launch_dify
    launch_maxun
    launch_openhands
    exit 0
fi

while true; do
    show_menu
    read -r opt
    case $opt in
        1) launch_stack; break ;;
        2) launch_dify; break ;;
        3) launch_maxun; break ;;
        4) launch_openhands; break ;;
        5) launch_fooocus; break ;;
        6) launch_comfyui; break ;;
        7) launch_aider_cli; break ;;
        8) launch_aider_gui; break ;;
        9) launch_letta; break ;;
        10)
            launch_stack
            launch_dify
            launch_maxun
            launch_openhands
            break
            ;;
        11)
            /Users/hassan/local-ai/stop_tools.sh
            break
            ;;
        12)
            echo "Exiting."
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Press Enter to retry.${NC}"
            read -r
            ;;
    esac
done

echo -e "\n${BOLD}${GREEN}Startup command processed!${NC}"
