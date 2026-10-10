"""Deterministic demo graph data for CLIMATWIN.
Labeled clearly as demo data, with realistic supply-chain and climate-hazard relationships.
"""

from typing import Optional
from app.graph.engine import DependencyGraphEngine
from app.graph.models import GraphNode, GraphEdge, NodeType, RiskLevel, EdgeType


def build_demo_graph(
    include_sectivia: bool = False, max_sectivia_nodes: Optional[int] = None
) -> DependencyGraphEngine:
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
            properties={
                "hazard_type": "Drought",
                "is_demo": True,
                "is_scenario": True,
                "confidence": 0.88,
                "provenance": "synthetic_scenario_hazard",
                "data_source": "World Bank CCKP CMIP6 & Taiwan WRA",
                "source_url": "https://wra.gov.tw/bulletins",
            },
        ),
        GraphNode(
            id="hz_rhine_low_water",
            label="Rhine River Low Water Event",
            type=NodeType.CLIMATE_HAZARD,
            risk_level=RiskLevel.HIGH,
            risk_score=78.0,
            location="Rhineland, Germany",
            properties={
                "hazard_type": "Low River Flow",
                "is_demo": True,
                "is_scenario": True,
                "confidence": 0.82,
                "provenance": "synthetic_scenario_hazard",
                "data_source": "German Federal Waterways & Shipping Administration (WSV)",
                "source_url": "https://elwis.de/wsv-kaub",
            },
        ),
        # Geographic Regions
        GraphNode(
            id="reg_hsinchu",
            label="Hsinchu Science Park",
            type=NodeType.GEOGRAPHIC_REGION,
            risk_level=RiskLevel.HIGH,
            risk_score=85.0,
            location="Hsinchu, Taiwan",
            properties={
                "is_demo": True,
                "provenance": "verified_physical_region",
                "data_source": "Hsinchu Science Park Bureau",
                "source_url": "https://sipa.gov.tw",
            },
        ),
        GraphNode(
            id="reg_rhine_valley",
            label="Upper Rhine Valley",
            type=NodeType.GEOGRAPHIC_REGION,
            risk_level=RiskLevel.HIGH,
            risk_score=75.0,
            location="Germany",
            properties={
                "is_demo": True,
                "provenance": "verified_physical_region",
                "data_source": "Federal Republic of Germany Geographic Registry",
            },
        ),
        # Physical Facilities & Logistics Hubs
        GraphNode(
            id="fac_fab12",
            label="Fab 12 Semiconductor Fab",
            type=NodeType.FACILITY,
            risk_level=RiskLevel.CRITICAL,
            risk_score=90.0,
            location="Hsinchu, Taiwan",
            properties={
                "water_intensity_m3_day": 45000,
                "is_demo": True,
                "facility_type": "300mm Advanced Silicon Wafer Fab",
                "provenance": "verified_physical_facility",
                "data_source": "TSMC Corporate Sustainability Report",
                "source_url": "https://esg.tsmc.com",
            },
        ),
        GraphNode(
            id="fac_basf_ludwigshafen",
            label="Ludwigshafen Chemical Complex",
            type=NodeType.FACILITY,
            risk_level=RiskLevel.HIGH,
            risk_score=72.0,
            location="Ludwigshafen, Germany",
            properties={
                "barge_dependency_pct": 65,
                "is_demo": True,
                "facility_type": "Integrated Petrochemical Verbund Site",
                "provenance": "verified_physical_facility",
                "data_source": "BASF SE Corporate Registry",
                "source_url": "https://basf.com/global/en/who-we-are/organization/locations/europe/germany/ludwigshafen.html",
            },
        ),
        GraphNode(
            id="hub_kaohsiung_port",
            label="Port of Kaohsiung Logistics Hub",
            type=NodeType.FACILITY,
            risk_level=RiskLevel.HIGH,
            risk_score=74.0,
            location="Kaohsiung, Taiwan",
            properties={
                "is_demo": True,
                "facility_type": "Deep-Water Container & Bulk Liquid Chemical Terminal",
                "provenance": "verified_physical_facility",
                "data_source": "Taiwan International Ports Corporation (TIPC)",
                "source_url": "https://kh.twport.com.tw",
            },
        ),
        GraphNode(
            id="hub_rotterdam_port",
            label="Port of Rotterdam Chemical Gateway",
            type=NodeType.FACILITY,
            risk_level=RiskLevel.HIGH,
            risk_score=70.0,
            location="Rotterdam, Netherlands",
            properties={
                "is_demo": True,
                "facility_type": "Inland Barge & Deep-Sea Transshipment Gateway",
                "provenance": "verified_physical_facility",
                "data_source": "Port of Rotterdam Authority",
                "source_url": "https://portofrotterdam.com",
            },
        ),
        # Transport Routes & Commodities
        GraphNode(
            id="tr_rhine_barge",
            label="Rhine Freight Barge Corridor",
            type=NodeType.TRANSPORT_ROUTE,
            risk_level=RiskLevel.HIGH,
            risk_score=76.0,
            location="Rotterdam-Basel",
            properties={
                "is_demo": True,
                "corridor_type": "Inland Waterway Navigation",
                "provenance": "verified_transport_corridor",
                "data_source": "Central Commission for the Navigation of the Rhine (CCNR)",
                "source_url": "https://ccr-zkr.org",
            },
        ),
        GraphNode(
            id="tr_taiwan_strait_shipping",
            label="Taiwan Strait Feeder Shipping Corridor",
            type=NodeType.TRANSPORT_ROUTE,
            risk_level=RiskLevel.HIGH,
            risk_score=71.0,
            location="Taiwan Strait (Kaohsiung-Taichung)",
            properties={
                "is_demo": True,
                "corridor_type": "Coastal Container Feeder Route",
                "provenance": "verified_transport_corridor",
                "data_source": "UNCTAD Review of Maritime Transport",
                "source_url": "https://unctad.org/topic/transport-and-trade-logistics",
            },
        ),
        GraphNode(
            id="comm_ultrapure_water",
            label="Ultra-Pure Water & Silicon Wafers",
            type=NodeType.COMMODITY,
            risk_level=RiskLevel.CRITICAL,
            risk_score=88.0,
            properties={
                "is_demo": True,
                "commodity_type": "Sub-Nanometer Electronic Process Input",
                "provenance": "sourced_industrial_commodity",
                "data_source": "Taiwan Water Resources Agency (WRA)",
                "source_url": "https://wra.gov.tw",
            },
        ),
        GraphNode(
            id="comm_neon_gas",
            label="High-Purity Neon & Specialty Gases",
            type=NodeType.COMMODITY,
            risk_level=RiskLevel.HIGH,
            risk_score=72.0,
            properties={
                "is_demo": True,
                "commodity_type": "DUV/EUV Lithography Laser Specialty Gas",
                "provenance": "sourced_industrial_commodity",
                "data_source": "USGS Mineral Commodity Summaries 2024",
                "source_url": "https://pubs.usgs.gov/periodicals/mcs2024/mcs2024-neon.pdf",
            },
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
            properties={
                "tier": 1,
                "is_demo": True,
                "provenance": "verified_sectivia",
                "data_source": "Sectivia Supply-Chain Graph (CC BY 4.0)",
                "source_url": "https://sectivia.com",
            },
        ),
        GraphNode(
            id="sup_basf",
            label="BASF SE (Specialty Chemicals)",
            type=NodeType.SUPPLIER,
            risk_level=RiskLevel.MEDIUM,
            risk_score=64.0,
            sector="Materials & Chemicals",
            location="Germany",
            properties={
                "tier": 1,
                "is_demo": True,
                "provenance": "verified_sectivia",
                "data_source": "Sectivia Supply-Chain Graph (CC BY 4.0)",
                "source_url": "https://sectivia.com",
            },
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
            properties={
                "portfolio_weight": 0.12,
                "is_demo": True,
                "provenance": "verified_sectivia",
                "data_source": "Sectivia Supply-Chain Graph (CC BY 4.0)",
                "source_url": "https://sectivia.com",
            },
        ),
        GraphNode(
            id="comp_nvidia",
            label="NVIDIA Corp (NVDA)",
            type=NodeType.COMPANY,
            risk_level=RiskLevel.HIGH,
            risk_score=79.0,
            sector="Semiconductors & AI",
            location="Santa Clara, USA",
            properties={
                "portfolio_weight": 0.09,
                "is_demo": True,
                "provenance": "verified_sectivia",
                "data_source": "Sectivia Supply-Chain Graph (CC BY 4.0)",
                "source_url": "https://sectivia.com",
            },
        ),
        GraphNode(
            id="comp_bmw",
            label="BMW Group (BMW.DE)",
            type=NodeType.COMPANY,
            risk_level=RiskLevel.MEDIUM,
            risk_score=58.0,
            sector="Automotive",
            location="Munich, Germany",
            properties={
                "portfolio_weight": 0.05,
                "is_demo": True,
                "provenance": "verified_sectivia",
                "data_source": "Sectivia Supply-Chain Graph (CC BY 4.0)",
                "source_url": "https://sectivia.com",
            },
        ),
        # Customers / Portfolio
        GraphNode(
            id="cust_global_tech_fund",
            label="Global Climate-Resilient Tech Portfolio",
            type=NodeType.CUSTOMER,
            risk_level=RiskLevel.MEDIUM,
            risk_score=68.5,
            properties={
                "aum_usd_millions": 250.0,
                "is_demo": True,
                "provenance": "portfolio_benchmark",
                "data_source": "CLIMATWIN Investment Holdings Benchmark",
            },
        ),
    ]

    for n in nodes:
        engine.add_node(n)

    edges = [
        # Taiwan drought multi-tier impact chains
        # Tier 0 -> Tier 1: Hazard to Region
        GraphEdge(
            id="e_hz_to_reg_hsinchu",
            source="hz_taiwan_drought",
            target="reg_hsinchu",
            relationship=EdgeType.EXPOSED_TO,
            label="regional drought basin",
            weight=0.95,
            properties={"provenance": "synthetic_scenario_hazard"},
        ),
        # Tier 1 -> Tier 1: Region to Facility & Logistics
        GraphEdge(
            id="e_reg_to_fac12",
            source="reg_hsinchu",
            target="fac_fab12",
            relationship=EdgeType.LOCATED_IN,
            label="houses fab facility",
            weight=0.90,
            properties={"provenance": "physical_infrastructure_dependency"},
        ),
        GraphEdge(
            id="e_reg_to_strait_shipping",
            source="reg_hsinchu",
            target="tr_taiwan_strait_shipping",
            relationship=EdgeType.LOCATED_IN,
            label="regional freight corridor",
            weight=0.82,
            properties={"provenance": "physical_infrastructure_dependency"},
        ),
        GraphEdge(
            id="e_strait_to_kaohsiung",
            source="tr_taiwan_strait_shipping",
            target="hub_kaohsiung_port",
            relationship=EdgeType.TRANSPORTS,
            label="coastal feeder logistics",
            weight=0.85,
            properties={"provenance": "verified_transport_corridor"},
        ),
        # Logistics Hub to Specialty Commodities
        GraphEdge(
            id="e_kaohsiung_to_neon",
            source="hub_kaohsiung_port",
            target="comm_neon_gas",
            relationship=EdgeType.TRANSPORTS,
            label="specialty gas import berths",
            weight=0.80,
            properties={"provenance": "sourced_industrial_commodity"},
        ),
        # Commodities to Facility
        GraphEdge(
            id="e_fac12_to_comm",
            source="fac_fab12",
            target="comm_ultrapure_water",
            relationship=EdgeType.PRODUCES,
            label="requires water for wafers",
            weight=0.88,
            properties={"provenance": "physical_infrastructure_dependency"},
        ),
        GraphEdge(
            id="e_neon_to_fac12",
            source="comm_neon_gas",
            target="fac_fab12",
            relationship=EdgeType.DEPENDS_ON,
            label="EUV lithography gas feed",
            weight=0.85,
            properties={"provenance": "sourced_industrial_commodity"},
        ),
        # Facility to Contract Foundry
        GraphEdge(
            id="e_fac12_to_tsmc",
            source="fac_fab12",
            target="sup_tsmc",
            relationship=EdgeType.OWNS,
            label="flagship fabrication asset",
            weight=0.90,
            properties={"provenance": "physical_infrastructure_dependency"},
        ),
        # Contract Foundry to Tier 1 OEM Holdings (Verified Sectivia)
        GraphEdge(
            id="e_tsmc_to_nvda",
            source="sup_tsmc",
            target="comp_nvidia",
            relationship=EdgeType.SUPPLIES_TO,
            label="exclusive GPU foundry (Tier 1)",
            weight=0.92,
            properties={
                "provenance": "verified_sectivia",
                "attribution": "Sectivia (https://sectivia.com), CC BY 4.0",
                "source_url": "https://sectivia.com",
            },
        ),
        GraphEdge(
            id="e_tsmc_to_aapl",
            source="sup_tsmc",
            target="comp_apple",
            relationship=EdgeType.SUPPLIES_TO,
            label="A/M-series foundry (Tier 1)",
            weight=0.85,
            properties={
                "provenance": "verified_sectivia",
                "attribution": "Sectivia (https://sectivia.com), CC BY 4.0",
                "source_url": "https://sectivia.com",
            },
        ),
        # Rhine low water multi-tier impact chain
        GraphEdge(
            id="e_hz_to_reg_rhine",
            source="hz_rhine_low_water",
            target="reg_rhine_valley",
            relationship=EdgeType.EXPOSED_TO,
            label="affects Rhine basin",
            weight=0.80,
            properties={"provenance": "synthetic_scenario_hazard"},
        ),
        GraphEdge(
            id="e_reg_to_tr_barge",
            source="reg_rhine_valley",
            target="tr_rhine_barge",
            relationship=EdgeType.LOCATED_IN,
            label="restricts waterway draft",
            weight=0.85,
            properties={"provenance": "physical_infrastructure_dependency"},
        ),
        GraphEdge(
            id="e_rotterdam_to_barge",
            source="hub_rotterdam_port",
            target="tr_rhine_barge",
            relationship=EdgeType.TRANSPORTS,
            label="feedstock barge transshipment",
            weight=0.88,
            properties={"provenance": "verified_transport_corridor"},
        ),
        GraphEdge(
            id="e_barge_to_basf",
            source="tr_rhine_barge",
            target="fac_basf_ludwigshafen",
            relationship=EdgeType.TRANSPORTS,
            label="chemical feedstock deliveries",
            weight=0.75,
            properties={"provenance": "physical_infrastructure_dependency"},
        ),
        GraphEdge(
            id="e_fac_to_basf_company",
            source="fac_basf_ludwigshafen",
            target="sup_basf",
            relationship=EdgeType.OWNS,
            label="flagship chemical Verbund site",
            weight=0.80,
            properties={"provenance": "physical_infrastructure_dependency"},
        ),
        GraphEdge(
            id="e_basf_to_bmw",
            source="sup_basf",
            target="comp_bmw",
            relationship=EdgeType.SUPPLIES_TO,
            label="coatings & polymers supply (Tier 1)",
            weight=0.65,
            properties={
                "provenance": "verified_sectivia",
                "attribution": "Sectivia (https://sectivia.com), CC BY 4.0",
                "source_url": "https://sectivia.com",
            },
        ),
        # Portfolio exposure
        GraphEdge(
            id="e_nvda_to_port",
            source="comp_nvidia",
            target="cust_global_tech_fund",
            relationship=EdgeType.DEPENDS_ON,
            label="9% portfolio weight",
            weight=0.90,
            properties={"provenance": "portfolio_weight_allocation"},
        ),
        GraphEdge(
            id="e_aapl_to_port",
            source="comp_apple",
            target="cust_global_tech_fund",
            relationship=EdgeType.DEPENDS_ON,
            label="12% portfolio weight",
            weight=0.85,
            properties={"provenance": "portfolio_weight_allocation"},
        ),
        GraphEdge(
            id="e_bmw_to_port",
            source="comp_bmw",
            target="cust_global_tech_fund",
            relationship=EdgeType.DEPENDS_ON,
            label="5% portfolio weight",
            weight=0.50,
            properties={"provenance": "portfolio_weight_allocation"},
        ),
    ]

    for e in edges:
        engine.add_edge(e)

    if include_sectivia:
        try:
            from app.graph.sectivia_loader import SectiviaSupplyChainLoader
            loader = SectiviaSupplyChainLoader()
            loader.reconcile_with_graph(engine, max_nodes=max_sectivia_nodes)
        except Exception as err:
            import logging
            logging.getLogger("climatwin.demo_data").warning(f"Could not load Sectivia data: {err}")

    # Pre-calculate deterministic layout coordinates
    engine.calculate_deterministic_layout()
    return engine
