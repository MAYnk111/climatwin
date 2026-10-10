import pytest
from app.graph.demo_data import build_demo_graph
from app.graph.sectivia_loader import SectiviaSupplyChainLoader
from app.graph.models import EdgeType, RiskLevel, NodeType


def test_sectivia_loader_parsing_and_attribution():
    """Verifies that Sectivia JSON/CSV dataset loads with required attribution and metadata."""
    loader = SectiviaSupplyChainLoader()
    companies, relations, metadata = loader.load_dataset()

    assert len(companies) >= 200
    assert len(relations) >= 300
    assert "Sectivia (https://sectivia.com), CC BY 4.0" in metadata["attribution"]
    assert metadata["license"] == "CC BY 4.0"


def test_sectivia_supplier_to_customer_direction_and_deduplication():
    """Verifies directed edges run supplier -> customer and relations are deduplicated."""
    engine = build_demo_graph()
    initial_nodes_count = len(engine.node_metadata)

    loader = SectiviaSupplyChainLoader()
    result = loader.reconcile_with_graph(engine)

    assert result["nodes_added"] > 0
    assert result["edges_added"] > 0
    assert "CC BY 4.0" in result["attribution"]

    # Reconciling twice must NOT duplicate edges or nodes
    second_res = loader.reconcile_with_graph(engine)
    assert second_res["nodes_added"] == 0
    assert second_res["edges_added"] == 0


def test_sectivia_reconciliation_preserves_core_node_ids():
    """Verifies that existing core CLIMATWIN nodes (comp_nvidia, sup_tsmc, comp_apple) are preserved."""
    engine = build_demo_graph(include_sectivia=True)

    # Core IDs must remain intact
    assert "comp_nvidia" in engine.node_metadata
    assert "sup_tsmc" in engine.node_metadata
    assert "comp_apple" in engine.node_metadata
    assert "hz_taiwan_drought" in engine.node_metadata

    nvda_node = engine.node_metadata["comp_nvidia"]
    assert nvda_node.type == NodeType.COMPANY
    assert "sectivia_attribution" in nvda_node.properties


def test_commercial_links_do_not_imply_climate_damage():
    """Verifies that Sectivia supply chain links are NOT treated as evidence of climate damage."""
    engine = build_demo_graph(include_sectivia=True)

    # Pick an imported Sectivia company (e.g. sectivia_amzn or sectivia_msft)
    imported_nodes = [
        n for n in engine.node_metadata.values() if n.id.startswith("sectivia_")
    ]
    assert len(imported_nodes) > 0

    for node in imported_nodes[:10]:
        # Risk score must not be fabricated as damaged
        assert node.risk_score == 0.0
        assert node.properties.get("is_commercial_link_only") is True
        assert "Sectivia" in node.properties.get("attribution", "")


def test_multi_tier_networkx_propagation_through_sectivia():
    """Verifies NetworkX path calculation traverses from hazard -> fab -> TSMC -> NVDA -> Sectivia customer."""
    engine = build_demo_graph(include_sectivia=True)

    # Find propagation path to a downstream customer of NVIDIA (e.g. Amazon or Microsoft)
    if "sectivia_amzn" in engine.node_metadata:
        paths = engine.find_hazard_propagation_paths(
            hazard_id="hz_taiwan_drought",
            target_id="sectivia_amzn",
        )
        assert len(paths) >= 1
        path_nodes = paths[0].path_nodes
        assert path_nodes[0] == "hz_taiwan_drought"
        assert "sup_tsmc" in path_nodes
        assert "comp_nvidia" in path_nodes
        assert path_nodes[-1] == "sectivia_amzn"
