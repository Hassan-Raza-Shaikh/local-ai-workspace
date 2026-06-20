#!/usr/bin/env python3
import os
import sys
import asyncio
from dotenv import load_dotenv

# Load env variables from local-ai root
load_dotenv(os.path.join(os.path.dirname(__file__), "../.env"))

try:
    from browser_use import Agent
    from langchain_google_genai import ChatGoogleGenerativeAI
except ImportError:
    print("Error: Required libraries not found. Run pip install browser-use langchain-google-genai")
    sys.exit(1)

async def main():
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        print("❌ Error: GEMINI_API_KEY is missing in your .env file!")
        print("Please add it to /Users/hassan/local-ai/.env")
        sys.exit(1)
        
    print("Initializing browser agent with Gemini 2.5 Flash...")
    llm = ChatGoogleGenerativeAI(model="gemini-2.5-flash", google_api_key=api_key)
    
    # Define browser agent task
    task = "Search for the latest release version of the python package 'browser-use' on PyPI and tell me the version number."
    
    print(f"Running task: '{task}'")
    agent = Agent(
        task=task,
        llm=llm,
    )
    
    print("Starting agent... (Playwright will open Chromium browser in headless mode)")
    result = agent.run()
    # Since agent.run() is async, we await it
    output = await result
    
    print("\n=== Agent Result ===")
    print(output)
    print("====================\n")

if __name__ == "__main__":
    asyncio.run(main())
