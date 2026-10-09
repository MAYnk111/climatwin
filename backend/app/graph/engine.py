import networkx as nx
from typing import Dict, List, Optional, Set, Tuple
from app.graph.models import (
    GraphNode,
    GraphEdge,
    NodeType,
    RiskLevel,
    EdgeType,
    PropagationPath,
    DependencyGraphResponse,
)


class DependencyGraphEngine:
    """Graph calculation engine using NetworkX for risk propagation and deterministic layout."""

    TIER_ORDER = {
        NodeType.CLIMATE_HAZARD: 0,
        NodeType.GEOGRAPHIC_REGION: 1,
        NodeType.FACILITY: 1,
        NodeType.TRANSPORT_ROUTE: 2,
        NodeType.COMMODITY: 2,
        NodeType.SUPPLIER: 2,
        NodeType.COMPANY: 3,
        NodeType.CUSTOMER: 4,
    }

    def __init__(self):
        self.graph = nx.DiGraph()
        self.node_metadata: Dict[str, GraphNode] = {}
        self.edge_metadata: Dict[str, GraphEdge] = {}

    def add_node(self, node: GraphNode) -> None:
        self.node_metadata[node.id] = node
        self.graph.add_node(
            node.id,
            type=node.type.value,
            risk_level=node.risk_level.value,
            risk_score=node.risk_score,
            label=node.label,
        )

    def add_edge(self, edge: GraphEdge) -> None:
        self.edge_metadata[edge.id] = edge
        self.graph.add_edge(
            edge.source,
            edge.target,
            id=edge.id,
            relationship=edge.relationship.value,
            label=edge.label,
            weight=edge.weight,
        )

    def calculate_deterministic_layout(
        self, width: float = 1000.0, height: float = 800.0
    ) -> Dict[str, Tuple[float, float]]:
        """Calculates stable, readable hierarchical coordinates for mobile screens.
        Hazard (Left/Top) -> Infrastructure/Suppliers (Center) -> Companies/Portfolio (Right/Bottom)
        """
        tier_groups: Dict[int, List[str]] = {}
        for node_id, node in self.node_metadata.items():
            tier = self.TIER_ORDER.get(node.type, 2)
            tier_groups.setdefault(tier, []).append(node_id)

        positions: Dict[str, Tuple[float, float]] = {}
        total_tiers = max(tier_groups.keys()) + 1 if tier_groups else 1
        x_spacing = width / (total_tiers + 1)

        for tier, node_ids in sorted(tier_groups.items()):
            # Sort node IDs alphabetically for completely deterministic ordering
            sorted_nodes = sorted(node_ids)
            count = len(sorted_nodes)
            y_spacing = height / (count + 1)
            x_pos = (tier + 1) * x_spacing

            for idx, n_id in enumerate(sorted_nodes):
                y_pos = (idx + 1) * y_spacing
                positions[n_id] = (round(x_pos, 2), round(y_pos, 2))
                # Update node record
                self.node_metadata[n_id].x = round(x_pos, 2)
                self.node_metadata[n_id].y = round(y_pos, 2)

        return positions

    def find_hazard_propagation_paths(
        self, hazard_id: str, target_id: str
    ) -> List[PropagationPath]:
        """Finds all directed paths propagating risk from a climate hazard to a portfolio/company."""
        paths: List[PropagationPath] = []
        if not self.graph.has_node(hazard_id) or not self.graph.has_node(target_id):
            return paths

        try:
            simple_paths = list(
                nx.all_simple_paths(self.graph, source=hazard_id, target=target_id, cutoff=5)
            )
            for path in simple_paths:
                edge_ids = []
                cumulative_risk = self.node_metadata[hazard_id].risk_score
                for i in range(len(path) - 1):
                    u, v = path[i], path[i + 1]
                    edge_data = self.graph.get_edge_data(u, v)
                    if edge_data and "id" in edge_data:
                        edge_ids.append(edge_data["id"])
                    # Attenuation factor along supply chain hop
                    cumulative_risk *= 0.85

                paths.append(
                    PropagationPath(
                        path_nodes=path,
                        path_edges=edge_ids,
                        hazard_id=hazard_id,
                        target_id=target_id,
                        cumulative_risk=round(cumulative_risk, 2),
                    )
                )
        except nx.NetworkXNoPath:
            pass

        return paths

    def filter_subgraph(
        self,
        relationship_types: Optional[List[EdgeType]] = None,
        min_risk_level: Optional[RiskLevel] = None,
        max_depth: Optional[int] = None,
        center_node_id: Optional[str] = None,
    ) -> DependencyGraphResponse:
        """Filters nodes and edges based on user-selected criteria."""
        self.calculate_deterministic_layout()

        allowed_nodes: Set[str] = set(self.node_metadata.keys())

        # Depth filter from center node if requested
        if center_node_id and center_node_id in self.graph and max_depth is not None:
            lengths = nx.single_source_shortest_path_length(
                self.graph.to_undirected(), center_node_id, cutoff=max_depth
            )
            allowed_nodes = set(lengths.keys())

        # Risk level filter
        risk_rank = {
            RiskLevel.LOW: 0,
            RiskLevel.MEDIUM: 1,
            RiskLevel.HIGH: 2,
            RiskLevel.CRITICAL: 3,
        }
        if min_risk_level:
            min_rank = risk_rank[min_risk_level]
            allowed_nodes = {
                n_id
                for n_id in allowed_nodes
                if risk_rank[self.node_metadata[n_id].risk_level] >= min_rank
            }

        filtered_nodes = [
            self.node_metadata[n_id] for n_id in allowed_nodes if n_id in self.node_metadata
        ]

        # Filter edges
        rel_set = {r.value for r in relationship_types} if relationship_types else None
        filtered_edges: List[GraphEdge] = []
        for e in self.edge_metadata.values():
            if e.source in allowed_nodes and e.target in allowed_nodes:
                if rel_set is None or e.relationship.value in rel_set:
                    filtered_edges.append(e)

        # Compute propagation paths for active nodes
        hazard_nodes = [n_id for n_id in allowed_nodes if self.node_metadata[n_id].type == NodeType.CLIMATE_HAZARD]
        target_nodes = [n_id for n_id in allowed_nodes if self.node_metadata[n_id].type in (NodeType.CUSTOMER, NodeType.COMPANY)]
        propagation_paths: List[PropagationPath] = []
        for h in hazard_nodes:
            for t in target_nodes:
                propagation_paths.extend(self.find_hazard_propagation_paths(hazard_id=h, target_id=t))

        return DependencyGraphResponse(
            nodes=filtered_nodes,
            edges=filtered_edges,
            propagation_paths=propagation_paths,
            metadata={"total_nodes": len(filtered_nodes), "total_edges": len(filtered_edges)},
        )

