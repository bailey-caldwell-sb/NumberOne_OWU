"""
title: Perplexity Web Search Pipeline
author: NumberOne OWU Team
date: 2024-12-04
version: 1.0
license: MIT
description: A pipeline that integrates Perplexity's web search API for real-time information retrieval
requirements: pydantic, requests, openai
"""

from typing import List, Optional, Dict, Any
from pydantic import BaseModel
import json
import requests
import logging
import re
from datetime import datetime

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class Pipeline:
    class Valves(BaseModel):
        pipelines: List[str] = []
        priority: int = 0

        # Perplexity API Configuration
        perplexity_api_key: str = ""
        perplexity_base_url: str = "https://api.perplexity.ai"
        
        # Search Configuration
        enable_auto_search: bool = True  # Automatically decide when to search
        enable_manual_search: bool = True  # Allow manual search triggers
        search_trigger_keywords: List[str] = [
            "search", "find", "lookup", "what is", "who is", "when did", 
            "where is", "how to", "latest", "recent", "current", "news",
            "today", "yesterday", "this week", "this month", "2024", "2025"
        ]
        
        # Search Parameters
        search_model: str = "llama-3.1-sonar-large-128k-online"  # Perplexity search model
        max_tokens: int = 1000
        temperature: float = 0.2
        top_p: float = 0.9
        
        # Content Filtering
        search_domains: List[str] = []  # Empty = all domains
        exclude_domains: List[str] = ["reddit.com", "quora.com"]  # Domains to exclude
        max_search_results: int = 5
        
        # Response Configuration
        include_citations: bool = True
        citation_format: str = "markdown"  # "markdown" or "numbered"
        search_context_template: str = "Based on current web search results:\n\n{search_results}\n\nNow, please answer the user's question using this information:"

    def __init__(self):
        self.type = "filter"
        self.name = "Perplexity Search"
        self.valves = self.Valves(
            **{
                "pipelines": ["*"],  # Connect to all pipelines
            }
        )
        logger.info(f"Initialized {self.name} pipeline")

    async def on_startup(self):
        logger.info(f"on_startup:{__name__}")
        # Test API connection
        if self.valves.perplexity_api_key:
            try:
                await self._test_api_connection()
                logger.info("Perplexity API connection successful")
            except Exception as e:
                logger.warning(f"Perplexity API test failed: {e}")
        else:
            logger.warning("No Perplexity API key configured")

    async def on_shutdown(self):
        logger.info(f"on_shutdown:{__name__}")

    async def inlet(self, body: dict, user: Optional[dict] = None) -> dict:
        """Process incoming messages and add web search context if needed"""
        logger.info(f"Processing message through {__name__}")

        # Parse body if it's a string
        if isinstance(body, str):
            body = json.loads(body)

        all_messages = body.get("messages", [])
        if not all_messages:
            return body

        last_message = all_messages[-1].get("content", "")
        
        # Check if we should perform a web search
        should_search = await self._should_perform_search(last_message)
        
        if should_search and self.valves.perplexity_api_key:
            try:
                search_results = await self._perform_search(last_message)
                if search_results:
                    await self._add_search_context(all_messages, search_results)
                    logger.info("Added web search context to conversation")
            except Exception as e:
                logger.error(f"Search failed: {e}")

        return body

    async def _should_perform_search(self, message: str) -> bool:
        """Determine if a web search should be performed"""
        if not self.valves.enable_auto_search and not self.valves.enable_manual_search:
            return False

        message_lower = message.lower()

        # Check for manual search triggers
        if self.valves.enable_manual_search:
            manual_triggers = ["search:", "web:", "find:", "lookup:"]
            if any(trigger in message_lower for trigger in manual_triggers):
                return True

        # Check for automatic search triggers
        if self.valves.enable_auto_search:
            # Check for search keywords
            if any(keyword in message_lower for keyword in self.valves.search_trigger_keywords):
                return True
            
            # Check for question patterns that might benefit from search
            question_patterns = [
                r'\bwhat\s+is\b',
                r'\bwho\s+is\b',
                r'\bwhen\s+did\b',
                r'\bwhere\s+is\b',
                r'\bhow\s+to\b',
                r'\bwhy\s+does\b',
                r'\blatest\b',
                r'\brecent\b',
                r'\bcurrent\b',
                r'\bnews\b',
                r'\btoday\b',
                r'\b202[4-9]\b',  # Years 2024-2029
            ]
            
            if any(re.search(pattern, message_lower) for pattern in question_patterns):
                return True

        return False

    async def _perform_search(self, query: str) -> Optional[str]:
        """Perform web search using Perplexity API"""
        try:
            # Clean the query for search
            search_query = self._clean_search_query(query)
            
            headers = {
                "Authorization": f"Bearer {self.valves.perplexity_api_key}",
                "Content-Type": "application/json"
            }

            # Prepare search request
            search_data = {
                "model": self.valves.search_model,
                "messages": [
                    {
                        "role": "system",
                        "content": "You are a helpful assistant that provides accurate, up-to-date information from web search results. Include relevant citations."
                    },
                    {
                        "role": "user", 
                        "content": search_query
                    }
                ],
                "max_tokens": self.valves.max_tokens,
                "temperature": self.valves.temperature,
                "top_p": self.valves.top_p,
                "search_domain_filter": self.valves.search_domains if self.valves.search_domains else None,
                "return_citations": self.valves.include_citations,
                "search_recency_filter": "month"  # Focus on recent information
            }

            # Remove None values
            search_data = {k: v for k, v in search_data.items() if v is not None}

            # Make API request
            response = requests.post(
                f"{self.valves.perplexity_base_url}/chat/completions",
                headers=headers,
                json=search_data,
                timeout=30
            )

            if response.status_code == 200:
                result = response.json()
                content = result["choices"][0]["message"]["content"]
                
                # Extract citations if available
                citations = result.get("citations", [])
                
                # Format the response
                formatted_result = self._format_search_results(content, citations)
                
                logger.info(f"Search successful for query: {search_query[:50]}...")
                return formatted_result
            else:
                logger.error(f"Search API error: {response.status_code} - {response.text}")
                return None

        except Exception as e:
            logger.error(f"Search request failed: {e}")
            return None

    def _clean_search_query(self, query: str) -> str:
        """Clean and optimize the query for web search"""
        # Remove manual search triggers
        query = re.sub(r'^(search:|web:|find:|lookup:)\s*', '', query, flags=re.IGNORECASE)
        
        # Remove common conversational elements
        query = re.sub(r'^(can you|could you|please|help me)\s+', '', query, flags=re.IGNORECASE)
        
        # Limit query length
        if len(query) > 200:
            query = query[:200] + "..."
        
        return query.strip()

    def _format_search_results(self, content: str, citations: List[str]) -> str:
        """Format search results with citations"""
        formatted_result = content

        if self.valves.include_citations and citations:
            if self.valves.citation_format == "markdown":
                # Add citations as markdown links
                citations_text = "\n\n**Sources:**\n"
                for i, citation in enumerate(citations[:self.valves.max_search_results], 1):
                    citations_text += f"{i}. {citation}\n"
                formatted_result += citations_text
            elif self.valves.citation_format == "numbered":
                # Add numbered citations
                citations_text = "\n\nSources:\n"
                for i, citation in enumerate(citations[:self.valves.max_search_results], 1):
                    citations_text += f"[{i}] {citation}\n"
                formatted_result += citations_text

        return formatted_result

    async def _add_search_context(self, all_messages: list, search_results: str):
        """Add search results as context to the conversation"""
        search_context = self.valves.search_context_template.format(
            search_results=search_results
        )
        
        # Insert search context before the last user message
        all_messages.insert(-1, {
            "role": "system",
            "content": search_context
        })

    async def _test_api_connection(self):
        """Test the Perplexity API connection"""
        headers = {
            "Authorization": f"Bearer {self.valves.perplexity_api_key}",
            "Content-Type": "application/json"
        }

        test_data = {
            "model": self.valves.search_model,
            "messages": [{"role": "user", "content": "test"}],
            "max_tokens": 10
        }

        response = requests.post(
            f"{self.valves.perplexity_base_url}/chat/completions",
            headers=headers,
            json=test_data,
            timeout=10
        )

        if response.status_code != 200:
            raise Exception(f"API test failed: {response.status_code}")

    async def outlet(self, body: dict, user: Optional[dict] = None) -> dict:
        """Process outgoing responses (optional post-processing)"""
        return body
