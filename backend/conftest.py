"""Global pytest configuration for CLIMATWIN backend test suite.

Enforces:
- Mode 1: Offline testing by default (zero external Gemini API calls).
- Disables live Gemini calls unless RUN_LIVE_GEMINI_TESTS=1 is explicitly passed.
- Resets LLM metrics and in-memory caches before tests.
"""

import os
import pytest
from app.core.llm_service import llm_metrics, set_mock_model_override


@pytest.fixture(autouse=True)
def configure_test_mode(monkeypatch):
    """Ensures ordinary pytest runs do not make live external Gemini network calls."""
    # Reset LLM metrics for isolation
    llm_metrics.reset_for_tests()
    set_mock_model_override(None)

    # Unless RUN_LIVE_GEMINI_TESTS=1 is explicitly set, enforce offline test mode
    if os.getenv("RUN_LIVE_GEMINI_TESTS") != "1":
        monkeypatch.setenv("CLIMATWIN_OFFLINE_TEST", "1")
    yield
    set_mock_model_override(None)
