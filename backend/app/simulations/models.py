from typing import Dict, List, Optional
from pydantic import BaseModel, Field


class HoldingBaseline(BaseModel):
    ticker: str
    name: str
    weight: float
    current_value_usd: float
    beta_to_hazard: float = 1.0


class ScenarioParameter(BaseModel):
    hazard_severity_multiplier: float = 1.5  # e.g., 1.5x severity
    duration_months: int = 3
    adaptation_mitigation_active: bool = False
    alternative_supplier_available: bool = False


class HoldingStressedResult(BaseModel):
    ticker: str
    name: str
    baseline_value_usd: float
    stressed_value_usd: float
    loss_usd: float
    drawdown_pct: float
    mitigation_savings_usd: float = 0.0


class ScenarioSimulationResult(BaseModel):
    scenario_id: str
    scenario_name: str
    baseline_total_aum: float
    stressed_total_aum: float
    net_portfolio_loss_usd: float
    portfolio_drawdown_pct: float
    stressed_holdings: List[HoldingStressedResult]
    branch_comparison: Dict[str, float] = Field(default_factory=dict)
    is_modelled_data: bool = True


class SimulationRequest(BaseModel):
    scenario_id: str = "scen_q4_water_stress"
    scenario_name: str = "Q4 Taiwan Severe Drought & Packaging Bottleneck"
    severity_multiplier: float = 1.8
    duration_months: int = 4
    adaptation_mitigation_active: bool = True
    alternative_supplier_available: bool = True
    target_holding_tickers: Optional[List[str]] = None
    baseline_holdings: Optional[List[HoldingBaseline]] = None
