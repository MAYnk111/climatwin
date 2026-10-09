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
