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
| **ComfyUI WebUI** | http://localhost:8188 | Node-based offline image generator & workflow engine | Launcher option `6` |

---

## 📂 Project Directory Map

*   📁 **`odysseus/`**: Core Odysseus dashboard source and compose stack.
*   📁 **`dify/`**: Dify application platform compose stack.
*   📁 **`maxun/`**: Maxun point-and-click scraper stack.
*   📁 **`fooocus/`**: Fooocus offline SDXL generator repository.
*   📁 **`comfyui/`**: ComfyUI node-based offline image generator repository.
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

### 5. PDF & Document Conversion (`markitdown`)
Convert documents (PDFs, Word files, Excel, PowerPoint) to Markdown locally:
- **Using the helper Python script**:
  ```bash
  python /Users/hassan/local-ai/notebooks/convert_doc.py /path/to/your_file.pdf
  ```
  *Outputs a matching `.md` file in the same directory.*
- **Using the command line directly**:
  ```bash
  markitdown your_file.pdf > data/your_file.md
  ```

### 6. HTML-to-Video Compiler (`Hyperframes`)
Create programmatic videos using HTML/CSS/JS. From the `hyperframes/` folder, run:
- **Preview video composition**: `npx hyperframes preview`
- **Render composition to MP4**: `npx hyperframes render`

### 7. Apple Silicon Hardware Optimizations
Instead of using Intel-specific `openvino.genai` packages, we leverage native Apple Metal Performance Shaders (MPS) and PyTorch MPS fallbacks in python, and native CoreML runtimes in Ollama to ensure maximum model performance.

---

## 🦙 Specialized Local LLMs (Ollama)

Your 32GB Mac has the following highly specialized models configured to run locally with zero limits:

- **Coding Assistant**: `qwen2.5-coder:32b` (~19 GB) — World-class code writing, refactoring, and multi-file debugging.
- **Creative & Chat**: `gemma2:27b` (~16 GB) — Google's top-tier general model for writing, brainstorming, and translation.
- **Deep Reasoning**: `deepseek-r1:32b` (~19 GB) — Step-by-step chain-of-thought reasoning (comparable to OpenAI o1) for math, logic, and planning.
- **Fast General Chat**: `gemma2:9b` (~5.5 GB) — Responsive, lightweight model for everyday quick queries.

### CLI Reference:
- **List installed models**: `ollama list`
- **Run a model in terminal**: `ollama run <model_name>`
- **Pull a new model**: `ollama pull <model_name>`

---

## 🔍 Retrieval-Augmented Generation (RAG) Guide

Your workspace is built from the ground up to support both **Local Document RAG** and **Web RAG (Search-Augmented Generation)**. Here is how to use these capabilities:

### 1. Local Document RAG (Querying your private files)
Feed private PDFs, CSVs, or text files into your models without sending them to the cloud.

*   **Via Open WebUI (`http://localhost:3000`)**:
    1.  Start a new chat and select your local model (e.g., `qwen2.5-coder:32b`).
    2.  Click the **`+`** (attachment) button and upload a document.
    3.  Open WebUI will index it locally. Ask your question, and the model will answer using the document context.
*   **Via Python Script (`query_local_data.py`)**:
    1.  Drop text or PDF files into the [`data/`](file:///Users/hassan/local-ai/data) folder.
    2.  Run the query script: `python /Users/hassan/local-ai/notebooks/query_local_data.py`
    3.  To switch models, open the script and change: `Ollama(model="qwen2.5-coder:32b")`.

### 2. Web RAG (Real-Time Web Search grounding)
Let your local models search the web for the latest info before generating an answer.

*   **Via Odysseus Hub (`http://localhost:7000`)**:
    1.  Odysseus has a local **SearXNG** engine running in its Docker compose stack.
    2.  Toggle **Web Search** in the Odysseus Chat interface. It will query SearXNG to search the web anonymously, scrape the results, and pass them as prompt context to your local LLM.
*   **Via Open WebUI (`http://localhost:3000`)**:
    1.  Go to **Admin Settings** -> **Web Search**.
    2.  Enable web search and set the URL to your local SearXNG port at `http://host.docker.internal:8080`.
    3.  Activate the globe icon in the chat bar to force search grounding on every query.
*   **Via Python Agent (`local_crew_agent.py`)**:
    1.  Equip your CrewAI agents with a search tool (like `TavilySearchResult` or a custom SearXNG wrapper).
    2.  The agents will programmatically query the search API and synthesize the output.
