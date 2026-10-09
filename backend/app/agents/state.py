from typing import Annotated, Dict, List, Optional, Any
from pydantic import BaseModel, Field
import operator


class EvidenceItem(BaseModel):
    id: str
    source_name: str
    source_url: Optional[str] = None
    title: str
    snippet: str
    timestamp: str
    reliability_score: float = 0.9


class RiskInvestigationState(BaseModel):
    """Investigation state managed by LangGraph."""
    investigation_id: str
    portfolio_id: str
    hazard_event_id: str
    hazard_title: str
    hazard_description: str
    evidence_items: Annotated[List[EvidenceItem], operator.add] = Field(default_factory=list)
    impacted_holdings: Annotated[List[Dict[str, Any]], operator.add] = Field(default_factory=list)
    graph_propagation_paths: List[List[str]] = Field(default_factory=list)
    risk_summary: Optional[str] = None
    estimated_portfolio_impact_pct: Optional[float] = None
    mitigation_recommendations: Annotated[List[Dict[str, Any]], operator.add] = Field(default_factory=list)
    status: str = "initialized"
    trace_id: Optional[str] = None
