#!/usr/bin/env python3
import os
import sys
from dotenv import load_dotenv

# ============================================================
# ⚙️ CONFIGURATION TOGGLE
# Set AI_ENGINE to "local" (uses Ollama Llama 3) or "cloud" (uses Google Gemini 1.5)
AI_ENGINE = "cloud" 
# ============================================================

# Load environment variables from local-ai root
load_dotenv(os.path.join(os.path.dirname(__file__), "../.env"))

try:
    from llama_index.core import VectorStoreIndex, SimpleDirectoryReader, Settings
    if AI_ENGINE == "cloud":
        from llama_index.llms.gemini import Gemini
        from llama_index.embeddings.gemini import GeminiEmbedding
    else:
        from llama_index.llms.ollama import Ollama
        from llama_index.embeddings.ollama import OllamaEmbedding
except ImportError:
    print("Error: LlamaIndex packages are missing. Make sure you run inside Miniconda.")
    sys.exit(1)

def main():
    print("=== Initialize Local RAG System ===")
    
    if AI_ENGINE == "cloud":
        # 1. Setup Cloud Gemini LLM and Embeddings
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            print("\n❌ Error: GEMINI_API_KEY is missing in your .env file!")
            print("Please create an API key at https://aistudio.google.com/ and add it to /Users/hassan/local-ai/.env")
            sys.exit(1)
            
        print("Connecting to cloud Google Gemini (2.5 Flash)...")
        Settings.llm = Gemini(model="models/gemini-2.5-flash", api_key=api_key)
        
        print("Initializing cloud Gemini embedding engine...")
        Settings.embed_model = GeminiEmbedding(model_name="models/gemini-embedding-2", api_key=api_key)
    else:
        # 1. Setup Local Ollama LLM and Embeddings
        print("Connecting to local Ollama (Llama 3)...")
        Settings.llm = Ollama(model="llama3", request_timeout=120.0)
        
        print("Initializing local nomic-embed-text embedding engine...")
        Settings.embed_model = OllamaEmbedding(model_name="nomic-embed-text")
    
    # 2. Check if there are files to read
    data_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "../data"))
    if not os.path.exists(data_dir):
        os.makedirs(data_dir)
        
    files = os.listdir(data_dir)
    if not files or all(f.startswith('.') for f in files):
        print(f"\n📂 No files found in your data folder: {data_dir}")
        print("Please drop some text files, PDFs, or docs in that folder, then run this script again.")
        print("\nCreating a sample file to test...")
        sample_path = os.path.join(data_dir, "test_note.txt")
        with open(sample_path, "w") as f:
            f.write("Hassan's MacBook Pro is a high-performance machine powered by an M1 Pro Apple Silicon processor with 16GB unified memory.")
        print(f"Created: {sample_path}")
    
    # 3. Read documents
    print("\nReading documents from data/...")
    documents = SimpleDirectoryReader(data_dir).load_data()
    
    # 4. Create local vector index
    print("Indexing documents into local vector store...")
    index = VectorStoreIndex.from_documents(documents)
    
    # 5. Query the model
    query_engine = index.as_query_engine()
    
    query = "What kind of processor does Hassan's MacBook Pro have?"
    print(f"\nQuerying: '{query}'")
    
    response = query_engine.query(query)
    print("\n=== Response ===")
    print(response)
    print("================")

if __name__ == "__main__":
    main()
