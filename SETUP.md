# ⚙️ Local AI Workspace Hub: Setup Guide

This guide describes the hardware requirements, prerequisites, and step-by-step installation instructions to set up the workspace on macOS, Windows (WSL2), or Linux.

---

## 💻 Hardware & Memory Requirements

Running local LLMs and AI agent pipelines is memory-intensive. Below is a sizing guide based on your system RAM:

| System RAM | Recommended LLM Size | Recommended Capabilities | Limitations |
| :--- | :--- | :--- | :--- |
| **8 GB** | 1.5B – 3B parameters | Lightweight RAG, SQLite testing, basic scraping | Cannot run multiple Docker stacks or larger LLMs. Image generation will be extremely slow. |
| **16 GB** | 7B – 9B parameters | Medium RAG (e.g. `gemma2:9b` or `llama3:8b`), Open WebUI, Stirling-PDF, n8n, Fooocus | Running multiple Docker platforms (like Dify + Maxun) concurrently will cause paging. |
| **32 GB+** | 27B – 32B+ parameters | Full concurrent Docker stacks, specialized coding assistants (`qwen2.5-coder:32b`), reasoning LLMs (`deepseek-r1:32b`), ComfyUI generation | None. Fully capable of running local vector databases, multi-agent frameworks, and rendering concurrently. |

### OS Compatibility
* **macOS**: Apple Silicon (M1/M2/M3/M4) is highly recommended. It leverages macOS Unified Memory to share RAM between CPU and GPU via Apple Metal (MPS).
* **Windows**: WSL2 (Windows Subsystem for Linux) is **strictly required** to run the shell scripts (`.sh`) and Docker Compose stacks.
* **Linux**: Native compatibility. Ensure you have modern NVIDIA GPUs with CUDA configured for optimal model performance.

---

## 🛠️ Prerequisites

Ensure you have the following installed on your system before proceeding:

1. **Docker & Docker Compose**:
   * Windows/macOS: Install [Docker Desktop](https://www.docker.com/products/docker-desktop/).
   * Linux: Install `docker-ce` and `docker-compose-plugin`.
2. **Conda or Python 3.10+**:
   * Install [Miniconda](https://docs.anaconda.com/miniconda/) or Python 3.10/3.11/3.12.
3. **Ollama (Optional - for local LLMs)**:
   * Download and install from [Ollama.com](https://ollama.com/).
4. **Git**:
   * Ensure `git` is available in your shell.

---

## 🚀 Step-by-Step Installation

### Step 1: Clone the Repository
```bash
git clone https://github.com/your-username/local-ai-workspace.git
cd local-ai-workspace
```

### Step 2: Configure Environment Variables
Create a `.env` file in the root of the workspace directory to securely manage API keys.
```bash
cp .env.example .env
```
Open `.env` in a text editor and fill in your keys (e.g. `GEMINI_API_KEY`, etc.):
```env
# Google Gemini API Key (Optional - for cloud model backups)
GEMINI_API_KEY="your_api_key_here"
```

### Step 3: Set Up the Python Environment
Create a virtual environment (Conda or native venv) and install dependencies.

**Using Conda (Recommended):**
```bash
# Create and activate environment
conda create -n local-ai python=3.11 -y
conda activate local-ai

# Install Python packages
pip install -r requirements.txt
```
*Note: If you have network connection timeouts during installation, you can speed up downloads by using a PyPI mirror:*
```bash
pip install -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple/
```

### Step 4: Pull Local LLM Models (Ollama)
If you are planning to run models locally on your GPU, start the Ollama application and download the recommended models in your terminal:
```bash
# General responder & RAG model
ollama pull gemma2:9b

# Specialized coding assistant (needs 16GB+ RAM)
ollama pull qwen2.5-coder:32b

# Local text embeddings model
ollama pull nomic-embed-text
```

### Step 5: Launch the Tools Stack
Ensure Docker is active, then launch the interactive controller:
```bash
chmod +x start_tools.sh stop_tools.sh start_letta.sh start_aider.sh
./start_tools.sh
```
Choose an option to launch your desired tool stack. 

---

## ⚙️ Troubleshooting & Optimizations

### 1. macOS Unified Memory Optimization
On Apple Silicon, PyTorch might throw out-of-memory errors on large workloads due to strict allocation limits. You can optimize this by disabling the MPS memory allocator watermark limit in your shell:
```bash
export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0
```
This is pre-configured inside our ComfyUI and Fooocus launcher scripts.

### 2. WSL2 Port Mapping (Windows)
When running inside WSL2 on Windows, Docker containers bind to the Linux environment's localhost. Ensure WSL2 port forwarding is active so you can access the URLs (e.g., `http://localhost:3000`) directly from your Windows web browsers.
