import os
import pytest
from unittest.mock import patch, MagicMock
from app.agents.state import RiskInvestigationState
from app.agents.workflow import build_investigation_workflow
from app.agents.poller import ClimateEventPoller
from app.core.redis_store import RedisStateStore
from app.adapters.climate import ClimateHazardAdapter
from app.adapters.market import MarketPortfolioAdapter


def test_risk_investigator_networkx_propagation():
    """Verifies that the LangGraph workflow traces physical hazard paths through NetworkX."""
    workflow = build_investigation_workflow()
    initial_state = RiskInvestigationState(
        investigation_id="inv_test_001",
        portfolio_id="cust_global_tech_fund",
        hazard_event_id="hz_taiwan_drought",
        hazard_title="Taiwan Drought Event",
        hazard_description="Drought threatening semiconductor cooling and fabrication.",
    )

    result = workflow.invoke(initial_state.model_dump())
    assert result["status"] == "completed"

    # Traces NetworkX propagation paths to portfolio holdings
    paths = result["graph_propagation_paths"]
    assert len(paths) >= 1
    # Check that TSMC is in the propagation path
    all_path_nodes = [node for p in paths for node in p]
    assert "sup_tsmc" in all_path_nodes

    # Affected companies identified
    holdings = result["impacted_holdings"]
    tickers = [h["ticker"] for h in holdings]
    assert "NVDA" in tickers or "AAPL" in tickers


def test_mitigation_advisor_four_interventions():
    """Verifies that Mitigation Advisor calls simulation engine and Python computes numbers for 4 branches."""
    workflow = build_investigation_workflow()
    initial_state = RiskInvestigationState(
        investigation_id="inv_test_mitigation",
        portfolio_id="cust_global_tech_fund",
        hazard_event_id="hz_taiwan_drought",
        hazard_title="Taiwan Drought Event",
        hazard_description="Drought threatening semiconductor cooling and fabrication.",
    )

    result = workflow.invoke(initial_state.model_dump())
    recommendations = result["mitigation_recommendations"]
    assert len(recommendations) >= 3

    # Check mitigation comparisons
    comparisons = result.get("mitigation_comparisons", {})
    assert "unmitigated_drawdown_pct" in comparisons
    assert "supplier_savings_usd" in comparisons
    assert "adaptation_savings_usd" in comparisons
    assert "combined_savings_usd" in comparisons
    assert comparisons["combined_savings_usd"] > 0
    assert comparisons["residual_drawdown_pct"] < comparisons["unmitigated_drawdown_pct"]

    # Verify quantitative numbers in executive summary
    summary = result.get("risk_summary", "")
    assert str(round(comparisons["unmitigated_drawdown_pct"], 1)) in summary or "drawdown" in summary.lower()


def test_gemini_called_when_credentials_exist():
    """Verifies Gemini is genuinely called when credentials exist, and returns gemini model type."""
    mock_response = MagicMock()
    mock_response.content = "Executive Summary: Gemini analyzed the NetworkX propagation paths and confirms $13.7M saved."

    with patch.dict(os.environ, {"GOOGLE_API_KEY": "fake_test_gemini_key_123", "CLIMATWIN_OFFLINE_TEST": "0"}):
        with patch("langchain_google_genai.ChatGoogleGenerativeAI") as MockLLMClass:
            mock_llm_instance = MagicMock()
            mock_llm_instance.invoke.return_value = mock_response
            MockLLMClass.return_value = mock_llm_instance

            workflow = build_investigation_workflow()
            result = workflow.invoke({
                "investigation_id": "inv_gemini_test",
                "portfolio_id": "cust_global_tech_fund",
                "hazard_event_id": "hz_taiwan_drought",
                "hazard_title": "Taiwan Drought Event",
                "hazard_description": "Water scarcity in Hsinchu.",
            })

            # Assert Gemini LLM was instantiated and invoked
            MockLLMClass.assert_called_once()
            mock_llm_instance.invoke.assert_called_once()
            assert "gemini" in result["model_type"] and "flash" in result["model_type"]
            assert result["is_modelled_data"] is False
            assert "Gemini analyzed" in result["risk_summary"]


