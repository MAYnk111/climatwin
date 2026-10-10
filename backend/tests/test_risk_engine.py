import pytest
from app.graph.demo_data import build_demo_graph
from app.simulations.risk_engine import PhysicalRiskEngine, RiskCalculationResult


def test_deterministic_hev_risk_calculation():
    """Verifies that Hazard-Exposure-Vulnerability calculations are purely deterministic in Python."""
    engine = PhysicalRiskEngine()

    result = engine.calculate_entity_risk(
        hazard_id="hz_taiwan_drought",
        hazard_title="Central Taiwan Extreme Drought",
        target_node_id="comp_nvidia",
        portfolio_aum_usd=250_000_000.0,
        has_secondary_supplier=False,
        has_onsite_mitigation=False,
    )

    assert isinstance(result, RiskCalculationResult)
    assert result.hazard_score > 0 and result.hazard_score <= 100
    assert result.exposure_score > 0 and result.exposure_score <= 100
    assert result.vulnerability_score > 0 and result.vulnerability_score <= 100
    assert result.composite_risk_score > 0 and result.composite_risk_score <= 100

    # Holding weight and value check
    assert result.target_ticker == "NVDA"
    assert result.baseline_value_usd == round(250_000_000.0 * result.holding_weight, 2)
    assert result.unmitigated_loss_usd > 0
    assert result.unmitigated_drawdown_pct > 0

    # Evidence items must be present with attribution
    assert len(result.evidence_items) >= 2
    for ev in result.evidence_items:
        assert ev.source_name is not None
        assert ev.source_url.startswith("http")
        assert ev.reliability > 0.9


def test_mitigation_preserves_capital():
    """Verifies that applying dual-sourcing and adaptation buffers strictly reduces loss and preserves capital."""
    engine = PhysicalRiskEngine()

    unmitigated = engine.calculate_entity_risk(
        hazard_id="hz_taiwan_drought",
        hazard_title="Central Taiwan Extreme Drought",
        target_node_id="comp_nvidia",
        has_secondary_supplier=False,
        has_onsite_mitigation=False,
    )

    mitigated = engine.calculate_entity_risk(
        hazard_id="hz_taiwan_drought",
        hazard_title="Central Taiwan Extreme Drought",
        target_node_id="comp_nvidia",
        has_secondary_supplier=True,
        has_onsite_mitigation=True,
    )

    # Mitigated loss must be strictly lower than unmitigated loss
    assert mitigated.mitigated_loss_usd < unmitigated.unmitigated_loss_usd
    assert mitigated.capital_preserved_usd > 0
    assert mitigated.capital_preserved_usd == round(
        mitigated.unmitigated_loss_usd - mitigated.mitigated_loss_usd, 2
    )
    assert mitigated.vulnerability_score < unmitigated.vulnerability_score


def test_transparency_assumptions_and_provisional_weights():
    """Verifies that the risk calculation transparently reports assumptions and provisional weights."""
    engine = PhysicalRiskEngine()
    result = engine.calculate_entity_risk(
        hazard_id="hz_rhine_low_water",
        hazard_title="Rhine Low Water",
        target_node_id="comp_bmw",
    )

    # Weights must sum to 1.0
    total_weight = sum(result.weights_used.values())
    assert abs(total_weight - 1.0) < 0.001
    assert "provisional engineering weights" in result.assumptions[0]
    assert "Uncertainty range" in result.confidence_limitations


def test_gemini_synthesis_does_not_override_python_numbers():
    """Verifies that Gemini synthesis attaches text without changing deterministic Python scores."""
    engine = PhysicalRiskEngine()
    result = engine.calculate_entity_risk(
        hazard_id="hz_taiwan_drought",
        hazard_title="Central Taiwan Extreme Drought",
        target_node_id="comp_nvidia",
    )

    orig_composite = result.composite_risk_score
    orig_loss = result.unmitigated_loss_usd

    synthesized = engine.synthesize_risk_with_gemini(result)
    assert synthesized.composite_risk_score == orig_composite
    assert synthesized.unmitigated_loss_usd == orig_loss
    assert synthesized.executive_synthesis is not None
    assert len(synthesized.executive_synthesis) > 20
