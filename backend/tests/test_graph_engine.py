from app.graph.demo_data import build_demo_graph
from app.graph.models import NodeType, RiskLevel


def test_demo_graph_initialization():
    engine = build_demo_graph()
    assert len(engine.node_metadata) > 0
    assert len(engine.edge_metadata) > 0

    # Ensure typed nodes are present
    hazard_nodes = [
        n for n in engine.node_metadata.values() if n.type == NodeType.CLIMATE_HAZARD
    ]
    assert len(hazard_nodes) >= 2


def test_deterministic_layout_coordinates():
    engine = build_demo_graph()
    positions = engine.calculate_deterministic_layout(width=1000, height=800)

    for node_id, (x, y) in positions.items():
        assert x > 0 and x < 1000
        assert y > 0 and y < 800

    # Taiwan drought hazard (tier 0) should have smaller x than TSMC (tier 2) and Apple (tier 3)
    hz_x, _ = positions["hz_taiwan_drought"]
    tsmc_x, _ = positions["sup_tsmc"]
    aapl_x, _ = positions["comp_apple"]
    assert hz_x < tsmc_x < aapl_x


def test_propagation_path_calculation():
    engine = build_demo_graph()
    paths = engine.find_hazard_propagation_paths(
        hazard_id="hz_taiwan_drought",
        target_id="comp_nvidia",
    )
    assert len(paths) >= 1
    primary_path = paths[0]
    assert primary_path.hazard_id == "hz_taiwan_drought"
    assert primary_path.target_id == "comp_nvidia"
    assert "sup_tsmc" in primary_path.path_nodes
    assert primary_path.cumulative_risk > 0


def test_graph_filtering():
    engine = build_demo_graph()
    critical_subgraph = engine.filter_subgraph(min_risk_level=RiskLevel.CRITICAL)
    for node in critical_subgraph.nodes:
        assert node.risk_level == RiskLevel.CRITICAL


def test_logistics_hubs_and_commodity_provenance():
    """Verifies that sourced logistics hubs, commodities, corridors, and provenance tags exist."""
    engine = build_demo_graph()
    node_ids = set(engine.node_metadata.keys())

    # Core nodes plus enriched hubs and commodities
    assert "hub_kaohsiung_port" in node_ids
    assert "hub_rotterdam_port" in node_ids
    assert "comm_neon_gas" in node_ids
    assert "tr_taiwan_strait_shipping" in node_ids

    # Provenance tags distinguish verified assets from synthetic scenarios
    kh_port = engine.node_metadata["hub_kaohsiung_port"]
    assert kh_port.properties.get("provenance") == "verified_physical_facility"
    assert "TIPC" in kh_port.properties.get("data_source", "")

    neon_comm = engine.node_metadata["comm_neon_gas"]
    assert neon_comm.properties.get("provenance") == "sourced_industrial_commodity"

    hazard = engine.node_metadata["hz_taiwan_drought"]
    assert hazard.properties.get("provenance") == "synthetic_scenario_hazard"
    assert hazard.properties.get("is_scenario") is True

    # Sectivia commercial links
    nvda_edge = engine.edge_metadata["e_tsmc_to_nvda"]
    assert nvda_edge.properties.get("provenance") == "verified_sectivia"
    assert "Sectivia" in nvda_edge.properties.get("attribution", "")


def test_multi_tier_2nd_and_3rd_order_propagation_to_portfolio():
    """Verifies multi-tier 2nd- and 3rd-order propagation paths through suppliers to portfolio holdings."""
    engine = build_demo_graph()

    # Taiwan drought -> Hsinchu -> Fab12 -> TSMC -> NVDA -> Fund (5 hops)
    tw_paths = engine.find_hazard_propagation_paths(
        hazard_id="hz_taiwan_drought",
        target_id="cust_global_tech_fund",
    )
    assert len(tw_paths) >= 2  # Through NVDA and AAPL
    nvda_path = next(p for p in tw_paths if "comp_nvidia" in p.path_nodes)
    assert len(nvda_path.path_nodes) == 6
    assert nvda_path.cumulative_risk > 0

    # Rhine low water -> Rhine Valley -> Rhine Barge -> BASF Ludwigshafen -> BASF SE -> BMW -> Fund (6 hops, 3rd order)
    rhine_paths = engine.find_hazard_propagation_paths(
        hazard_id="hz_rhine_low_water",
        target_id="cust_global_tech_fund",
    )
    assert len(rhine_paths) >= 1
    rhine_path = rhine_paths[0]
    assert len(rhine_path.path_nodes) == 7
    assert "tr_rhine_barge" in rhine_path.path_nodes
    assert "comp_bmw" in rhine_path.path_nodes
    assert rhine_path.cumulative_risk > 0
