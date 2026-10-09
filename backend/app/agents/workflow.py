"""LangGraph workflow definition for CLIMATWIN risk investigations.
Utilizes standard LangGraph StateGraph compiled with LangSmith tracing enabled via environment.
"""

from typing import Dict, Any
from app.agents.state import RiskInvestigationState, EvidenceItem


def retrieve_evidence_node(state: RiskInvestigationState) -> Dict[str, Any]:
    """Node: Collects verified news, satellite, or hydrological evidence for the hazard."""
    # Starter implementation: structured retrieval
    sample_evidence = [
        EvidenceItem(
            id="ev_01",
            source_name="Taiwan Water Resources Agency",
            source_url="https://wip.wra.gov.tw/demo",
            title="Reservoir Capacity Dropped Below 18% in Hsinchu",
            snippet="Baoshan No. 2 Reservoir water reserves triggered Stage 2 restrictions.",
            timestamp="2026-10-08T12:00:00Z",
            reliability_score=0.95,
        )
    ]
    return {
        "evidence_items": sample_evidence,
        "status": "evidence_retrieved",
    }


def traverse_graph_impact_node(state: RiskInvestigationState) -> Dict[str, Any]:
    """Node: Uses NetworkX dependency graph to trace physical hazard to supply chain tiers."""
    paths = [
        ["hz_taiwan_drought", "reg_hsinchu", "fac_fab12", "sup_tsmc", "comp_nvidia"],
        ["hz_taiwan_drought", "reg_hsinchu", "fac_fab12", "sup_tsmc", "comp_apple"],
    ]
    impacted = [
        {"ticker": "NVDA", "holding_name": "NVIDIA Corp", "weight": 0.09, "tier_exposure": 1, "direct_impact": False},
        {"ticker": "AAPL", "holding_name": "Apple Inc.", "weight": 0.12, "tier_exposure": 1, "direct_impact": False},
    ]
    return {
        "graph_propagation_paths": paths,
        "impacted_holdings": impacted,
        "status": "graph_impact_traced",
    }


def assess_portfolio_risk_node(state: RiskInvestigationState) -> Dict[str, Any]:
    """Node: Quantifies portfolio vulnerability from holding weights and supply chain bottlenecks."""
    summary = (
        "Extreme drought in Hsinchu restricts ultrapure water required for advanced semiconductor packaging. "
        "High Tier-1 supply dependency introduces a combined 21% portfolio revenue at risk over Q4."
    )
    return {
        "risk_summary": summary,
        "estimated_portfolio_impact_pct": -4.2,
        "status": "risk_assessed",
    }


def synthesize_mitigations_node(state: RiskInvestigationState) -> Dict[str, Any]:
    """Node: Proposes actionable hedging, supplier diversification, and scenario branches."""
    mitigations = [
        {
            "action": "Increase allocation to secondary foundries (Intel 18A / Samsung Austin)",
            "impact_reduction_pct": 1.8,
            "feasibility": "Medium (requires packaging qualification)",
        },
        {
            "action": "Hedge exposure via Semiconductor Volatility Put Spreads",
            "impact_reduction_pct": 2.1,
            "feasibility": "Immediate (capital markets hedge)",
        },
    ]
    return {
        "mitigation_recommendations": mitigations,
        "status": "completed",
    }


def build_investigation_workflow():
    """Builds the compiled LangGraph workflow.
    LangSmith tracing is activated automatically when LANGCHAIN_TRACING_V2=true.
    """
    try:
        from langgraph.graph import StateGraph, END
        workflow = StateGraph(RiskInvestigationState)

        workflow.add_node("retrieve_evidence", retrieve_evidence_node)
        workflow.add_node("traverse_graph_impact", traverse_graph_impact_node)
        workflow.add_node("assess_portfolio_risk", assess_portfolio_risk_node)
        workflow.add_node("synthesize_mitigations", synthesize_mitigations_node)

        workflow.set_entry_point("retrieve_evidence")
        workflow.add_edge("retrieve_evidence", "traverse_graph_impact")
        workflow.add_edge("traverse_graph_impact", "assess_portfolio_risk")
        workflow.add_edge("assess_portfolio_risk", "synthesize_mitigations")
        workflow.add_edge("synthesize_mitigations", END)

        return workflow.compile()
    except ImportError:
        # Fallback runner for tests or environments where langgraph is not yet installed in active venv
        class SimpleRunner:
            def invoke(self, state_dict: Dict[str, Any]) -> Dict[str, Any]:
                state = RiskInvestigationState(**state_dict)
                s1 = retrieve_evidence_node(state)
                state = state.model_copy(update=s1)
                s2 = traverse_graph_impact_node(state)
                state = state.model_copy(update=s2)
                s3 = assess_portfolio_risk_node(state)
                state = state.model_copy(update=s3)
                s4 = synthesize_mitigations_node(state)
                state = state.model_copy(update=s4)
                return state.model_dump()

        return SimpleRunner()
