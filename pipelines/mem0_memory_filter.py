"""
title: Long Term Memory Filter
author: Anton Nilsson (Modified for NumberOne OWU)
date: 2024-12-04
version: 2.0
license: MIT
description: A filter that processes user messages and stores them as long term memory by utilizing the mem0 framework together with qdrant and ollama
requirements: pydantic, ollama, mem0ai
"""

from typing import List, Optional
from pydantic import BaseModel
import json
from mem0 import Memory
import threading
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class Pipeline:
    class Valves(BaseModel):
        pipelines: List[str] = []
        priority: int = 0

        # Memory Configuration
        store_cycles: int = 3  # Number of messages from the user before the data is processed and added to the memory
        mem_zero_user: str = "bailey"  # Memories belongs to this user, only used by mem0 for internal organization of memories
        
        # Enable/disable memory features
        enable_memory_storage: bool = True
        enable_memory_retrieval: bool = True
        enable_memory_logging: bool = True

        # Default values for the mem0 vector store (Qdrant)
        vector_store_qdrant_name: str = "memories"
        vector_store_qdrant_url: str = "qdrant"  # Docker service name
        vector_store_qdrant_port: int = 6333
        vector_store_qdrant_dims: int = 768  # Need to match the vector dimensions of the embedder model

        # Default values for the mem0 language model (Ollama)
        ollama_llm_model: str = "qwen2.5:7b"  # This model need to exist in ollama
        ollama_llm_temperature: float = 0
        ollama_llm_tokens: int = 8000
        ollama_llm_url: str = "http://ollama:11434"  # Docker service name

        # Default values for the mem0 embedding model (Ollama)
        ollama_embedder_model: str = "nomic-embed-text:latest"  # This model need to exist in ollama
        ollama_embedder_url: str = "http://ollama:11434"  # Docker service name

        # Memory retrieval settings
        max_memories_retrieved: int = 3
        memory_relevance_threshold: float = 0.7
        memory_context_template: str = "This is your inner voice talking, you remember this about the person you're chatting with: {memory}"

    def __init__(self):
        self.type = "filter"
        self.name = "Memory Filter"
        self.user_messages = []
        self.thread = None
        self.m = None  # Initialize lazily
        self.valves = self.Valves(
            **{
                "pipelines": ["*"],  # Connect to all pipelines
            }
        )
        logger.info(f"Initialized {self.name} pipeline")

    async def on_startup(self):
        logger.info(f"on_startup:{__name__}")
        # Test memory connection on startup
        try:
            memory = self.get_memory()
            logger.info("Memory system initialized successfully")
        except Exception as e:
            logger.error(f"Failed to initialize memory system: {e}")

    async def on_shutdown(self):
        logger.info(f"on_shutdown:{__name__}")
        # Wait for any pending memory operations
        if self.thread and self.thread.is_alive():
            logger.info("Waiting for memory operations to complete...")
            self.thread.join(timeout=10)

    def get_memory(self):
        """Lazy initialization of memory instance"""
        if self.m is None:
            try:
                self.m = self.init_mem_zero()
                logger.info("Memory instance created successfully")
            except Exception as e:
                logger.error(f"Failed to create memory instance: {e}")
                raise
        return self.m

    async def inlet(self, body: dict, user: Optional[dict] = None) -> dict:
        """Process incoming messages and add memory context"""
        if self.valves.enable_memory_logging:
            logger.info(f"Processing message through {__name__}")

        # Use configured user or fallback to valve setting
        user_id = self.valves.mem_zero_user
        if user and user.get("id"):
            user_id = user["id"]

        store_cycles = self.valves.store_cycles

        # Parse body if it's a string
        if isinstance(body, str):
            body = json.loads(body)

        all_messages = body.get("messages", [])
        if not all_messages:
            return body

        last_message = all_messages[-1].get("content", "")
        
        # Store user messages for memory creation
        if self.valves.enable_memory_storage:
            self.user_messages.append(last_message)

            # Check if we should store memories
            if len(self.user_messages) >= store_cycles:
                await self._store_memories(user_id)

        # Retrieve and add relevant memories to context
        if self.valves.enable_memory_retrieval:
            await self._add_memory_context(all_messages, last_message, user_id)

        if self.valves.enable_memory_logging:
            logger.info("Message processing completed")

        return body

    async def _store_memories(self, user_id: str):
        """Store accumulated messages as memories"""
        try:
            # Combine messages into a single text
            message_text = " ".join(self.user_messages)
            
            # Wait for any previous memory operation to complete
            if self.thread and self.thread.is_alive():
                logger.info("Waiting for previous memory operation to complete")
                self.thread.join(timeout=5)

            # Start memory storage in background thread
            memory = self.get_memory()
            self.thread = threading.Thread(
                target=self._store_memory_thread,
                args=(memory, message_text, user_id)
            )

            if self.valves.enable_memory_logging:
                logger.info(f"Storing memory for user {user_id}: {message_text[:100]}...")

            self.thread.start()
            self.user_messages.clear()

        except Exception as e:
            logger.error(f"Failed to store memories: {e}")
            self.user_messages.clear()  # Clear to prevent accumulation

    def _store_memory_thread(self, memory: Memory, text: str, user_id: str):
        """Thread function for storing memory"""
        try:
            memory.add(data=text, user_id=user_id)
            logger.info(f"Memory stored successfully for user {user_id}")
        except Exception as e:
            logger.error(f"Failed to store memory in thread: {e}")

    async def _add_memory_context(self, all_messages: list, last_message: str, user_id: str):
        """Retrieve relevant memories and add to message context"""
        try:
            memory = self.get_memory()
            memories = memory.search(
                query=last_message, 
                user_id=user_id,
                limit=self.valves.max_memories_retrieved
            )

            if memories:
                # Filter memories by relevance threshold
                relevant_memories = [
                    mem for mem in memories 
                    if mem.get("score", 0) >= self.valves.memory_relevance_threshold
                ]

                if relevant_memories:
                    # Use the most relevant memory
                    best_memory = relevant_memories[0]["memory"]
                    memory_context = self.valves.memory_context_template.format(memory=best_memory)
                    
                    # Insert memory context at the beginning
                    all_messages.insert(0, {
                        "role": "system", 
                        "content": memory_context
                    })

                    if self.valves.enable_memory_logging:
                        logger.info(f"Added memory context for user {user_id}: {best_memory[:100]}...")

        except Exception as e:
            logger.error(f"Failed to retrieve memories: {e}")

    def init_mem_zero(self):
        """Initialize Mem0 with configuration"""
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

        logger.info("Initializing Mem0 with configuration")
        return Memory.from_config(config)
