from app.simulations.engine import ClimateScenarioSimulationEngine
from app.simulations.models import HoldingBaseline, ScenarioParameter


def test_simulation_stress_test_drawdown():
    holdings = [
        HoldingBaseline(
            ticker="AAPL",
            name="Apple Inc.",
            weight=0.12,
            current_value_usd=100_000.0,
            beta_to_hazard=1.0,
        ),
    ]
    # Unmitigated scenario
    params_unmitigated = ScenarioParameter(
        hazard_severity_multiplier=2.0,
        duration_months=3,
        adaptation_mitigation_active=False,
    )
    res_unmitigated = ClimateScenarioSimulationEngine.run_stress_test(
        scenario_id="s1",
        scenario_name="Drought Stress",
        holdings=holdings,
        params=params_unmitigated,
    )

    # Mitigated scenario
    params_mitigated = ScenarioParameter(
        hazard_severity_multiplier=2.0,
        duration_months=3,
        adaptation_mitigation_active=True,
        alternative_supplier_available=True,
    )
    res_mitigated = ClimateScenarioSimulationEngine.run_stress_test(
        scenario_id="s2",
        scenario_name="Drought Stress Mitigated",
        holdings=holdings,
        params=params_mitigated,
    )

    assert res_unmitigated.net_portfolio_loss_usd > res_mitigated.net_portfolio_loss_usd
    assert res_mitigated.stressed_holdings[0].mitigation_savings_usd > 0
