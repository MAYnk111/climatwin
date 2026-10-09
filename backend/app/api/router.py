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


@api_router.post("/intelligence/investigate", response_model=RiskInvestigationState)
def run_investigation(
    investigation_id: str = "inv_001",
    portfolio_id: str = "cust_global_tech_fund",
    hazard_event_id: str = "hz_taiwan_drought",
    hazard_title: str = "Central Taiwan Extreme Drought",
    hazard_description: str = "Severe drought impacting Baoshan reservoir and semiconductor fabrication clusters.",
):
    """Executes the LangGraph AI risk investigation workflow."""
    workflow = build_investigation_workflow()
    initial_state = RiskInvestigationState(
        investigation_id=investigation_id,
        portfolio_id=portfolio_id,
        hazard_event_id=hazard_event_id,
        hazard_title=hazard_title,
        hazard_description=hazard_description,
    )
    result = workflow.invoke(initial_state.model_dump())
    return RiskInvestigationState(**result)


@api_router.post("/simulations/run", response_model=ScenarioSimulationResult)
def run_simulation(
    scenario_id: str = "scen_q4_water_stress",
    scenario_name: str = "Q4 Taiwan Severe Drought & Packaging Bottleneck",
    severity_multiplier: float = 1.8,
    duration_months: int = 4,
    adaptation_mitigation_active: bool = True,
    alternative_supplier_available: bool = True,
):
    """Runs baseline-versus-stressed portfolio stress test and branch comparison."""
    sample_holdings = [
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
    params = ScenarioParameter(
        hazard_severity_multiplier=severity_multiplier,
        duration_months=duration_months,
        adaptation_mitigation_active=adaptation_mitigation_active,
        alternative_supplier_available=alternative_supplier_available,
    )
    return ClimateScenarioSimulationEngine.run_stress_test(
        scenario_id=scenario_id,
        scenario_name=scenario_name,
        holdings=sample_holdings,
        params=params,
    )
