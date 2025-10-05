"""
title: Long Term Memory Filter (Robust Version)
author: Bailey Caldwell / Anton Nilsson
date: 2024-10-04
version: 2.0
license: MIT
description: A robust filter that processes user messages and stores them as long term memory using mem0, qdrant and ollama with comprehensive error handling
requirements: pydantic, ollama, mem0ai
"""

from typing import List, Optional
from pydantic import BaseModel
import json
import threading
import time

class Pipeline:
    class Valves(BaseModel):
        pipelines: List[str] = []
        priority: int = 0

        store_cycles: int = 3  # Number of messages before storing memory
        mem_zero_user: str = "bailey"  # User ID for memory organization

        # Qdrant configuration
        vector_store_qdrant_name: str = "memories"
        vector_store_qdrant_url: str = "host.docker.internal"
        vector_store_qdrant_port: int = 6333
        vector_store_qdrant_dims: int = 768

        # Ollama LLM configuration
        ollama_llm_model: str = "qwen2.5:7b"
        ollama_llm_temperature: float = 0
        ollama_llm_tokens: int = 8000
        ollama_llm_url: str = "http://host.docker.internal:11434"

        # Ollama embedder configuration
        ollama_embedder_model: str = "nomic-embed-text:latest"
        ollama_embedder_url: str = "http://host.docker.internal:11434"

        # Feature flags
        enable_memory_storage: bool = True
        enable_memory_search: bool = True
        debug_mode: bool = True

    def __init__(self):
        self.type = "filter"
        self.name = "Memory Filter"
        self.user_messages = []
        self.thread = None
        self.m = None  # Lazy initialization
        self.memory_available = False
        self.valves = self.Valves(
            **{
                "pipelines": ["*"],  # Connect to all pipelines
            }
        )

    async def on_startup(self):
        if self.valves.debug_mode:
            print(f"🚀 Starting mem0 memory filter pipeline")

    async def on_shutdown(self):
        if self.valves.debug_mode:
            print(f"🛑 Shutting down mem0 memory filter pipeline")

    def get_memory(self):
        """Lazy initialization of memory instance with robust error handling"""
        if self.m is None and not hasattr(self, '_init_failed'):
            try:
                if self.valves.debug_mode:
                    print("🔄 Initializing mem0 memory...")
                
                from mem0 import Memory
                
                config = {
                    "vector_store": {
                        "provider": "qdrant",
                        "config": {
                            "collection_name": self.valves.vector_store_qdrant_name,
                            "host": self.valves.vector_store_qdrant_url,
                            "port": self.valves.vector_store_qdrant_port,
                            "embedding_model_dims": self.valves.vector_store_qdrant_dims,
                        },
                    },
                    "llm": {
                        "provider": "ollama",
                        "config": {
                            "model": self.valves.ollama_llm_model,
                            "temperature": self.valves.ollama_llm_temperature,
                            "max_tokens": self.valves.ollama_llm_tokens,
                            "ollama_base_url": self.valves.ollama_llm_url,
                        },
                    },
                    "embedder": {
                        "provider": "ollama",
                        "config": {
                            "model": self.valves.ollama_embedder_model,
                            "ollama_base_url": self.valves.ollama_embedder_url,
                        },
                    },
                }
                
                self.m = Memory.from_config(config)
                self.memory_available = True
                
                if self.valves.debug_mode:
                    print("✅ Memory initialized successfully")
                    
            except Exception as e:
                self._init_failed = True
                self.memory_available = False
                if self.valves.debug_mode:
                    print(f"❌ Failed to initialize memory: {str(e)}")
                    print("🔄 Continuing without memory functionality")
                
        return self.m if self.memory_available else None

    async def inlet(self, body: dict, user: Optional[dict] = None) -> dict:
        """Process incoming messages with robust error handling"""
        try:
            if self.valves.debug_mode:
                print(f"🔄 Processing message through mem0 pipeline")

            # Validate input
            if not isinstance(body, dict):
                if isinstance(body, str):
                    try:
                        body = json.loads(body)
                    except:
                        if self.valves.debug_mode:
                            print("❌ Invalid JSON body, skipping memory processing")
                        return body
                else:
                    if self.valves.debug_mode:
                        print("❌ Invalid body type, skipping memory processing")
                    return body

            if "messages" not in body or not body["messages"]:
                if self.valves.debug_mode:
                    print("❌ No messages found, skipping memory processing")
                return body

            user_id = self.valves.mem_zero_user
            all_messages = body["messages"]
            
            # Get the last user message
            last_user_message = None
            for msg in reversed(all_messages):
                if msg.get("role") == "user" and msg.get("content"):
                    last_user_message = msg.get("content", "").strip()
                    break
            
            if not last_user_message:
                if self.valves.debug_mode:
                    print("❌ No user message found, skipping memory processing")
                return body

            if self.valves.debug_mode:
                print(f"📝 Processing user message: {last_user_message[:100]}...")

            # Handle memory storage
            if self.valves.enable_memory_storage:
                self._handle_memory_storage(last_user_message, user_id)

            # Handle memory search
            if self.valves.enable_memory_search:
                self._handle_memory_search(last_user_message, user_id, all_messages)

            if self.valves.debug_mode:
                print("✅ Memory processing completed")
                
            return body

        except Exception as e:
            if self.valves.debug_mode:
                print(f"❌ Critical error in mem0 pipeline: {str(e)}")
            # Always return the original body to prevent breaking the chat
            return body

    def _handle_memory_storage(self, message: str, user_id: str):
        """Handle memory storage with error handling"""
        try:
            self.user_messages.append(message)

            if len(self.user_messages) >= self.valves.store_cycles:
                memory = self.get_memory()
                if memory:
                    message_text = " ".join(self.user_messages)
                    
                    # Wait for previous thread if still running
                    if self.thread and self.thread.is_alive():
                        if self.valves.debug_mode:
                            print("⏳ Waiting for previous memory storage...")
                        self.thread.join(timeout=2.0)  # Short timeout

                    if self.valves.debug_mode:
                        print(f"💾 Storing memory: {message_text[:100]}...")
                    
                    # Store memory in background thread
                    self.thread = threading.Thread(
                        target=self._safe_memory_add, 
                        args=(memory, message_text, user_id)
                    )
                    self.thread.daemon = True  # Don't block shutdown
                    self.thread.start()
                
                self.user_messages.clear()
                
        except Exception as e:
            if self.valves.debug_mode:
                print(f"❌ Error in memory storage: {str(e)}")

    def _handle_memory_search(self, message: str, user_id: str, all_messages: list):
        """Handle memory search with error handling"""
        try:
            memory = self.get_memory()
            if not memory:
                return

            if self.valves.debug_mode:
                print(f"🔍 Searching memories for: {message[:50]}...")
            
            # Simple timeout by limiting search complexity
            memories = memory.search(message, user_id=user_id, limit=3)
            
            if memories and len(memories) > 0:
                # Get the best memory
                best_memory = memories[0]
                fetched_memory = ""
                
                # Handle different response formats
                if isinstance(best_memory, dict):
                    fetched_memory = best_memory.get("memory", "")
                elif hasattr(best_memory, "memory"):
                    fetched_memory = best_memory.memory
                
                if fetched_memory and len(fetched_memory.strip()) > 0:
                    if self.valves.debug_mode:
                        print(f"🧠 Found relevant memory: {fetched_memory[:100]}...")
                    
                    # Insert memory as system message
                    memory_message = {
                        "role": "system", 
                        "content": f"Context from your memory: {fetched_memory}"
                    }
                    all_messages.insert(0, memory_message)
                else:
                    if self.valves.debug_mode:
                        print("🔍 No relevant memories found")
            else:
                if self.valves.debug_mode:
                    print("🔍 No memories returned from search")
                    
        except Exception as e:
            if self.valves.debug_mode:
                print(f"❌ Error searching memories: {str(e)}")

    def _safe_memory_add(self, memory, message_text: str, user_id: str):
        """Safely add memory in background thread"""
        try:
            memory.add(message_text, user_id=user_id)
            if self.valves.debug_mode:
                print(f"✅ Memory stored successfully for user: {user_id}")
        except Exception as e:
            if self.valves.debug_mode:
                print(f"❌ Error in background memory storage: {str(e)}")
