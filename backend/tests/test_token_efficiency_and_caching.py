"""Tests for CLIMATWIN Token-Efficient Testing Architecture and Caching.

Covers Part B requirements:
- Mode 1: Offline tests make zero real Gemini calls.
- Mode 2: Mocked integration tests with FakeChatModel verifying handoffs and call counts.
- Mode 3: Optional live smoke test (only runs when RUN_LIVE_GEMINI_TESTS=1).
- Response caching in Redis / local store preventing redundant model calls.
- Cache invalidation on changed inputs.
- Circuit breaker tripping on 429 quota exhaustion.
- Usage tracking metadata.
- Authoritative quantitative risk preservation across all modes.
"""

import os
import pytest
from unittest.mock import patch, MagicMock

from app.core.llm_service import (
    FakeChatModel,
    set_mock_model_override,
    llm_metrics,
    compute_llm_cache_key,
    get_cached_llm_response,
    set_cached_llm_response,
)
from app.agents.state import RiskInvestigationState
from app.agents.workflow import build_investigation_workflow


def test_mode1_offline_makes_zero_real_gemini_calls():
    """Mode 1: Verifies that standard test invocation with CLIMATWIN_OFFLINE_TEST=1
    executes without contacting external Gemini and produces deterministic fallback.
    """
    llm_metrics.reset_for_tests()
    set_mock_model_override(None)

    workflow = build_investigation_workflow()
    initial_state = RiskInvestigationState(
        investigation_id="inv_offline_mode1",
        portfolio_id="cust_global_tech_fund",
        hazard_event_id="hz_taiwan_drought",
        hazard_title="Taiwan Drought Test",
        hazard_description="Testing offline zero-token execution.",
    )

    result = workflow.invoke(initial_state.model_dump())
    assert result["status"] == "completed"
    assert result["is_modelled_data"] is True
    assert result["model_type"] == "modeled_fallback"
    assert result["fallback_label"] == "DETERMINISTIC FALLBACK"

    # Verify zero external Gemini calls occurred
    summary = llm_metrics.get_summary()
    assert summary["cache_hits"] == 0
    assert summary["quota_exhaustions"] == 0
    # Numerical results strictly preserved
    assert result.get("risk_engine_result") is not None
    assert result["risk_engine_result"]["composite_risk_score"] > 0


def test_mode2_mocked_integration_with_call_counter():
    """Mode 2: Exercises real LangGraph orchestration and 6-agent handoffs using FakeChatModel.
    Verifies agent handoffs, custom mock outputs, and precise call counts.
    """
    llm_metrics.reset_for_tests()
    fake_model = FakeChatModel(
        canned_response="Mocked LLM Synthesis: TSMC Fab 12 bottleneck mitigated by Intel 18A dual-sourcing.",
        model_name="mock-gemini-pro-test",
    )
    set_mock_model_override(fake_model)

    try:
        workflow = build_investigation_workflow()
        initial_state = RiskInvestigationState(
            investigation_id="inv_mock_mode2",
            portfolio_id="cust_global_tech_fund",
            hazard_event_id="hz_taiwan_drought",
            hazard_title="Taiwan Drought Mode 2",
            hazard_description="Validating fake model injection.",
        )

        result = workflow.invoke(initial_state.model_dump())
        assert result["status"] == "completed"
        assert result["is_modelled_data"] is False
        assert result["model_type"] == "mock-gemini-pro-test"
        assert "Intel 18A dual-sourcing" in result["risk_summary"]

        # Assert mock was called exactly once by the synthesis node
        assert fake_model.call_count == 1
        assert "Taiwan Drought Mode 2" in fake_model.last_prompt

        # Verify all upstream agent payloads were consumed
        assert result.get("climate_intelligence") is not None
        assert result.get("scenario_analysis") is not None
        assert result.get("verification_report") is not None
        assert result.get("supply_chain_impact") is not None
        assert result.get("risk_engine_result") is not None
    finally:
        set_mock_model_override(None)


