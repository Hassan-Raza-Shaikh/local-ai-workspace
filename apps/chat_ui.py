#!/usr/bin/env python3
import chainlit as cl
import sys

# Sleek local streaming Chat UI using Chainlit and Ollama
try:
    import ollama
except ImportError:
    print("Error: 'ollama' python package is missing. Make sure you run inside Miniconda.")
    sys.exit(1)

@cl.on_chat_start
async def start():
    cl.user_session.set("history", [])
    # Set a custom avatar and clean starting message
    await cl.Message(
        content="👋 Hello Hassan! I am **Llama 3**, your local AI assistant running offline on your MacBook Pro GPU. How can I help you build today?"
    ).send()

@cl.on_message
async def main(message: cl.Message):
    # Retrieve chat history from session
    history = cl.user_session.get("history")
    history.append({"role": "user", "content": message.content})
    
    # Prepare a streaming message container in the UI
    msg = cl.Message(content="")
    await msg.send()
    
    try:
        # Use Ollama AsyncClient for real-time token streaming
        client = ollama.AsyncClient()
        async for chunk in await client.chat(model='llama3', messages=history, stream=True):
            token = chunk.get('message', {}).get('content', '')
            if token:
                await msg.stream_token(token)
    except Exception as e:
        await cl.Message(content=f"❌ Error communicating with Ollama: {str(e)}").send()
        return
        
    # Append assistant's final response to session history
    history.append({"role": "assistant", "content": msg.content})
    cl.user_session.set("history", history)
    await msg.update()