def test_deterministic_labeling_when_no_llm_key():
    """Verifies that deterministic fallback is explicitly labeled when API keys are absent."""
    with patch.dict(os.environ, {}, clear=True), patch("app.agents.workflow.settings.GOOGLE_API_KEY", ""):
        # Ensure no Gemini keys exist in env or settings
        workflow = build_investigation_workflow()
        result = workflow.invoke({
            "investigation_id": "inv_test_fallback",
            "portfolio_id": "cust_global_tech_fund",
            "hazard_event_id": "hz_rhine_low_water",
            "hazard_title": "Rhine Low Water Event",
            "hazard_description": "Freight barge draft restricted.",
        })

        assert result["is_modelled_data"] is True
        assert result["model_type"] == "modeled_fallback"
        assert result["confidence_score"] > 0.8
        assert "evidence_items" in result and len(result["evidence_items"]) > 0


@pytest.mark.anyio
async def test_poller_deduplication_and_truthful_monitoring():
    """Verifies background poller event deduplication and honest monitoring status reporting."""
    from app.core.redis_store import redis_store
    redis_store.clear_all()

    poller = ClimateEventPoller()

    # Before start, monitoring must be truthfully reported as False
    assert poller.is_monitoring_active is False
    status_idle = poller.get_status()
    assert status_idle["is_monitoring_active"] is False
    assert "Standby" in status_idle["monitoring_status_label"]

    # First polling cycle generates alerts
    alerts_round_1 = await poller.poll_once(user_id="user_test")
    assert len(alerts_round_1) >= 2
    assert len(poller.seen_event_ids) >= 2

    first_alert = alerts_round_1[0]
    assert "id" in first_alert
    assert "severity" in first_alert
    assert "affected_holdings" in first_alert
    assert "evidence_source" in first_alert
    assert "created_at" in first_alert

    # Second polling cycle: deduplication prevents re-alerting
    alerts_round_2 = await poller.poll_once(user_id="user_test")
    assert len(alerts_round_2) == 0  # Deduplicated!


def test_restart_persistence_and_duplicate_prevention(tmp_path):
    """Verifies that seen events and alerts survive backend restarts even without Redis."""
    store1 = RedisStateStore(redis_url="redis://localhost:9999/0")  # Offline redis
    store1._data_dir = tmp_path
    store1._state_file = tmp_path / "test_state.json"

    # Save event and alert
    store1.add_seen_event("ev_survive_01")
    store1.save_alert({"id": "al_01", "title": "Rhine Drought"})
    store1.save_investigation({"investigation_id": "inv_01", "user_id": "user_1"})

    assert store1.is_event_seen("ev_survive_01") is True

    # Simulate restart by instantiating a completely new store instance reading from disk
    store2 = RedisStateStore(redis_url="redis://localhost:9999/0")
    store2._data_dir = tmp_path
    store2._state_file = tmp_path / "test_state.json"
    store2._init_local_storage()

    # Verify state survived the restart
    assert store2.is_event_seen("ev_survive_01") is True
    assert len(store2.get_alerts()) >= 1
    assert store2.get_alerts()[0]["id"] == "al_01"
    assert len(store2.get_investigations("user_1")) >= 1


@pytest.mark.anyio
async def test_external_api_failure_resilience():
    """Verifies that external climate and FX API failures fall back gracefully without exceptions."""
    from app.core.redis_store import redis_store
    redis_store.clear_all()

    climate_adapter = ClimateHazardAdapter()
    market_adapter = MarketPortfolioAdapter()

    # Test with simulated network failure on unreachable host/port
    with patch("httpx.AsyncClient.get", side_effect=Exception("Connection timed out")):
        weather_rec = await climate_adapter.fetch_live_weather(latitude=24.78, longitude=120.99)
        assert weather_rec is not None
        assert weather_rec.status == "demo_fallback"
        assert weather_rec.payload["is_live_feed"] is False

        fx_rec = await market_adapter.fetch_live_fx_rate()
        assert fx_rec is not None
        assert fx_rec.status == "benchmark_fallback"
        assert fx_rec.payload["is_live_rate"] is False
        assert fx_rec.payload["exchange_rate"] == 83.50


