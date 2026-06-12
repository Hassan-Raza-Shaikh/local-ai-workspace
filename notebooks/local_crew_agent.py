#!/usr/bin/env python3
import sys

# Demonstration of a local multi-agent Crew using CrewAI and Ollama Llama 3
try:
    from crewai import Agent, Task, Crew, Process, LLM
except ImportError:
    print("Error: 'crewai' python package is missing. Make sure you run inside Miniconda.")
    sys.exit(1)

def main():
    print("=== Initialize Local AI Crew ===")
    
    # 1. Setup local LLM configuration (pointing to Ollama Llama 3)
    # Llama 3 8B is excellent at instruction following for agent roles
    print("Connecting to local Ollama (Llama 3)...")
    local_llm = LLM(
        model="ollama/llama3",
        base_url="http://localhost:11434"
    )

    # 2. Define our Agents with distinct roles and backstories
    print("Assembling the agents...")
    researcher = Agent(
        role="Senior Technology Researcher",
        goal="Uncover insights and analyze the benefits of local-first AI architectures.",
        backstory="You are an expert tech analyst at a leading research firm, specialized in hardware accelerators and local-first software engineering.",
        verbose=True,
        llm=local_llm
    )

    writer = Agent(
        role="Technical Content Writer",
        goal="Explain complex technology breakthroughs in simple, compelling articles.",
        backstory="You are a veteran technical editor with a gift for simplifying complex hardware concepts into engaging, developer-friendly summaries.",
        verbose=True,
        llm=local_llm
    )

    # 3. Define the collaborative tasks
    print("Defining tasks...")
    research_task = Task(
        description=(
            "Analyze the key benefits of running LLMs locally on Apple Silicon (M1/M2/M3) unified memory GPUs "
            "compared to cloud-hosted APIs like OpenAI."
        ),
        expected_output="A bulleted summary highlighting the top 3 hardware advantages.",
        agent=researcher
    )

    writing_task = Task(
        description="Convert the researcher's findings into a short, engaging 2-paragraph newsletter update for developers.",
        expected_output="A clean, markdown-formatted 2-paragraph newsletter summary.",
        agent=writer
    )

    # 4. Assemble the Crew
    print("Starting the cooperative run (kicking off sequential process)...")
    crew = Crew(
        agents=[researcher, writer],
        tasks=[research_task, writing_task],
        process=Process.sequential
    )

    # 5. Kickoff!
    result = crew.kickoff()
    
    print("\n=== Crew Collaboration Result ===")
    print(result)
    print("=================================")

if __name__ == "__main__":
    main()
