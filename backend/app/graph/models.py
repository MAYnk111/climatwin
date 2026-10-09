from enum import Enum
from typing import Dict, List, Optional, Any
from pydantic import BaseModel, Field


class NodeType(str, Enum):
    COMPANY = "company"
    SUPPLIER = "supplier"
    CUSTOMER = "customer"
    FACILITY = "facility"
    COMMODITY = "commodity"
    TRANSPORT_ROUTE = "transport_route"
    GEOGRAPHIC_REGION = "geographic_region"
    CLIMATE_HAZARD = "climate_hazard"


class RiskLevel(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class EdgeType(str, Enum):
    SUPPLIES_TO = "supplies_to"
    DEPENDS_ON = "depends_on"
    LOCATED_IN = "located_in"
    EXPOSED_TO = "exposed_to"
    TRANSPORTS = "transports"
    PRODUCES = "produces"
    OWNS = "owns"


class GraphNode(BaseModel):
    id: str
    label: str
    type: NodeType
    risk_level: RiskLevel = RiskLevel.LOW
    risk_score: float = Field(default=0.0, ge=0.0, le=100.0)
    sector: Optional[str] = None
    location: Optional[str] = None
    properties: Dict[str, Any] = Field(default_factory=dict)
    # Deterministic 2D coordinates for stable layout
    x: Optional[float] = None
    y: Optional[float] = None


class GraphEdge(BaseModel):
    id: str
    source: str
    target: str
    relationship: EdgeType
    label: str
    weight: float = 1.0
    properties: Dict[str, Any] = Field(default_factory=dict)


class PropagationPath(BaseModel):
    path_nodes: List[str]
    path_edges: List[str]
    hazard_id: str
    target_id: str
    cumulative_risk: float


class DependencyGraphResponse(BaseModel):
    nodes: List[GraphNode]
    edges: List[GraphEdge]
    propagation_paths: List[PropagationPath] = Field(default_factory=list)
    metadata: Dict[str, Any] = Field(default_factory=dict)
