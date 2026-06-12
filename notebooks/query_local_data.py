#!/usr/bin/env python3
import os
import sys

# Simple local RAG example using LlamaIndex and Ollama
try:
    from llama_index.core import VectorStoreIndex, SimpleDirectoryReader, Settings
    from llama_index.llms.ollama import Ollama
    from llama_index.embeddings.ollama import OllamaEmbedding
except ImportError:
    print("Error: LlamaIndex packages are missing. Make sure you run your script using the Miniconda python.")
    sys.exit(1)

def main():
    print("=== Initialize Local RAG System ===")
    
    # 1. Setup local LLM via Ollama (using the llama3 model we pulled)
    print("Connecting to local Ollama (Llama 3)...")
    llm = Ollama(model="llama3", request_timeout=120.0)
    Settings.llm = llm
    
    # Use Ollama's local nomic-embed-text model for embeddings (100% local)
    print("Initializing local nomic-embed-text embedding engine...")
    embed_model = OllamaEmbedding(model_name="nomic-embed-text")
    Settings.embed_model = embed_model
    
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
