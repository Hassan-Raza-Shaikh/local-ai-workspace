#!/usr/bin/env python3
import sys
import os
import asyncio

# Add error handling for missing packages
try:
    from crawl4ai import AsyncWebCrawler
except ImportError:
    print("Error: 'crawl4ai' package is missing in active environment.")
    sys.exit(1)

async def crawl(url, output_path):
    print(f"Initializing Crawl4AI scraper...")
    async with AsyncWebCrawler() as crawler:
        print(f"Scraping URL: {url}...")
        try:
            result = await crawler.arun(url=url)
            # Write markdown result to target path
            with open(output_path, "w", encoding="utf-8") as f:
                f.write(result.markdown)
            print("\n=== Scraping Completed! ===")
            print(f"Saved Markdown file to: {output_path}")
            print("===========================\n")
        except Exception as e:
            print(f"❌ Scraping failed: {e}")
            sys.exit(1)

def main():
    if len(sys.argv) < 3:
        print("Usage: python crawl_site.py <url> <output_file_path>")
        sys.exit(1)
    
    url = sys.argv[1]
    output_path = sys.argv[2]
    
    # Run async loop
    asyncio.run(crawl(url, output_path))

if __name__ == "__main__":
    main()
