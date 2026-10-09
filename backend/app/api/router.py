from fastapi import APIRouter, Query
from typing import List, Optional
from app.graph.demo_data import build_demo_graph
from app.graph.models import DependencyGraphResponse, PropagationPath, EdgeType, RiskLevel
from app.agents.state import RiskInvestigationState
from app.agents.workflow import build_investigation_workflow
from app.simulations.models import (
    HoldingBaseline,
    ScenarioParameter,
    ScenarioSimulationResult,
)
from app.simulations.engine import ClimateScenarioSimulationEngine

api_router = APIRouter(prefix="/v1")
_demo_graph = build_demo_graph()


@api_router.get("/health")
def health_check():
    return {
        "status": "healthy",
        "service": "CLIMATWIN Intelligence Engine",
        "version": "1.0.0-alpha",
        "graph_nodes_loaded": len(_demo_graph.node_metadata),
    }


@api_router.get("/graph", response_model=DependencyGraphResponse)
def get_dependency_graph(
    relationship_types: Optional[List[EdgeType]] = Query(None),
    min_risk_level: Optional[RiskLevel] = Query(None),
    max_depth: Optional[int] = Query(None),
    center_node_id: Optional[str] = Query(None),
):
    """Returns the dependency graph with deterministic coordinates and filters."""
    return _demo_graph.filter_subgraph(
        relationship_types=relationship_types,
        min_risk_level=min_risk_level,
        max_depth=max_depth,
        center_node_id=center_node_id,
    )


@api_router.get("/graph/propagation", response_model=List[PropagationPath])
def get_propagation_paths(
    hazard_id: str = "hz_taiwan_drought",
    target_id: str = "comp_nvidia",
):
    """Calculates NetworkX propagation paths from hazard to company or portfolio."""
    return _demo_graph.find_hazard_propagation_paths(hazard_id=hazard_id, target_id=target_id)


from pydantic import BaseModel
from typing import Any, Dict


class InvestigationRequest(BaseModel):
    investigation_id: str = "inv_001"
    portfolio_id: str = "cust_global_tech_fund"
    hazard_event_id: str = "hz_taiwan_drought"
    target_id: Optional[str] = None
    hazard_title: Optional[str] = "Central Taiwan Extreme Drought"
    hazard_description: Optional[str] = "Severe drought impacting Baoshan reservoir and semiconductor fabrication clusters."
    graph_context: Optional[Dict[str, Any]] = None


@api_router.post("/intelligence/investigate", response_model=RiskInvestigationState)
def run_investigation(
    payload: Optional[InvestigationRequest] = None,
):
    """Executes the LangGraph AI risk investigation workflow."""
    req = payload or InvestigationRequest()
    workflow = build_investigation_workflow()
    
    # Calculate propagation paths dynamically if target_id is present
    dynamic_paths = []
    if req.target_id:
        paths = _demo_graph.find_hazard_propagation_paths(
            hazard_id=req.hazard_event_id,
            target_id=req.target_id,
        )
        if paths:
            dynamic_paths = [p.path_nodes for p in paths]

    initial_state = RiskInvestigationState(
        investigation_id=req.investigation_id,
        portfolio_id=req.portfolio_id,
        hazard_event_id=req.hazard_event_id,
        hazard_title=req.hazard_title or "Central Taiwan Extreme Drought",
        hazard_description=req.hazard_description or "Severe drought impacting Baoshan reservoir.",
        graph_propagation_paths=dynamic_paths,
    )
    result = workflow.invoke(initial_state.model_dump())
    
    # If dynamic paths were calculated for this target, preserve them in response
    if dynamic_paths:
        result["graph_propagation_paths"] = dynamic_paths
        
    return RiskInvestigationState(**result)


class SimulationRequestBody(BaseModel):
    scenario_id: str = "scen_q4_water_stress"
    scenario_name: str = "Q4 Taiwan Severe Drought & Packaging Bottleneck"
    severity_multiplier: float = 1.8
    duration_months: int = 4
    adaptation_mitigation_active: bool = True
    alternative_supplier_available: bool = True
    target_holding_tickers: Optional[List[str]] = None
    baseline_holdings: Optional[List[HoldingBaseline]] = None


@api_router.post("/simulations/run", response_model=ScenarioSimulationResult)
def run_simulation(
    payload: Optional[SimulationRequestBody] = None,
):
    """Runs baseline-versus-stressed portfolio stress test and branch comparison."""
    req = payload or SimulationRequestBody()
    default_holdings = [
        HoldingBaseline(
            ticker="AAPL",
            name="Apple Inc.",
            weight=0.12,
            current_value_usd=30_000_000.0,
            beta_to_hazard=1.1,
        ),
        HoldingBaseline(
            ticker="NVDA",
            name="NVIDIA Corp",
            weight=0.09,
            current_value_usd=22_500_000.0,
            beta_to_hazard=1.6,
        ),
        HoldingBaseline(
            ticker="BMW.DE",
            name="BMW Group",
            weight=0.05,
            current_value_usd=12_500_000.0,
            beta_to_hazard=0.8,
        ),
    ]
    holdings = req.baseline_holdings or default_holdings
    if req.target_holding_tickers:
        selected_tickers = set(req.target_holding_tickers)
        filtered = [h for h in holdings if h.ticker in selected_tickers]
        if filtered:
            holdings = filtered

    params = ScenarioParameter(
        hazard_severity_multiplier=req.severity_multiplier,
        duration_months=req.duration_months,
        adaptation_mitigation_active=req.adaptation_mitigation_active,
        alternative_supplier_available=req.alternative_supplier_available,
    )
    return ClimateScenarioSimulationEngine.run_stress_test(
        scenario_id=req.scenario_id,
        scenario_name=req.scenario_name,
        holdings=holdings,
        params=params,
    )

