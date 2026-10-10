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


class AgentExecutionStep(BaseModel):
    """Execution step record for the live backend-driven multi-agent timeline."""
    agent_id: str
    agent_name: str
    role: str
    status: str = "completed"
    timestamp: str
    summary: str
    key_findings: List[str] = Field(default_factory=list)


class ClimateObservationMetric(BaseModel):
    """Empirical or projected climate metric collected by Agent A."""
    metric_name: str
    observed_value: Any
    unit: str
    historical_baseline: Optional[str] = None
    anomaly_indicator: Optional[str] = None
    source: str
    source_url: Optional[str] = None
    timestamp: str
    data_provenance: str = "observed_telemetry"


class ClimateIntelligencePayload(BaseModel):
    """Output from Agent A: Climate Intelligence Agent."""
    region: str
    hazard_type: str
    drought_stress_level: str
    observations: List[ClimateObservationMetric] = Field(default_factory=list)
    reservoir_storage_pct: Optional[float] = None
    precipitation_deficit_pct: Optional[float] = None
    spei12_drought_index: Optional[float] = None
    data_sources: List[str] = Field(default_factory=list)


class ScenarioAnalysisPayload(BaseModel):
    """Output from Agent B: Climate Analysis and Scenario Agent."""
    baseline_period: str = "1950-2014"
    tested_scenarios: List[str] = Field(default_factory=lambda: ["SSP2-4.5", "SSP5-8.5"])
    anomaly_delta: str
    projected_temperature_shift: str
    projected_precipitation_shift: str
    ensemble_percentiles: Dict[str, float] = Field(default_factory=dict)
    return_period_estimate: str
    threshold_breached: bool = True
    scenario_risk_classification: str = "critical"


class VerificationReportPayload(BaseModel):
    """Output from Agent C: Climate Research and Verification Agent."""
    verified_sources: List[str] = Field(default_factory=list)
    consensus_status: str = "high_consensus"
    verified_claims: List[str] = Field(default_factory=list)
    unsupported_or_flagged_claims: List[str] = Field(default_factory=list)
    telemetry_conflict_notes: Optional[str] = None
    confidence_level: float = 0.94


class SupplyChainImpactPayload(BaseModel):
    """Output from Agent D: Climate Impact and Adaptation Agent."""
    affected_facilities: List[Dict[str, Any]] = Field(default_factory=list)
    critical_commodities: List[str] = Field(default_factory=list)
    logistics_corridors: List[str] = Field(default_factory=list)
    physical_bottleneck_description: str
    adaptation_recommendations: List[str] = Field(default_factory=list)


class RiskInvestigationState(BaseModel):
    """Investigation state managed by LangGraph for CLIMATWIN multi-agent workflow."""
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
    uncertainty_range_pct: Optional[List[float]] = Field(default_factory=lambda: [-5.8, -3.1])
    confidence_score: float = 0.88
    is_modelled_data: bool = True
    mitigation_recommendations: Annotated[List[Dict[str, Any]], operator.add] = Field(default_factory=list)
    mitigation_comparisons: Optional[Dict[str, Any]] = None
    model_type: Optional[str] = "modeled_fallback"
    fallback_label: Optional[str] = "DETERMINISTIC FALLBACK"
    timestamp: Optional[str] = None
    status: str = "initialized"
    trace_id: Optional[str] = None

    # Multi-Agent Collaborative State Additions
    agent_timeline: Annotated[List[AgentExecutionStep], operator.add] = Field(default_factory=list)
    climate_intelligence: Optional[ClimateIntelligencePayload] = None
    scenario_analysis: Optional[ScenarioAnalysisPayload] = None
    verification_report: Optional[VerificationReportPayload] = None
    supply_chain_impact: Optional[SupplyChainImpactPayload] = None
    risk_engine_result: Optional[Dict[str, Any]] = None

