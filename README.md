# 🧠 Local AI Workspace Hub

Welcome to the **Local AI Workspace Hub**, a unified workspace designed to orchestrate local AI engineering pipelines, visual automation workflows, stateful multi-agent coding, and GPU-accelerated document processing on consumer hardware. 

All heavy tools run fully on-demand and shut down cleanly via a central interface, ensuring minimal idle resource consumption.

---

## 📖 Quick Links
*   **[Setup & Installation Guide (SETUP.md)](SETUP.md)**: Hardware requirements (8GB/16GB/32GB RAM), prerequisites, virtual environments, and configuration.
*   **[Detailed Usage Manual (USAGE.md)](USAGE.md)**: CLI references, script execution, ComfyUI, RAG workflows, and command bindings.

---

## 🚀 Key Features

*   **⚡ Resource-Optimized Orchestration**: Start/stop heavy services (n8n, Dify, ComfyUI, OpenHands) on-demand to save RAM and CPU.
*   **🤖 Stateful Memory Agents**: Run stateful agent gateways powered by Letta (MemGPT) connected to pgvector databases.
*   **💻 AI Pair Programming**: Write code inside local repositories with terminal and web-based Aider integration.
*   **🎨 Offline Image Generation**: Hardware-accelerated image generation using ComfyUI (nodes) and Fooocus (SDXL).
*   **🔍 Private Document RAG**: Parse and index private documents locally using Ollama and Open WebUI with no cloud dependencies.

---

## 🛠️ Port Registry & Access Guide

When activated via the launcher, your local services map to the following addresses:

| Service | Address | Description | Launch Option |
| :--- | :--- | :--- | :--- |
| **Open WebUI** | http://localhost:3000 | Private ChatGPT-style document chat & RAG | Launcher option `1` |
| **Stirling-PDF** | http://localhost:8082 | Offline web utility to sign, OCR, and compress PDFs | Launcher option `1` |
| **n8n Automation** | http://localhost:5678 | Self-hosted visual workflow builder | Launcher option `1` |
| **Langflow** | http://localhost:7860 | Visual agent builder & drag-and-drop RAG designer | Launcher option `1` |
| **Dify Platform** | http://localhost:8090 | Collaborative LLM app builder & studio | Launcher option `2` |
| **Maxun Scraper** | http://localhost:8086 | No-code point-and-click web scraper | Launcher option `3` |
| **OpenHands** | http://localhost:3001 | Autonomous coding developer agent | Launcher option `4` |
| **Fooocus WebUI** | http://localhost:7865 | Offline SDXL image generator UI | Launcher option `5` |
| **ComfyUI WebUI** | http://localhost:8188 | Node-based offline image generator | Launcher option `6` |
| **Aider Web GUI** | http://localhost:8501 | Streamlit collaborative coding board | Launcher option `8` |
| **Letta Server** | http://localhost:8283 | Stateful agent server with pgvector DB | Launcher option `9` |

---

## 📂 Project Directory Map

*   📁 **`apps/`**: Interactive chat UIs (Streamlit/Chainlit).
*   📁 **`comfyui/`**: Advanced ComfyUI image generator repository.
*   📁 **`data/`**: Drop private PDFs, CSVs, or text files here for RAG indexing.
*   📁 **`dify/`**: Dify application platform Docker Compose stack.
*   📁 **`fooocus/`**: Fooocus image generator repository.
*   📁 **`hyperframes/`**: HTML-to-video compilation starter template.
*   📁 **`maxun/`**: Maxun point-and-click web scraper stack.
*   📁 **`notebooks/`**: Python scripts and agent experiments:
    *   📄 `transcribe.py`: GPU-accelerated speech-to-text transcriber (Whisper).
    *   📄 `browser_use_demo.py`: Automated web browser agent.
    *   📄 `query_local_data.py`: Central LlamaIndex document RAG script.
    *   📄 `local_crew_agent.py`: Multi-agent research crew (CrewAI).
*   📁 **`odysseus/`**: Core Odysseus dashboard and offline database services.
*   📄 **`start_tools.sh`**: Central terminal-based launcher menu.
*   📄 **`stop_tools.sh`**: Central workspace shutdown script.
