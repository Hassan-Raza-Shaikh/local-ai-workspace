# 🧠 Hassan's Next-Level Local AI Workspace Hub

Welcome to your central workspace for local AI engineering, visual workflow automation, multi-agent coding, and private document processing on your M1 Pro 32GB RAM MacBook Pro.

---

## 🚀 The Launch Control Center (RAM & CPU Optimization)

To save battery, CPU, and RAM, **all heavy tools remain stopped by default**. You can start specific tools, stacks, or the entire suite on-demand, and shut everything down immediately using a single command.

### 1. Start Tools Menu (Interactive Launcher)
Run the master script to view the CLI menu and choose which tools to launch:
```bash
/Users/hassan/local-ai/start_tools.sh
```

### 2. Stop All Tools (Reclaim Memory)
Stop all Docker containers and free up your Mac's RAM immediately when you are done working:
```bash
/Users/hassan/local-ai/stop_tools.sh
```

### 3. Core Odysseus Dashboard Launcher
Starts the core offline database, ntfy, SearXNG search engine, and Odysseus React portal:
```bash
/Users/hassan/local-ai/start_workspace.sh
```

---

## 🛠️ Active Port Registry & Access Guide

When active, your local web services are mapped to these URLs:

| Service | Port / URL | Description | Start Method |
| :--- | :--- | :--- | :--- |
| **Odysseus Hub** | http://localhost:7000 | Core local knowledge dashboard (FastAPI + React) | `./start_workspace.sh` |
| **Open WebUI** | http://localhost:3000 | ChatGPT-style local chat with document upload & RAG | Launcher option `1` |
| **Stirling-PDF** | http://localhost:8082 | Offline web utility to merge, OCR, sign, compress PDFs | Launcher option `1` |
| **n8n Automation** | http://localhost:5678 | Self-hosted workflow builder (Zapier alternative) | Launcher option `1` |
| **Langflow** | http://localhost:7860 | Visual agent builder & drag-and-drop RAG designer | Launcher option `1` |
| **Dify Platform** | http://localhost:8090 | Collaborative LLM app builder & workflow studio | Launcher option `2` |
| **Maxun Scraper** | http://localhost:8086 | No-code point-and-click web data extractor | Launcher option `3` |
| **OpenHands** | http://localhost:3001 | Autonomous software development agent (Devin alternative) | Launcher option `4` |
| **Fooocus WebUI** | http://localhost:7865 | Offline SDXL image generator (Midjourney alternative) | Launcher option `5` |

---

## 📂 Project Directory Map

*   📁 **`odysseus/`**: Core Odysseus dashboard source and compose stack.
*   📁 **`dify/`**: Dify application platform compose stack.
*   📁 **`maxun/`**: Maxun point-and-click scraper stack.
*   📁 **`fooocus/`**: Fooocus offline SDXL generator repository.
*   📁 **`hyperframes/`**: HeyGen HTML-to-video boilerplate folder.
*   📁 **`data/`**: Drop your private documents (PDF, CSV, TXT) here for RAG indexing.
*   📁 **`notebooks/`**: Python scripts and agent experiments.
    *   📄 `transcribe.py` (Whisper offline speech-to-text script)
    *   📄 `browser_use_demo.py` (Web automation agent script)
    *   📄 `query_local_data.py` (Central LlamaIndex document RAG demo)
    *   📄 `local_crew_agent.py` (Collaborative multi-agent script)
*   📁 **`apps/`**: Interactive chat UIs (Streamlit/Chainlit).

---

## 🐍 Command Line & Script Tools

### 1. Offline Video Downloader (`yt-dlp`)
Download high-quality videos or audio files locally:
```bash
yt-dlp "https://www.youtube.com/watch?v=..."
```

### 2. Local GPU-Accelerated Transcription (`Whisper`)
Transcribe local audio or video files offline using Apple Silicon GPU (MPS) acceleration:
```bash
python /Users/hassan/local-ai/notebooks/transcribe.py /path/to/audio_file.mp3
```
*Outputs a matching `.txt` file containing the transcription in the same folder.*

### 3. Agentic Browser Automation (`browser-use`)
Run scripts where AI agents navigate the web for you:
```bash
python /Users/hassan/local-ai/notebooks/browser_use_demo.py
```

### 4. Document Scraper for RAG (`crawl4ai`)
Scrape web pages directly into LLM-friendly markdown. Sample Python code:
```python
import asyncio
from crawl4ai import AsyncWebCrawler

async def main():
    async with AsyncWebCrawler() as crawler:
        result = await crawler.arun(url="https://news.ycombinator.com")
        print(result.markdown)

asyncio.run(main())
```

### 5. PDF to Markdown Conversion (`markitdown`)
Convert document pages locally to Markdown tables/text:
```bash
markitdown your_file.pdf > data/your_file.md
```

### 6. HTML-to-Video Compiler (`Hyperframes`)
Create programmatic videos using HTML/CSS/JS. From the `hyperframes/` folder, run:
- **Preview video composition**: `npx hyperframes preview`
- **Render composition to MP4**: `npx hyperframes render`

### 7. Apple Silicon Hardware Optimizations
Instead of using Intel-specific `openvino.genai` packages, we leverage native Apple Metal Performance Shaders (MPS) and PyTorch MPS fallbacks in python, and native CoreML runtimes in Ollama to ensure maximum model performance.
