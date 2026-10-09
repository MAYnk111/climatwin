"""Deterministic demo graph data for CLIMATWIN.
Labeled clearly as demo data, with realistic supply-chain and climate-hazard relationships.
"""

from app.graph.engine import DependencyGraphEngine
from app.graph.models import GraphNode, GraphEdge, NodeType, RiskLevel, EdgeType


def build_demo_graph() -> DependencyGraphEngine:
    """Builds a deterministic demo supply chain and climate hazard dependency graph."""
    engine = DependencyGraphEngine()

    nodes = [
        # Climate Hazards
        GraphNode(
            id="hz_taiwan_drought",
            label="Central Taiwan Extreme Drought",
            type=NodeType.CLIMATE_HAZARD,
            risk_level=RiskLevel.CRITICAL,
            risk_score=92.0,
            location="Taichung / Hsinchu, Taiwan",
            properties={"hazard_type": "Drought", "is_demo": True, "confidence": 0.88},
        ),
        GraphNode(
            id="hz_rhine_low_water",
            label="Rhine River Low Water Event",
            type=NodeType.CLIMATE_HAZARD,
            risk_level=RiskLevel.HIGH,
            risk_score=78.0,
            location="Rhineland, Germany",
            properties={"hazard_type": "Low River Flow", "is_demo": True, "confidence": 0.82},
        ),
        # Geographic Regions
        GraphNode(
            id="reg_hsinchu",
            label="Hsinchu Science Park",
            type=NodeType.GEOGRAPHIC_REGION,
            risk_level=RiskLevel.HIGH,
            risk_score=85.0,
            location="Hsinchu, Taiwan",
            properties={"is_demo": True},
        ),
        GraphNode(
            id="reg_rhine_valley",
            label="Upper Rhine Valley",
            type=NodeType.GEOGRAPHIC_REGION,
            risk_level=RiskLevel.HIGH,
            risk_score=75.0,
            location="Germany",
            properties={"is_demo": True},
        ),
        # Facilities
        GraphNode(
            id="fac_fab12",
            label="Fab 12 Semiconductor Fab",
            type=NodeType.FACILITY,
            risk_level=RiskLevel.CRITICAL,
            risk_score=90.0,
            location="Hsinchu, Taiwan",
            properties={"water_intensity_m3_day": 45000, "is_demo": True},
        ),
        GraphNode(
            id="fac_basf_ludwigshafen",
            label="Ludwigshafen Chemical Complex",
            type=NodeType.FACILITY,
            risk_level=RiskLevel.HIGH,
            risk_score=72.0,
            location="Ludwigshafen, Germany",
            properties={"barge_dependency_pct": 65, "is_demo": True},
        ),
        # Transport Routes & Commodities
        GraphNode(
            id="tr_rhine_barge",
            label="Rhine Freight Barge Corridor",
            type=NodeType.TRANSPORT_ROUTE,
            risk_level=RiskLevel.HIGH,
            risk_score=76.0,
            location="Rotterdam-Basel",
            properties={"is_demo": True},
        ),
        GraphNode(
            id="comm_ultrapure_water",
            label="Ultra-Pure Water & Silicon Wafers",
            type=NodeType.COMMODITY,
            risk_level=RiskLevel.CRITICAL,
            risk_score=88.0,
            properties={"is_demo": True},
        ),
        # Suppliers
        GraphNode(
            id="sup_tsmc",
            label="TSMC (Contract Foundry)",
            type=NodeType.SUPPLIER,
            risk_level=RiskLevel.HIGH,
            risk_score=84.0,
            sector="Semiconductors",
            location="Taiwan",
            properties={"tier": 1, "is_demo": True},
        ),
        GraphNode(
            id="sup_basf",
            label="BASF SE (Specialty Chemicals)",
            type=NodeType.SUPPLIER,
            risk_level=RiskLevel.MEDIUM,
            risk_score=64.0,
            sector="Materials & Chemicals",
            location="Germany",
            properties={"tier": 1, "is_demo": True},
        ),
        # Portfolio Holdings / Companies
        GraphNode(
            id="comp_apple",
            label="Apple Inc. (AAPL)",
            type=NodeType.COMPANY,
            risk_level=RiskLevel.MEDIUM,
            risk_score=62.0,
            sector="Technology Hardware",
            location="Cupertino, USA",
            properties={"portfolio_weight": 0.12, "is_demo": True},
        ),
        GraphNode(
            id="comp_nvidia",
            label="NVIDIA Corp (NVDA)",
            type=NodeType.COMPANY,
            risk_level=RiskLevel.HIGH,
            risk_score=79.0,
            sector="Semiconductors & AI",
            location="Santa Clara, USA",
            properties={"portfolio_weight": 0.09, "is_demo": True},
        ),
        GraphNode(
            id="comp_bmw",
            label="BMW Group (BMW.DE)",
            type=NodeType.COMPANY,
            risk_level=RiskLevel.MEDIUM,
            risk_score=58.0,
            sector="Automotive",
            location="Munich, Germany",
            properties={"portfolio_weight": 0.05, "is_demo": True},
        ),
        # Customers / Portfolio
        GraphNode(
            id="cust_global_tech_fund",
            label="Global Climate-Resilient Tech Portfolio",
            type=NodeType.CUSTOMER,
            risk_level=RiskLevel.MEDIUM,
            risk_score=68.5,
            properties={"aum_usd_millions": 250.0, "is_demo": True},
        ),
    ]

    for n in nodes:
        engine.add_node(n)

    edges = [
        # Taiwan drought impact chain
        GraphEdge(
            id="e_hz_to_reg_hsinchu",
            source="hz_taiwan_drought",
            target="reg_hsinchu",
            relationship=EdgeType.EXPOSED_TO,
            label="covers region",
            weight=0.95,
        ),
        GraphEdge(
            id="e_reg_to_fac12",
            source="reg_hsinchu",
            target="fac_fab12",
            relationship=EdgeType.LOCATED_IN,
            label="houses fab facility",
            weight=0.9,
        ),
        GraphEdge(
            id="e_fac12_to_comm",
            source="fac_fab12",
            target="comm_ultrapure_water",
            relationship=EdgeType.PRODUCES,
            label="requires water for wafers",
            weight=0.88,
        ),
        GraphEdge(
            id="e_fac12_to_tsmc",
            source="fac_fab12",
            target="sup_tsmc",
            relationship=EdgeType.OWNS,
            label="primary production asset",
            weight=0.9,
        ),
        GraphEdge(
            id="e_tsmc_to_nvda",
            source="sup_tsmc",
            target="comp_nvidia",
            relationship=EdgeType.SUPPLIES_TO,
            label="exclusive GPU foundry (Tier 1)",
            weight=0.92,
        ),
        GraphEdge(
            id="e_tsmc_to_aapl",
            source="sup_tsmc",
            target="comp_apple",
            relationship=EdgeType.SUPPLIES_TO,
            label="A-series / M-series foundry (Tier 1)",
            weight=0.85,
        ),
        # Rhine low water impact chain
        GraphEdge(
            id="e_hz_to_reg_rhine",
            source="hz_rhine_low_water",
            target="reg_rhine_valley",
            relationship=EdgeType.EXPOSED_TO,
            label="affects watershed",
            weight=0.8,
        ),
        GraphEdge(
            id="e_reg_to_tr_barge",
            source="reg_rhine_valley",
            target="tr_rhine_barge",
            relationship=EdgeType.LOCATED_IN,
            label="restricts waterway draft",
            weight=0.85,
        ),
        GraphEdge(
            id="e_barge_to_basf",
            source="tr_rhine_barge",
            target="fac_basf_ludwigshafen",
            relationship=EdgeType.TRANSPORTS,
            label="raw material deliveries",
            weight=0.75,
        ),
        GraphEdge(
            id="e_fac_to_basf_company",
            source="fac_basf_ludwigshafen",
            target="sup_basf",
            relationship=EdgeType.OWNS,
            label="flagship chemical site",
            weight=0.8,
        ),
        GraphEdge(
            id="e_basf_to_bmw",
            source="sup_basf",
            target="comp_bmw",
            relationship=EdgeType.SUPPLIES_TO,
            label="coatings & polymers supply",
            weight=0.65,
        ),
        # Portfolio exposure
        GraphEdge(
            id="e_nvda_to_port",
            source="comp_nvidia",
            target="cust_global_tech_fund",
            relationship=EdgeType.DEPENDS_ON,
            label="9% holding weight",
            weight=0.9,
        ),
        GraphEdge(
            id="e_aapl_to_port",
            source="comp_apple",
            target="cust_global_tech_fund",
            relationship=EdgeType.DEPENDS_ON,
            label="12% holding weight",
            weight=0.85,
        ),
        GraphEdge(
            id="e_bmw_to_port",
            source="comp_bmw",
            target="cust_global_tech_fund",
            relationship=EdgeType.DEPENDS_ON,
            label="5% holding weight",
            weight=0.5,
        ),
    ]

    for e in edges:
        engine.add_edge(e)

    # Pre-calculate deterministic layout coordinates
    engine.calculate_deterministic_layout()
    return engine
