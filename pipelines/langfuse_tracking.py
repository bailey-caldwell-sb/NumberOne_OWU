"""
title: Langfuse LLM Tracking Pipeline
author: NumberOne OWU Team
date: 2024-12-04
version: 1.0
license: MIT
description: A pipeline that tracks LLM interactions using Langfuse for observability and analytics
requirements: pydantic, langfuse, requests
"""

from typing import List, Optional, Dict, Any
from pydantic import BaseModel
import json
import logging
import time
import uuid
from datetime import datetime

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

try:
    from langfuse import Langfuse
    LANGFUSE_AVAILABLE = True
except ImportError:
    logger.warning("Langfuse not available. Install with: pip install langfuse")
    LANGFUSE_AVAILABLE = False

class Pipeline:
    class Valves(BaseModel):
        pipelines: List[str] = []
        priority: int = 0

        # Langfuse Configuration
        langfuse_secret_key: str = ""
        langfuse_public_key: str = ""
        langfuse_host: str = "http://langfuse:3000"  # Docker service name
        
        # Tracking Configuration
        enable_tracking: bool = True
        enable_performance_tracking: bool = True
        enable_cost_tracking: bool = True
        enable_user_tracking: bool = True
        
        # Session Management
        session_timeout_minutes: int = 30
        auto_create_sessions: bool = True
        
        # Data Collection
        track_input_tokens: bool = True
        track_output_tokens: bool = True
        track_model_parameters: bool = True
        track_response_time: bool = True
        track_user_feedback: bool = True
        
        # Privacy Settings
        anonymize_user_data: bool = False
        exclude_system_messages: bool = False
        max_content_length: int = 10000  # Truncate long content
        
        # Cost Tracking (tokens per dollar - approximate)
        cost_per_input_token: float = 0.000001  # $1 per 1M tokens
        cost_per_output_token: float = 0.000002  # $2 per 1M tokens

    def __init__(self):
        self.type = "filter"
        self.name = "Langfuse Tracking"
        self.valves = self.Valves(
            **{
                "pipelines": ["*"],  # Connect to all pipelines
            }
        )
        self.langfuse = None
        self.active_traces = {}  # Store active traces by conversation ID
        self.start_times = {}  # Track request start times
        logger.info(f"Initialized {self.name} pipeline")

    async def on_startup(self):
        logger.info(f"on_startup:{__name__}")
        if LANGFUSE_AVAILABLE and self.valves.enable_tracking:
            await self._initialize_langfuse()

    async def on_shutdown(self):
        logger.info(f"on_shutdown:{__name__}")
        if self.langfuse:
            try:
                self.langfuse.flush()
                logger.info("Langfuse data flushed successfully")
            except Exception as e:
                logger.error(f"Error flushing Langfuse data: {e}")

    async def _initialize_langfuse(self):
        """Initialize Langfuse client"""
        try:
            if self.valves.langfuse_secret_key and self.valves.langfuse_public_key:
                self.langfuse = Langfuse(
                    secret_key=self.valves.langfuse_secret_key,
                    public_key=self.valves.langfuse_public_key,
                    host=self.valves.langfuse_host
                )
                logger.info("Langfuse client initialized successfully")
            else:
                logger.warning("Langfuse API keys not configured")
        except Exception as e:
            logger.error(f"Failed to initialize Langfuse: {e}")

    async def inlet(self, body: dict, user: Optional[dict] = None) -> dict:
        """Track incoming requests"""
        if not self._should_track():
            return body

        try:
            # Parse body if it's a string
            if isinstance(body, str):
                body = json.loads(body)

            # Generate or get conversation ID
            conversation_id = self._get_conversation_id(body, user)
            
            # Record start time
            self.start_times[conversation_id] = time.time()
            
            # Create or get trace
            trace = await self._create_or_get_trace(conversation_id, user)
            
            # Create generation span
            if trace:
                generation = await self._create_generation(trace, body, user)
                self.active_traces[conversation_id] = {
                    "trace": trace,
                    "generation": generation,
                    "start_time": time.time()
                }

            logger.info(f"Started tracking for conversation: {conversation_id}")

        except Exception as e:
            logger.error(f"Error in inlet tracking: {e}")

        return body

    async def outlet(self, body: dict, user: Optional[dict] = None) -> dict:
        """Track outgoing responses"""
        if not self._should_track():
            return body

        try:
            # Parse body if it's a string
            if isinstance(body, str):
                body = json.loads(body)

            # Get conversation ID
            conversation_id = self._get_conversation_id(body, user)
            
            # Update generation with response
            if conversation_id in self.active_traces:
                await self._update_generation(conversation_id, body)
                
            logger.info(f"Completed tracking for conversation: {conversation_id}")

        except Exception as e:
            logger.error(f"Error in outlet tracking: {e}")

        return body

    def _should_track(self) -> bool:
        """Check if tracking should be enabled"""
        return (
            LANGFUSE_AVAILABLE and 
            self.valves.enable_tracking and 
            self.langfuse is not None
        )

    def _get_conversation_id(self, body: dict, user: Optional[dict] = None) -> str:
        """Extract or generate conversation ID"""
        # Try to get from body
        conv_id = body.get("conversation_id") or body.get("chat_id")
        
        if not conv_id:
            # Generate based on user and timestamp
            user_id = self._get_user_id(user)
            conv_id = f"{user_id}_{int(time.time())}"
        
        return str(conv_id)

    def _get_user_id(self, user: Optional[dict] = None) -> str:
        """Extract user ID with privacy considerations"""
        if not user:
            return "anonymous"
        
        user_id = user.get("id") or user.get("email") or user.get("username")
        
        if self.valves.anonymize_user_data and user_id:
            # Create anonymous hash
            import hashlib
            user_id = hashlib.sha256(str(user_id).encode()).hexdigest()[:16]
        
        return user_id or "anonymous"

    async def _create_or_get_trace(self, conversation_id: str, user: Optional[dict] = None):
        """Create or retrieve existing trace"""
        if not self.langfuse:
            return None

        try:
            user_id = self._get_user_id(user)
            
            trace = self.langfuse.trace(
                id=conversation_id,
                name=f"Conversation_{conversation_id}",
                user_id=user_id,
                metadata={
                    "pipeline": self.name,
                    "timestamp": datetime.now().isoformat(),
                    "user_agent": "NumberOne_OWU"
                }
            )
            
            return trace

        except Exception as e:
            logger.error(f"Error creating trace: {e}")
            return None

    async def _create_generation(self, trace, body: dict, user: Optional[dict] = None):
        """Create generation span for LLM interaction"""
        if not trace:
            return None

        try:
            messages = body.get("messages", [])
            model = body.get("model", "unknown")
            
            # Extract input content
            input_content = self._extract_input_content(messages)
            
            # Count input tokens (approximate)
            input_tokens = self._estimate_tokens(input_content) if self.valves.track_input_tokens else None
            
            generation = trace.generation(
                name=f"LLM_Generation_{model}",
                model=model,
                input=input_content,
                metadata={
                    "model_parameters": self._extract_model_parameters(body),
                    "message_count": len(messages),
                    "user_id": self._get_user_id(user)
                },
                usage={
                    "input": input_tokens
                } if input_tokens else None
            )
            
            return generation

        except Exception as e:
            logger.error(f"Error creating generation: {e}")
            return None

    async def _update_generation(self, conversation_id: str, body: dict):
        """Update generation with response data"""
        if conversation_id not in self.active_traces:
            return

        try:
            trace_data = self.active_traces[conversation_id]
            generation = trace_data.get("generation")
            start_time = trace_data.get("start_time", time.time())
            
            if not generation:
                return

            # Extract response content
            output_content = self._extract_output_content(body)
            
            # Calculate metrics
            end_time = time.time()
            response_time = end_time - start_time
            
            # Count output tokens
            output_tokens = self._estimate_tokens(output_content) if self.valves.track_output_tokens else None
            input_tokens = generation.input_usage.get("input", 0) if hasattr(generation, 'input_usage') else 0
            
            # Calculate cost
            cost = self._calculate_cost(input_tokens, output_tokens) if self.valves.enable_cost_tracking else None
            
            # Update generation
            generation.end(
                output=output_content,
                usage={
                    "input": input_tokens,
                    "output": output_tokens,
                    "total": (input_tokens or 0) + (output_tokens or 0)
                } if self.valves.track_input_tokens or self.valves.track_output_tokens else None,
                metadata={
                    "response_time_ms": response_time * 1000,
                    "cost_usd": cost,
                    "timestamp": datetime.now().isoformat()
                }
            )
            
            # Clean up
            del self.active_traces[conversation_id]
            if conversation_id in self.start_times:
                del self.start_times[conversation_id]

        except Exception as e:
            logger.error(f"Error updating generation: {e}")

    def _extract_input_content(self, messages: List[dict]) -> str:
        """Extract input content from messages"""
        if self.valves.exclude_system_messages:
            messages = [msg for msg in messages if msg.get("role") != "system"]
        
        content_parts = []
        for msg in messages:
            role = msg.get("role", "unknown")
            content = msg.get("content", "")
            content_parts.append(f"{role}: {content}")
        
        full_content = "\n".join(content_parts)
        
        # Truncate if too long
        if len(full_content) > self.valves.max_content_length:
            full_content = full_content[:self.valves.max_content_length] + "..."
        
        return full_content

    def _extract_output_content(self, body: dict) -> str:
        """Extract output content from response"""
        # Handle different response formats
        if "choices" in body:
            # OpenAI format
            choices = body["choices"]
            if choices and "message" in choices[0]:
                content = choices[0]["message"].get("content", "")
            else:
                content = str(body)
        else:
            # Other formats
            content = str(body)
        
        # Truncate if too long
        if len(content) > self.valves.max_content_length:
            content = content[:self.valves.max_content_length] + "..."
        
        return content

    def _extract_model_parameters(self, body: dict) -> dict:
        """Extract model parameters from request"""
        if not self.valves.track_model_parameters:
            return {}
        
        params = {}
        param_keys = ["temperature", "top_p", "max_tokens", "frequency_penalty", "presence_penalty"]
        
        for key in param_keys:
            if key in body:
                params[key] = body[key]
        
        return params

    def _estimate_tokens(self, text: str) -> int:
        """Estimate token count (rough approximation)"""
        # Very rough estimation: ~4 characters per token
        return len(text) // 4

    def _calculate_cost(self, input_tokens: Optional[int], output_tokens: Optional[int]) -> Optional[float]:
        """Calculate estimated cost"""
        if not input_tokens and not output_tokens:
            return None
        
        cost = 0.0
        if input_tokens:
            cost += input_tokens * self.valves.cost_per_input_token
        if output_tokens:
            cost += output_tokens * self.valves.cost_per_output_token
        
        return round(cost, 6)
