#!/usr/bin/env python3
import os
import sys
import asyncio
from dotenv import load_dotenv

# Load environment keys from workspace .env
load_dotenv("/Users/hassan/local-ai/.env")

try:
    from browser_use import Agent, Browser, BrowserConfig
    from langchain_google_genai import ChatGoogleGenerativeAI
except ImportError:
    print("Error: Required libraries not found. Running pip installation guide.")
    print("Install via: pip install browser-use langchain-google-genai Playwright")
    sys.exit(1)

async def main():
    if len(sys.argv) < 2:
        print("Usage: python run_browser_agent.py <task_description> [headless_boolean]")
        sys.exit(1)
        
    task_desc = sys.argv[1]
    
    # Parse headless argument
    headless = True
    if len(sys.argv) >= 3:
        headless_arg = sys.argv[2].lower()
        if headless_arg == "false" or headless_arg == "0":
            headless = False
            
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        print("❌ Error: GEMINI_API_KEY is missing in your workspace .env file!")
        sys.exit(1)
        
    print(f"Initializing browser agent (Headless: {headless}) using Gemini 2.5 Flash...")
    llm = ChatGoogleGenerativeAI(model="gemini-2.5-flash", google_api_key=api_key)
    
    # Configure browser config (visible vs headless)
    config = BrowserConfig(headless=headless)
    browser = Browser(config=config)
    
    print(f"Executing browser agent task:\n\"{task_desc}\"\n")
    agent = Agent(
        task=task_desc,
        llm=llm,
        browser=browser
    )
    
    try:
        result = await agent.run()
        print("\n=== Agent Result ===")
        print(result)
        print("====================\n")
    except Exception as e:
        print(f"❌ Execution failed: {e}")
        sys.exit(1)
    finally:
        await browser.close()

if __name__ == "__main__":
    asyncio.run(main())
