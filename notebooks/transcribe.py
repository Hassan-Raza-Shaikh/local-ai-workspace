#!/usr/bin/env python3
import os
import sys
import torch
import whisper

def main():
    if len(sys.argv) < 2:
        print("Usage: python transcribe.py <path_to_audio_file>")
        sys.exit(1)
        
    audio_path = sys.argv[1]
    if not os.path.exists(audio_path):
        print(f"Error: File not found at {audio_path}")
        sys.exit(1)
        
    print("Checking hardware acceleration...")
    # Determine the best device available (MPS for Apple Silicon)
    if torch.backends.mps.is_available():
        device = "mps"
        print("🚀 Found Apple Silicon GPU (MPS) acceleration! Using GPU.")
    elif torch.cuda.is_available():
        device = "cuda"
        print("🚀 Found NVIDIA GPU (CUDA) acceleration! Using GPU.")
    else:
        device = "cpu"
        print("⚠️ Using CPU for transcription (this may be slower).")
        
    print("Loading Whisper model (base)...")
    # 'base' model is a great balance of speed and quality
    model = whisper.load_model("base", device=device)
    
    print(f"Transcribing audio file: {audio_path}...")
    result = model.transcribe(audio_path)
    
    print("\n=== Transcription Result ===")
    print(result["text"].strip())
    print("============================\n")
    
    # Save output to same directory with .txt extension
    output_path = os.path.splitext(audio_path)[0] + ".txt"
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(result["text"].strip())
    print(f"Saved transcription text to: {output_path}")

if __name__ == "__main__":
    main()
