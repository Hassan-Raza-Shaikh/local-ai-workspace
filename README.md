# 🧠 Local AI Workspace Hub

Welcome to the **Local AI Workspace Hub**, a unified workspace designed to orchestrate local AI engineering pipelines, visual automation workflows, stateful multi-agent coding, and GPU-accelerated document processing on consumer hardware.

This repository features a suite of **6 native macOS SwiftUI desktop applications** built with the macOS 27 Golden Gate Liquid Glass 2.0 design framework. These apps manage background service daemons (Docker, Python backends, Ollama APIs) on-demand and perform automatic resources teardown upon application closure.

---

## 📖 Quick Links
*   **[Desktop Applications Manual (APPS.md)](APPS.md)**: Features, internal architecture, compilation scripts, and lifecycles.
*   **[Setup & Installation Guide (SETUP.md)](SETUP.md)**: Hardware requirements (8GB/16GB/32GB RAM), prerequisites, virtual environments, and configuration.
*   **[Detailed Usage Manual (USAGE.md)](USAGE.md)**: CLI references, script execution, ComfyUI, RAG workflows, and command bindings.

---

## 🖥️ The 6-App Native macOS SwiftUI Suite

The suite of desktop apps is compiled and located in your root workspace. They utilize a premium visual language featuring refractive translucency materials, scale spring click animations, and pointer-sensitive hover transitions:

1.  🧭 **`Odysseus.app`** (Core Dashboard Portal)
    *   *Port*: `7070`
    *   *Features*: Real-time hardware HUD (CPU & RAM allocation load monitors), logs panel drawer, and a borderless search panel web view. Auto-stops core containers on termination.
2.  🎙️ **`Media Studio.app`** (File & Media Workbench)
    *   *Features*: UI wraps for `yt-dlp` (custom resolution, cookies import, raw CLI flags field), Whisper (GPU-accelerated transcription), `MarkItDown` (document conversion), and `Crawl4AI` (URL-to-markdown scraping).
3.  💻 **`Dev Assistant.app`** (Autonomous Pair Programming)
    *   *Port*: `3001` (OpenHands), `8501` (Aider GUI)
    *   *Features*: Aider chat bubble window, OpenHands container controller + embedded sandbox web workspace, and a prompt field to run browser-use visual agents. Auto-stops OpenHands docker container on termination.
4.  💬 **`Local Chat.app`** (Direct Ollama Interface)
    *   *Port*: `11434`
    *   *Features*: Streaming token parser for Ollama `/api/chat`, installed model list, model puller with progress bar downloads, model deletions, and server toggles.
5.  🎨 **`Creative Studio.app`** (Visual AI Art Canvas)
    *   *Port*: `8188` (ComfyUI), `7865` (Fooocus)
    *   *Features*: Starts/stops local ComfyUI and Fooocus python services (configuring Apple Silicon MPS parameters). Auto-kills backend servers on exit.
6.  🧩 **`AI Orchestrator.app`** (Container Workspace Portal)
    *   *Port*: `3000` (Open WebUI), `8082` (Stirling-PDF), `5678` (n8n), `7860` (Langflow), `8090` (Dify), `8086` (Maxun)
    *   *Features*: Central dashboard to spin up/tear down compose stacks. Mounts tabbed borderless web views of all tools. Auto-shuts down all docker compose services on quit.

---

## 🛠️ Port Registry & Access Guide

When active, your local services map to the following addresses:

| Service | Address | Description | Primary Desktop Manager |
| :--- | :--- | :--- | :--- |
| **Open WebUI** | http://localhost:3000 | Private ChatGPT-style document chat & RAG | `AI Orchestrator.app` |
| **Stirling-PDF** | http://localhost:8082 | Offline web utility to sign, OCR, and compress PDFs | `AI Orchestrator.app` |
| **n8n Automation** | http://localhost:5678 | Self-hosted visual workflow builder | `AI Orchestrator.app` |
| **Langflow** | http://localhost:7860 | Visual agent builder & drag-and-drop RAG designer | `AI Orchestrator.app` |
| **Dify Platform** | http://localhost:8090 | Collaborative LLM app builder & studio | `AI Orchestrator.app` |
| **Maxun Scraper** | http://localhost:8086 | No-code point-and-click web scraper | `AI Orchestrator.app` |
| **OpenHands** | http://localhost:3001 | Autonomous coding developer agent | `Dev Assistant.app` |
| **Fooocus WebUI** | http://localhost:7865 | Offline SDXL image generator UI | `Creative Studio.app` |
| **ComfyUI WebUI** | http://localhost:8188 | Node-based offline image generator | `Creative Studio.app` |
| **Aider Web GUI** | http://localhost:8501 | Streamlit collaborative coding board | `Dev Assistant.app` |
| **Letta Server** | http://localhost:8283 | Stateful agent server with pgvector DB | `AI Orchestrator.app` |
| **Odysseus UI** | http://localhost:7070 | Central database dashboard & workspace portal | `Odysseus.app` |

---

## 📂 Project Directory Map

*   📁 **`apps/`**: Source files and build scripts for the 6 SwiftUI applications.
*   📁 **`comfyui/`**: Advanced ComfyUI image generator repository.
*   📁 **`data/`**: Drop private PDFs, CSVs, or text files here for RAG indexing.
*   📁 **`dify/`**: Dify application platform Docker Compose stack.
*   📁 **`fooocus/`**: Fooocus image generator repository.
*   📁 **`hyperframes/`**: HTML-to-video compilation starter template.
*   📁 **`maxun/`**: Maxun point-and-click web scraper stack.
*   📁 **`notebooks/`**: Python scripts and agent experiments:
    *   📄 `transcribe.py`: GPU-accelerated speech-to-text transcriber (Whisper).
    *   📄 `convert_doc.py`: Document to markdown converter (MarkItDown).
    *   📄 `browser_use_demo.py`: Automated web browser agent.
    *   📄 `query_local_data.py`: Central LlamaIndex document RAG script.
    *   📄 `local_crew_agent.py`: Multi-agent research crew (CrewAI).
*   📁 **`odysseus/`**: Core Odysseus dashboard and offline database services.
*   📄 **`start_tools.sh`**: Central terminal-based launcher menu.
*   📄 **`stop_tools.sh`**: Central workspace shutdown script.
