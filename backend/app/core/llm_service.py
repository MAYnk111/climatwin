"""CLIMATWIN LLM Client Provider & Usage Tracking Architecture.

Provides:
- Token-efficient caching (Redis + durable local fallback)
- Circuit-breaker / cooldown for quota exhaustion (429 RESOURCE_EXHAUSTED)
- Configurable test modes:
    * Mode 1: Offline / Unit tests (default, zero external Gemini calls)
    * Mode 2: Mocked integration tests (injected fake model responses with call counters)
    * Mode 3: Live Gemini smoke test (opt-in only via RUN_LIVE_GEMINI_TESTS=1)
- Provider usage metadata tracking (call counts, tokens if available, cache hits/misses, fallback count)
- Factory for LangChain / ChatGoogleGenerativeAI or deterministic FakeChatModel
"""

import os
import time
import hashlib
import json
import logging
from typing import Dict, Any, Optional, List, Union
from datetime import datetime, timezone
from pydantic import BaseModel, Field

from app.core.config import settings
from app.core.redis_store import redis_store

logger = logging.getLogger("climatwin.llm_service")


class LLMUsageRecord(BaseModel):
    model_identifier: str
    prompt_tokens: Optional[int] = None
    completion_tokens: Optional[int] = None
    total_tokens: Optional[int] = None
    latency_ms: float = 0.0
    cache_hit: bool = False
    fallback_activated: bool = False
    error_category: Optional[str] = None
    timestamp: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())


class LLMMetricsCollector:
    """Singleton tracking provider-reported usage and invocation stats."""
    def __init__(self):
        self.total_invocations: int = 0
        self.cache_hits: int = 0
        self.cache_misses: int = 0
        self.fallback_activations: int = 0
        self.quota_exhaustions: int = 0
        self.history: List[LLMUsageRecord] = []
        self._circuit_breaker_until: float = 0.0

    def record(self, record: LLMUsageRecord):
        self.total_invocations += 1
        if record.cache_hit:
            self.cache_hits += 1
        else:
            self.cache_misses += 1
        if record.fallback_activated:
            self.fallback_activations += 1
        if record.error_category == "quota_exhausted":
            self.quota_exhaustions += 1
        self.history.append(record)

    def trigger_circuit_breaker(self, cooldown_seconds: int = 300):
        """Trips circuit breaker after 429 quota exhaustion to prevent repeated failing calls."""
        self._circuit_breaker_until = time.time() + cooldown_seconds
        logger.warning(f"Gemini circuit breaker tripped. External calls suspended for {cooldown_seconds}s.")

    @property
    def is_circuit_open(self) -> bool:
        return time.time() < self._circuit_breaker_until

    def reset_for_tests(self):
        self.total_invocations = 0
        self.cache_hits = 0
        self.cache_misses = 0
        self.fallback_activations = 0
        self.quota_exhaustions = 0
        self.history.clear()
        self._circuit_breaker_until = 0.0

    def get_summary(self) -> Dict[str, Any]:
        return {
            "total_invocations": self.total_invocations,
            "cache_hits": self.cache_hits,
            "cache_misses": self.cache_misses,
            "fallback_activations": self.fallback_activations,
            "quota_exhaustions": self.quota_exhaustions,
            "is_circuit_open": self.is_circuit_open,
        }


llm_metrics = LLMMetricsCollector()


class FakeChatModel:
    """Deterministic fake language model for Mode 1 & Mode 2 testing without real API keys."""

    def __init__(
        self,
        canned_response: str = "Executive Summary: Multi-agent synthesis confirms supply chain bottleneck and capital preservation.",
        simulate_error: Optional[str] = None,
        model_name: str = "mock-gemini-flash",
    ):
        self.canned_response = canned_response
        self.simulate_error = simulate_error
        self.model_name = model_name
        self.call_count: int = 0
        self.last_prompt: Optional[str] = None

    def invoke(self, prompt: Any) -> Any:
        self.call_count += 1
        self.last_prompt = str(prompt)

        if self.simulate_error == "quota_exhausted":
            raise Exception("429 RESOURCE_EXHAUSTED: Quota exceeded for mock model")
        elif self.simulate_error == "timeout":
            raise TimeoutError("Mock connection timed out")
        elif self.simulate_error == "malformed":
            return type("MockResp", (), {"content": ""})()

        return type("MockResp", (), {"content": self.canned_response})()


# Global mock override for testing
_mock_override_model: Optional[FakeChatModel] = None


def set_mock_model_override(fake_model: Optional[FakeChatModel]):
    """Injects a fake model for test suites."""
    global _mock_override_model
    _mock_override_model = fake_model


def get_mock_model_override() -> Optional[FakeChatModel]:
    return _mock_override_model


def compute_llm_cache_key(model_name: str, prompt: str, version: str = "v1") -> str:
    """Computes a stable SHA-256 hash for caching prompt responses."""
    h = hashlib.sha256(f"{model_name}:{version}:{prompt.strip()}".encode("utf-8")).hexdigest()
    return f"llm_synth:{h}"


def get_cached_llm_response(cache_key: str) -> Optional[Dict[str, Any]]:
    """Retrieves cached response from Redis / durable local store."""
    try:
        cached = redis_store.cache_get(cache_key)
        if cached and isinstance(cached, dict) and "risk_summary" in cached:
            return cached
    except Exception as e:
        logger.debug(f"LLM cache lookup notice: {e}")
    return None


def set_cached_llm_response(cache_key: str, data: Dict[str, Any], ttl_seconds: int = 1800):
    """Caches successful model synthesis for 30 minutes."""
    try:
        redis_store.cache_set(cache_key, data, ttl_seconds=ttl_seconds)
    except Exception as e:
        logger.debug(f"LLM cache set notice: {e}")
