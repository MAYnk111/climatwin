from typing import List, Dict
from app.simulations.models import (
    HoldingBaseline,
    ScenarioParameter,
    HoldingStressedResult,
    ScenarioSimulationResult,
)


class ClimateScenarioSimulationEngine:
    """Simulates portfolio stress tests and scenario branches using financial logic."""

    @staticmethod
    def run_stress_test(
        scenario_id: str,
        scenario_name: str,
        holdings: List[HoldingBaseline],
        params: ScenarioParameter,
    ) -> ScenarioSimulationResult:
        baseline_total = sum(h.current_value_usd for h in holdings)
        stressed_holdings: List[HoldingStressedResult] = []

        total_stressed_value = 0.0

        for h in holdings:
            # Base loss function driven by hazard multiplier and holding sensitivity
            raw_drawdown_pct = 0.05 * params.hazard_severity_multiplier * h.beta_to_hazard * (params.duration_months / 3.0)
            
            # Mitigation dampening
            mitigation_factor = 0.4 if params.adaptation_mitigation_active else 0.0
            if params.alternative_supplier_available:
                mitigation_factor += 0.3

            effective_drawdown_pct = max(0.0, min(1.0, raw_drawdown_pct * (1.0 - mitigation_factor)))
            unmitigated_drawdown_pct = max(0.0, min(1.0, raw_drawdown_pct))

            unmitigated_loss = h.current_value_usd * unmitigated_drawdown_pct
            mitigated_loss = h.current_value_usd * effective_drawdown_pct
            savings = unmitigated_loss - mitigated_loss

            stressed_value = h.current_value_usd - mitigated_loss
            total_stressed_value += stressed_value

            stressed_holdings.append(
                HoldingStressedResult(
                    ticker=h.ticker,
                    name=h.name,
                    baseline_value_usd=round(h.current_value_usd, 2),
                    stressed_value_usd=round(stressed_value, 2),
                    loss_usd=round(mitigated_loss, 2),
                    drawdown_pct=round(effective_drawdown_pct * 100, 2),
                    mitigation_savings_usd=round(savings, 2),
                )
            )

        net_loss = baseline_total - total_stressed_value
        portfolio_drawdown = (net_loss / baseline_total * 100) if baseline_total > 0 else 0.0

        # Scenario branch comparisons
        branches = {
            "unmitigated_drawdown_pct": round(portfolio_drawdown / (1.0 - mitigation_factor if (1.0 - mitigation_factor) > 0 else 1.0), 2) if params.adaptation_mitigation_active else round(portfolio_drawdown, 2),
            "current_simulated_drawdown_pct": round(portfolio_drawdown, 2),
        }

        return ScenarioSimulationResult(
            scenario_id=scenario_id,
            scenario_name=scenario_name,
            baseline_total_aum=round(baseline_total, 2),
            stressed_total_aum=round(total_stressed_value, 2),
            net_portfolio_loss_usd=round(net_loss, 2),
            portfolio_drawdown_pct=round(portfolio_drawdown, 2),
            stressed_holdings=stressed_holdings,
            branch_comparison=branches,
        )
