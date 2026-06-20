#!/usr/bin/env python3
import os
import sys

try:
    from markitdown import MarkItDown
except ImportError:
    print("Error: 'markitdown' package is missing in active environment.")
    sys.exit(1)

def main():
    if len(sys.argv) < 2:
        print("Usage: python convert_doc.py <input_file_path> [<output_file_path>]")
        sys.exit(1)
        
    input_path = sys.argv[1]
    if not os.path.exists(input_path):
        print(f"Error: File not found at {input_path}")
        sys.exit(1)
        
    # Setup output path
    if len(sys.argv) >= 3:
        output_path = sys.argv[2]
    else:
        # Default: replace current extension with .md
        output_path = os.path.splitext(input_path)[0] + ".md"
        
    print(f"Initializing MarkItDown converter...")
    md = MarkItDown()
    
    print(f"Converting document: {input_path}...")
    try:
        result = md.convert(input_path)
        
        # Save results
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(result.text_content)
            
        print("\n=== Conversion Completed! ===")
        print(f"Saved Markdown file to: {output_path}")
        print("=============================\n")
        
    except Exception as e:
        print(f"❌ Conversion failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
