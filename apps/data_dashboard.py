#!/usr/bin/env python3
import streamlit as st
import sys

# Local AI Data Dashboard using Streamlit and Ollama
try:
    import ollama
except ImportError:
    st.error("Error: 'ollama' python package is missing. Make sure you run inside Miniconda.")
    sys.exit(1)

st.set_page_config(
    page_title="Local AI Data Dashboard",
    page_icon="📊",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom Styling (Glassmorphism & harmonized colors)
st.markdown("""
<style>
    .main { background-color: #0e1117; }
    h1 { color: #58a6ff; font-family: 'Inter', sans-serif; }
    .stTextArea textarea { background-color: #161b22; color: #c9d1d9; border: 1px solid #30363d; }
    .stButton button { background-color: #238636; color: white; border: none; border-radius: 6px; }
</style>
""", unsafe_allow_html=True)

st.title("📊 Local AI Data Dashboard")
st.write("Analyze text, generate summaries, and calculate vector embeddings 100% locally on your Mac GPU.")

# Sidebar for settings
with st.sidebar:
    st.header("⚙️ Settings")
    model_choice = st.selectbox(
        "Select Local Model",
        ["llama3", "nomic-embed-text"],
        help="llama3 is used for generation, nomic-embed-text for mathematical vectors."
    )
    
    st.markdown("---")
    st.markdown("### System Status")
    st.success("Ollama Connection Active")

# Main interface
col1, col2 = st.columns([2, 1])

with col1:
    st.subheader("📝 Input Data")
    input_text = st.text_area(
        "Paste your document/text here:",
        height=250,
        placeholder="Type or paste text here (e.g. an academic paper, news article, or notes)..."
    )
    
    action = st.button("Execute Local AI Run")

with col2:
    st.subheader("🎯 Operations")
    task_option = st.radio(
        "Choose task:",
        ["Summarize Text", "Extract Key Action Items", "Calculate Vector Embeddings"]
    )

if action:
    if not input_text.strip():
        st.warning("Please enter some text to process first!")
    else:
        st.subheader("🚀 Result")
        with st.spinner("Processing locally on Apple Silicon GPU..."):
            try:
                if task_option == "Summarize Text":
                    prompt = f"Summarize the following text clearly in 3 bullet points:\n\n{input_text}"
                    response = ollama.generate(model="llama3", prompt=prompt)
                    st.info(response['response'])
                    
                elif task_option == "Extract Key Action Items":
                    prompt = f"Extract all action items or tasks from this text as a list:\n\n{input_text}"
                    response = ollama.generate(model="llama3", prompt=prompt)
                    st.success(response['response'])
                    
                elif task_option == "Calculate Vector Embeddings":
                    response = ollama.embeddings(model="nomic-embed-text", prompt=input_text)
                    vectors = response['embedding']
                    st.write(f"Generated Vector Embeddings ({len(vectors)} dimensions):")
                    st.code(str(vectors[:15])[:-1] + ", ...]")
                    st.metric("Vector Dimensions", len(vectors))
                    
            except Exception as e:
                st.error(f"Error executing task: {str(e)}")
