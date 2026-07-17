# 🖥️ macOS SwiftUI Native Desktop Apps Guide

This document provides a comprehensive developer and user manual for the native macOS SwiftUI desktop applications bundled with the **Local AI Workspace Hub**.

All applications are built using native Swift controls, target compatibility for **macOS 14.0+** (fully optimized for the **macOS 27 Golden Gate** Apple Silicon exclusive environment), and implement advanced lifecycle teardown hooks.

---

## 🎨 macOS 27 "Liquid Glass 2.0" Design Specs

Every application in this suite conforms to the latest macOS Golden Gate human interface guidelines:
*   **Translucent Refraction**: Uses `NSVisualEffectView` with `underWindowBackground` blending to match desktop wallpapers dynamically.
*   **Double-Border Separation (`liquidGlassCard`)**: Overlay strokes feature an inner bright highlight (`Color.white.opacity(0.15)`) and an outer dark shadow contrast outline (`Color.black.opacity(0.20)`) to ensure elements pop clearly.
*   **Fluid Spring Motion**: Controls respond to mouse gestures with custom spring physics:
    *   **Hover**: Scales to `1.02` with an active drop shadow.
    *   **Press/Click**: Compresses to `0.96`.
    *   **Spring Configuration**: `response: 0.25`, `dampingFraction: 0.65`.

---

## 📦 App Directory Catalog

All compiled binaries are located in the root of the workspace directory: `/Users/hassan/local-ai/`.

### 1. 🧭 Odysseus
*   **Bundle Identifier**: `com.localai.odysseus`
*   **Icon**: `icns/Odysseus.icns`
*   **Purpose**: Central hub and search/RAG portal.
*   **Key Features**:
    *   **Dashboard Manager**: Boots the core dashboard engine at port `7070` via background scripts.
    *   **Hardware HUD**: Header gauges display active **CPU Load Percentage** and **Free Unified RAM** (out of 32GB) in real-time.
    *   **Embedded Web View**: Loads the main search canvas in a borderless frame once online.
    *   **Auto-Teardown**: Automatically shuts down the Odysseus Docker container stack upon app termination to free memory.

### 2. 🎙️ Media Studio
*   **Bundle Identifier**: `com.localai.mediastudio`
*   **Icon**: `icns/Media Studio.icns`
*   **Purpose**: Offline file conversion and scraping workbench.
*   **Key Features**:
    *   **Media Downloader**: Wraps `yt-dlp` CLI. Features custom format selects, subtitle embedding, browser cookie importing, and an **Advanced CLI Flags** input field to bypass GUI constraints.
    *   **Local Transcriber**: Wraps Whisper. Transcribes speech-to-text locally using Apple Silicon GPU/ANE acceleration.
    *   **Document Converter**: Wraps Microsoft's `MarkItDown` library. Converts PDF, Word, and Excel files to markdown on drag-and-drop.
    *   **Web Scraper**: Wraps `Crawl4AI` to convert website URLs to LLM-ready markdown.

### 3. 💻 Dev Assistant
*   **Bundle Identifier**: `com.localai.devassistant`
*   **Icon**: `icns/Dev Assistant.icns`
*   **Purpose**: Local pair programming and web automation terminal.
*   **Key Features**:
    *   **Aider Chat**: Native chat view executing Aider CLI commands (`--yes` auto-apply) on a background thread targeting the repository of your choice.
    *   **Aider Web GUI**: Toggle button to launch Streamlit Aider board on port `8501`.
    *   **OpenHands Sandbox**: Visual launcher to spin up the Docker-based container on port `3001` and display it in an embedded WebView.
    *   **Browser-Use**: Visual prompt agent that spawns a visible Playwright browser window to execute web search instructions.
    *   **Auto-Teardown**: Automatically stops the `openhands-app` container when the app is closed.

### 4. 💬 Local Chat
*   **Bundle Identifier**: `com.localai.localchat`
*   **Icon**: `icns/Local Chat.icns`
*   **Purpose**: Direct streaming client for Ollama LLM models.
*   **Key Features**:
    *   **API Streaming**: Communicates directly with `/api/chat` using asynchronous byte streams, displaying LLM tokens word-by-word into chat bubbles.
    *   **Ollama Manager**: Dynamically fetches locally installed models, allows model deletion with one click, and pulls new models from the Ollama library showing active download progress bars.
    *   **Service Toggle**: Start/Stop the local Ollama background server daemon.

### 5. 🎨 Creative Studio
*   **Bundle Identifier**: `com.localai.creativestudio`
*   **Icon**: `icns/Creative Studio.icns`
*   **Purpose**: GPU-accelerated local Stable Diffusion / Flux art creation.
*   **Key Features**:
    *   **ComfyUI Node Canvas**: One-click launcher for the ComfyUI python backend (pre-configured with `PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0` for Apple Silicon memory optimization) showing the canvas on port `8188`.
    *   **Fooocus Art Workspace**: One-click launcher for the Fooocus backend (port `7865`) with Gradio interfaces.
    *   **Auto-Teardown**: Forcefully kills background python instances (`pkill`) immediately on exit to release your GPU memory.

### 6. 🧩 AI Orchestrator
*   **Bundle Identifier**: `com.localai.aiorchestrator`
*   **Icon**: `icns/AI Orchestrator.icns`
*   **Purpose**: Central container manager and service workspace dashboard.
*   **Key Features**:
    *   **Service Toggles**: Deploys/stops individual Compose stacks: Core Tools, Dify Platform, Maxun Visual Scraper, and Letta Agents.
    *   **Workspace Tabs**: Integrates borderless WebViews mapping to:
        *   **Open WebUI** (Port `3000`)
        *   **Stirling-PDF** (Port `8082`)
        *   **n8n Automation** (Port `5678`)
        *   **Langflow Graph** (Port `7860`)
        *   **Dify Studio** (Port `8090`)
        *   **Maxun Scraper** (Port `8086`)
    *   **Auto-Teardown**: Stops and shuts down all active Compose containers (`docker compose down` and `docker stop`) when the orchestrator is closed.

---

## 🛠️ Compilation & Packaging

Each application folder inside `apps/` contains a `build_app.sh` script.

### Bulk Recompilation
To compile the entire suite at once, navigate to the root directory and run:
```bash
for app in "Media Studio" "Dev Assistant" "Local Chat" "Creative Studio" "AI Orchestrator" "Odysseus"; do
  "./apps/$app/build_app.sh"
done
```

### Script Internals
The build scripts automate the following steps:
1.  Clean up previous builds.
2.  Set up the macOS `.app` bundle directory structures (`Contents/MacOS` and `Contents/Resources`).
3.  Compile Swift source files using `swiftc` targeting the Apple Silicon architecture (`-target arm64-apple-macosx14.0`) with optimizations (`-O`).
4.  Copy configuration properties (`Info.plist`) and bundle icon sets (`AppIcon.icns`).
5.  Clear Gatekeeper attributes (`xattr -cr`) and perform ad-hoc code-signing (`codesign --force --deep --sign -`).
