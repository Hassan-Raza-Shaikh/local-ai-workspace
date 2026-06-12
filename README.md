# 🧠 Hassan's Local AI Workspace Hub

Welcome to your central workspace for local AI engineering, agents, and private document search on your MacBook Pro.

---

## 📂 Workspace Folder Structure

*   📁 **`odysseus/`**: Your self-hosted local AI dashboard workspace. Contains your local vector databases, notes, task manager, and local chat client.
*   📁 **`data/`**: The directory to drop your private documents (PDFs, Word docs, CSVs, TXT files). The RAG scripts and Odysseus automatically index files dropped here.
*   📁 **`notebooks/`**: Your local scratchpad for Python scripts and Jupyter notebook experiments using LangChain and LlamaIndex.
*   📄 **`start_workspace.sh`**: The master launch script that starts your environment.

---

## 🚀 How to Run the Workspace

You can launch your local AI dashboard simply by running the master script in your terminal:

```bash
/Users/hassan/local-ai/start_workspace.sh
```

**What this script does:**
1.  Verifies if **Docker Desktop** is running (starts it if it isn't).
2.  Verifies if **Ollama** is active (starts it if it isn't).
3.  Launches the Odysseus docker stack (fastapi backend, react frontend, ChromaDB vector store, and SearXNG search engine).
4.  Opens your browser automatically to the Odysseus UI at **http://localhost:7000**.

---

## 🛠️ Included Tools & How to Use Them

### 1. File Conversion (`markitdown`)
You have Microsoft's `markitdown` installed in your path. Before feeding PDFs, Word files, or Excel sheets to local models, you can convert them into clean markdown tables and structured text:

```bash
markitdown your_file.pdf > data/your_file.md
```

### 2. Local Document Search Demo (RAG)
We have written a local RAG demo script inside `notebooks/` that reads documents from your `data/` folder, indexes them locally, and queries them using your local Llama 3 model.

To run it:
```bash
python /Users/hassan/local-ai/notebooks/query_local_data.py
```

### 3. Asynchronous Chat Interface (Chainlit)
You have a full-featured, streaming ChatGPT-like web interface that runs locally.

To launch the Chat UI:
```bash
chainlit run /Users/hassan/local-ai/apps/chat_ui.py
```

### 4. Local AI Data Dashboard (Streamlit)
You have a structured data and analysis dashboard to summarize text and generate embeddings:

To launch the Dashboard:
```bash
streamlit run /Users/hassan/local-ai/apps/data_dashboard.py
```

### 5. Multi-Agent Collaboration (CrewAI)
You have a local script that coordinates multiple autonomous agents working together locally to solve tech research tasks:

To run the Crew demo:
```bash
python /Users/hassan/local-ai/notebooks/local_crew_agent.py
```

### 6. IDE Local Copilot (Continue.dev)
We have configured your system settings for Continue.dev to automatically use Llama 3 for chat, autocomplete, and refactoring commands.
*   **Settings Location**: [config.json](file:///Users/hassan/.continue/config.json)
*   **Action**: Simply install the **Continue** extension in VS Code or Cursor. It will read this config and immediately enable local code autocomplete!

---

## ☁️ Hybrid Local-Cloud Support (Google Gemini)

You can run both the RAG script and the CrewAI multi-agent script using a premium, fast cloud model (Google Gemini) instead of local Ollama. This bypasses local CPU/GPU limits and local model knowledge cutoffs.

### Setup and Configuration

1. **API Credentials**: Save your Gemini API key in the root environment file at [`/Users/hassan/local-ai/.env`](file:///Users/hassan/local-ai/.env):
   ```env
   GEMINI_API_KEY="your_api_key_here"
   ```
   *(Note: This file is automatically ignored by Git via `.gitignore` to keep your credentials private).*

2. **Toggle AI Engine**:
   In both `notebooks/query_local_data.py` and `notebooks/local_crew_agent.py`, find the configuration toggle at the top and set:
   ```python
   # Set AI_ENGINE to "local" (uses Ollama Llama 3) or "cloud" (uses Google Gemini 2.5)
   AI_ENGINE = "cloud"
   ```
   Set it back to `"local"` to run fully offline using Ollama.

3. **Configured Cloud Models**:
   - **LLM**: `models/gemini-2.5-flash`
   - **Embeddings**: `models/gemini-embedding-2`

---

## 🦙 Managing Local LLMs (Ollama)
Ollama runs in your Mac's menu bar and executes models using Apple Silicon's GPU. Here are the most useful commands:

*   **List downloaded models**:
    ```bash
    ollama list
    ```
*   **Pull a new model** (e.g. Google's Gemma 2):
    ```bash
    ollama pull gemma2
    ```
*   **Pull a dedicated embedding model** (for fast document indexing):
    ```bash
    ollama pull nomic-embed-text
    ```
*   **Run a model directly in your command line**:
    ```bash
    ollama run llama3
    ```