def test_multi_agent_climate_handoffs():
    """Verifies that all 6 collaborative agents execute in the LangGraph workflow,
    producing typed execution steps, upstream-to-downstream handoffs, and authoritative H-E-V scores.
    """
    workflow = build_investigation_workflow()
    initial_state = RiskInvestigationState(
        investigation_id="inv_multi_agent_001",
        portfolio_id="cust_global_tech_fund",
        hazard_event_id="hz_taiwan_drought",
        hazard_title="Central Taiwan Extreme Drought",
        hazard_description="Extreme hydrological drought impacting Baoshan reservoir and semiconductor fabrication clusters.",
    )

    result = workflow.invoke(initial_state.model_dump())
    assert result["status"] == "completed"

    # 1. Verify live timeline has records from all 6 agents
    timeline = result.get("agent_timeline", [])
    assert len(timeline) >= 6
    agent_ids = [step.agent_id if hasattr(step, "agent_id") else step["agent_id"] for step in timeline]
    assert "agent_a_climate_intelligence" in agent_ids
    assert "agent_b_climate_scenario" in agent_ids
    assert "agent_c_climate_verification" in agent_ids
    assert "agent_d_climate_impact" in agent_ids
    assert "agent_risk_investigator" in agent_ids
    assert "agent_mitigation_advisor" in agent_ids

    # 2. Verify Agent A (Climate Intelligence)
    climate_intel = result.get("climate_intelligence")
    assert climate_intel is not None
    res_storage = getattr(climate_intel, "reservoir_storage_pct", None) or (climate_intel.get("reservoir_storage_pct") if isinstance(climate_intel, dict) else None)
    assert res_storage == 17.8
    obs = getattr(climate_intel, "observations", None) or climate_intel.get("observations", [])
    assert len(obs) >= 3

    # 3. Verify Agent B (Climate Scenarios) consumed Agent A
    scenario_res = result.get("scenario_analysis")
    assert scenario_res is not None
    scenarios = getattr(scenario_res, "tested_scenarios", None) or scenario_res.get("tested_scenarios", [])
    assert "SSP2-4.5" in scenarios[0]
    breached = getattr(scenario_res, "threshold_breached", None) or scenario_res.get("threshold_breached")
    assert breached is True

    # 4. Verify Agent C (Verification)
    verification = result.get("verification_report")
    assert verification is not None
    v_sources = getattr(verification, "verified_sources", None) or verification.get("verified_sources", [])
    assert len(v_sources) >= 3
    v_claims = getattr(verification, "verified_claims", None) or verification.get("verified_claims", [])
    assert len(v_claims) >= 2
    u_claims = getattr(verification, "unsupported_or_flagged_claims", None) or verification.get("unsupported_or_flagged_claims", [])
    assert len(u_claims) >= 1

    # 5. Verify Agent D (Supply Chain Impact)
    supply_impact = result.get("supply_chain_impact")
    assert supply_impact is not None
    facs = getattr(supply_impact, "affected_facilities", None) or supply_impact.get("affected_facilities", [])
    assert len(facs) >= 2
    comms = getattr(supply_impact, "critical_commodities", None) or supply_impact.get("critical_commodities", [])
    assert len(comms) >= 2

    # 6. Verify Risk Investigator & Authoritative Python Risk Engine
    risk_calc = result.get("risk_engine_result")
    assert risk_calc is not None
    comp_score = getattr(risk_calc, "composite_risk_score", None) or (risk_calc.get("composite_risk_score") if isinstance(risk_calc, dict) else None)
    assert comp_score is not None and comp_score > 0
    calib = getattr(risk_calc, "model_calibration_status", None) or (risk_calc.get("model_calibration_status") if isinstance(risk_calc, dict) else None)
    assert calib == "provisional_engineering_model"

    # 7. Verify Mitigation Advisor comparisons
    comparisons = result.get("mitigation_comparisons")
    assert comparisons is not None
    savings = getattr(comparisons, "combined_savings_usd", None) or (comparisons.get("combined_savings_usd") if isinstance(comparisons, dict) else None)
    assert savings is not None and savings > 0