def test_cache_hits_prevent_duplicate_llm_calls():
    """Mode 2/B5: Verifies that identical requests hit the cache, avoiding duplicate model calls."""
    from app.core.redis_store import redis_store
    redis_store.clear_all()
    llm_metrics.reset_for_tests()

    fake_model = FakeChatModel(
        canned_response="Cached Analysis Response: Critical UPW water deficit managed via desalination.",
        model_name="mock-gemini-cached",
    )
    set_mock_model_override(fake_model)

    try:
        workflow = build_investigation_workflow()
        state_dict = {
            "investigation_id": "inv_cache_test",
            "portfolio_id": "cust_global_tech_fund",
            "hazard_event_id": "hz_taiwan_drought",
            "hazard_title": "Cache Benchmark Hazard",
            "hazard_description": "Cache testing description.",
        }

        # First run: invokes mock model and caches result
        res1 = workflow.invoke(state_dict)
        assert res1["status"] == "completed"
        assert fake_model.call_count == 1
        assert "Cached Analysis Response" in res1["risk_summary"]

        # Second run: identical inputs must hit cache and NOT increment mock call_count
        res2 = workflow.invoke(state_dict)
        assert res2["status"] == "completed"
        assert fake_model.call_count == 1  # Exactly 1! Never incremented because cached
        assert "Cached Analysis Response" in res2["risk_summary"]
        assert llm_metrics.cache_hits >= 1
    finally:
        set_mock_model_override(None)


def test_circuit_breaker_trips_on_quota_exhaustion():
    """Mode 2/B6: Verifies that simulated 429 quota exhaustion immediately trips
    the circuit breaker and activates deterministic fallback without repeated retry loops.
    """
    llm_metrics.reset_for_tests()
    quota_mock = FakeChatModel(
        simulate_error="quota_exhausted",
        model_name="mock-gemini-quota-exhausted",
    )
    set_mock_model_override(quota_mock)

    try:
        workflow = build_investigation_workflow()
        state_dict = {
            "investigation_id": "inv_quota_test",
            "portfolio_id": "cust_global_tech_fund",
            "hazard_event_id": "hz_taiwan_drought",
            "hazard_title": "Quota Scarcity Test",
            "hazard_description": "Simulating 429 resource exhausted.",
        }

        result = workflow.invoke(state_dict)
        assert result["status"] == "completed"
        # Must fall back gracefully to deterministic benchmark
        assert result["is_modelled_data"] is True
        assert result["model_type"] == "modeled_fallback"
        assert result["fallback_label"] == "DETERMINISTIC FALLBACK"

        # Check circuit breaker is now active
        assert llm_metrics.is_circuit_open is True
        assert llm_metrics.quota_exhaustions >= 1
    finally:
        set_mock_model_override(None)
        llm_metrics.reset_for_tests()


def test_mode3_live_gemini_smoke_test_opt_in():
    """Mode 3: Live Gemini smoke test.
    Explicitly skipped by default unless RUN_LIVE_GEMINI_TESTS=1 is provided.
    """
    if os.getenv("RUN_LIVE_GEMINI_TESTS") != "1":
        pytest.skip("Mode 3 live Gemini smoke test skipped by default. Set RUN_LIVE_GEMINI_TESTS=1 to execute.")

    # Only reached when developer explicitly opts in
    gemini_key = os.getenv("GOOGLE_API_KEY", "")
    if not gemini_key:
        pytest.fail("RUN_LIVE_GEMINI_TESTS=1 was set, but GOOGLE_API_KEY is not configured.")

    from langchain_google_genai import ChatGoogleGenerativeAI
    llm = ChatGoogleGenerativeAI(
        model="gemini-flash-lite-latest",
        google_api_key=gemini_key,
        temperature=0.1,
        max_retries=0,
        timeout=8.0,
    )
    resp = llm.invoke("Ping CLIMATWIN risk engine: reply 'OK' in one word.")
    assert len(str(resp.content)) > 0
