# 📖 Local AI Workspace Hub: Usage Manual

This manual provides detailed, step-by-step instructions on how to use the various AI models, interactive developer tools, web scrapers, image generators, and automation pipelines integrated into this workspace.

---

## 🚀 Central Workspace Control

To save battery, CPU, and RAM, all heavy services remain stopped by default. You can launch individual tools or stacks on-demand, and shut them down cleanly.

### 1. Interactive Tools Launcher
Launch the master command-line menu to choose which tools to start:
```bash
./start_tools.sh
```
**Launcher Menu Options:**
1. **Docker stack**: Open WebUI, Stirling-PDF, n8n, and Langflow.
2. **Dify**: Collaborative LLM application builder.
3. **Maxun**: Point-and-click no-code web scraper.
4. **OpenHands**: Autonomous software development agent.
5. **Fooocus**: Offline SDXL image generator.
6. **ComfyUI**: Advanced offline node-based image generator.
7. **Aider CLI**: Terminal-based AI pair programmer.
8. **Aider GUI**: Web-based collaborative coding interface.
9. **Letta Server**: Stateful agent gateway and server.
10. **Start All Stack**: Launch docker stacks simultaneously.
11. **Stop All Stack**: Shutdown and free all memory.

### 2. Stop All Services
Shut down all Docker containers, Streamlit interfaces, and Python backend servers immediately to reclaim memory:
```bash
./stop_tools.sh
```

---

## 🛠️ CLI & Script Tools Reference

### 1. Offline Video Downloader (`yt-dlp`)
Download high-quality videos or extract audio files locally:
```bash
# Download a video (best quality)
yt-dlp "https://www.youtube.com/watch?v=..."

# Extract audio as MP3
yt-dlp -x --audio-format mp3 "https://www.youtube.com/watch?v=..."
```

### 2. GPU-Accelerated Audio Transcription (`Whisper`)
Transcribe local audio or video files offline. If you are on Apple Silicon, the script uses Metal Performance Shaders (MPS) for hardware acceleration:
```bash
python notebooks/transcribe.py /path/to/audio_file.mp3
```
*Outputs a matching `.txt` file containing the transcription in the same directory.*

### 3. Agentic Browser Automation (`browser-use`)
Run autonomous AI agents that navigate the web browser, extract data, or click elements for you:
```bash
python notebooks/browser_use_demo.py
```

### 4. Document Scraper for RAG (`crawl4ai`)
Scrape websites directly into clean, LLM-friendly markdown. You can use the following Python boilerplate:
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
Convert various documents (PDFs, Word files, Excel, PowerPoint) to Markdown locally:
* **Using the python helper script**:
  ```bash
  python notebooks/convert_doc.py /path/to/your_file.pdf
  ```
* **Directly via the command line**:
  ```bash
  markitdown your_file.pdf > data/your_file.md
  ```

### 6. HTML-to-Video Compilation (`Hyperframes`)
Compile programmatic videos using HTML/CSS/JS. Navigate to the `hyperframes/` folder and run:
* **Preview composition**: `npx hyperframes preview`
* **Render composition to MP4**: `npx hyperframes render`

---

## 💻 Code & Agent Assistants

### 1. Interactive AI Pair Programmer (`Aider`)
Aider lets you pair program with AI directly inside your local git repository. It automatically reads files, updates them, and commits code changes.
* **Terminal CLI Mode**: Select option `7` in the menu or run:
  ```bash
  ./start_aider.sh
  ```
* **Web-based GUI Mode**: Select option `8` in the menu or run:
  ```bash
  ./start_aider.sh --gui
  ```
  *(Launches Streamlit on port `8501`)*
* **Key Bindings & Prompt Commands**:
  * `/add <file>`: Add files to the chat context so Aider can edit them.
  * `/drop <file>`: Remove files from the chat context.
  * `/commit`: Commit the changes made by Aider.
  * `/exit` or `/quit`: Exit Aider.

### 2. Stateful Agent Server (`Letta`)
Letta (formerly MemGPT) runs autonomous stateful agents that maintain long-term memory.
* **Start Server**: Select option `9` in the menu or run:
  ```bash
  ./start_letta.sh
  ```
* **API Access**: Access the server at `http://localhost:8283`.
* **Database Backend**: Connected to a local PostgreSQL + pgvector Docker database (`letta-db`), enabling persistent semantic memory retrieval.

---

## 🎨 Image Generation

### 1. Fooocus Offline SDXL UI
Option `5` in the launcher starts a simplified web-based SDXL image generator optimized for Apple Silicon MPS.
* **Web Access**: `http://localhost:7865`

### 2. ComfyUI Workflow Engine
Option `6` in the launcher starts the advanced node-based offline image generator.
* **Web Access**: `http://localhost:8188`
* **Performance Note**: Runs fully offline and utilizes PyTorch MPS settings (`PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0`) to run large generation passes without out-of-memory errors on macOS unified memory.

---

## 🦙 Specialized Local LLMs (Ollama)

Manage and run offline models locally on your GPU:
* **List installed models**: `ollama list`
* **Run a model**: `ollama run <model_name>`
* **Pull a new model**: `ollama pull <model_name>`
* **Check memory allocation**: `ollama ps`

---

## 🔍 Retrieval-Augmented Generation (RAG)

This workspace supports both **Local Document RAG** and **Web RAG (Search-Augmented Generation)**.

### 1. Local Document RAG (Offline & Secure)
Index private documents (PDFs, CSVs, TXT) and query them without cloud dependencies.
* **Via Open WebUI (`http://localhost:3000`)**:
  1. Open a new chat, select your local model (e.g., `qwen2.5-coder:32b`).
  2. Click the `+` attachment button and upload your document.
  3. The document is parsed and indexed locally. Ask questions directly in the chat interface.
* **Via Python Script (`query_local_data.py`)**:
  1. Drop text or PDF files into the `data/` directory.
  2. Run the script:
     ```bash
     python notebooks/query_local_data.py
     ```
  3. To toggle between local GPU models and cloud providers, edit the `AI_ENGINE` switch at the top of the file:
     ```python
     # Choose: "local" (uses Ollama) or "cloud" (uses Gemini)
     AI_ENGINE = "local"
     ```

### 2. Web RAG (Real-Time Search Grounding)
Augment model responses with real-time web search results before generation.
* **Via Open WebUI (`http://localhost:3000`)**:
  1. Go to **Admin Settings** -> **Web Search**.
  2. Enable search and input the local SearXNG URL: `http://host.docker.internal:8080`.
  3. Activate the web globe icon in the chat input bar to enable search on queries.
* **Via Python Agent (`local_crew_agent.py`)**:
  1. This script orchestrates a cooperative research team (Tech Researcher and Technical Writer).
  2. Run the script:
     ```bash
     python notebooks/local_crew_agent.py
     ```
  3. The research agent automatically runs web queries, summarizes articles, and hands the clean notes to the writing agent to synthesize a newsletter.
