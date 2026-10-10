"""Sectivia Supply-Chain Data Loader and Graph Reconciler for CLIMATWIN.

Imports verified supplier-to-customer relationships from Sectivia datasets:
- Supplier-to-customer directed edges (supplier -> customer)
- Deduplication of records and validation of company tickers
- Preservation of sectors, segments, country, exchange, and source metadata
- Attribution: "Supply-chain data: Sectivia (https://sectivia.com), CC BY 4.0"
- Reconciles imported records with existing CLIMATWIN graph without breaking IDs

Important note: Supplier links indicate commercial customer-supplier dependencies;
they do NOT constitute evidence of climate damage or financial loss.
"""

import os
import json
import csv
import logging
from typing import Dict, List, Optional, Set, Tuple, Any
from pathlib import Path

from app.graph.engine import DependencyGraphEngine
from app.graph.models import GraphNode, GraphEdge, NodeType, RiskLevel, EdgeType

logger = logging.getLogger("climatwin.graph.sectivia")

SECTIVIA_ATTRIBUTION = "Supply-chain data: Sectivia (https://sectivia.com), CC BY 4.0"
SECTIVIA_URL = "https://sectivia.com/dataset/"


class SectiviaSupplyChainLoader:
    """Loads and reconciles Sectivia supply-chain data into the NetworkX graph engine."""

    # Explicit mapping for existing core CLIMATWIN node IDs to prevent collisions
    CORE_TICKER_TO_NODE_ID = {
        "NVDA": "comp_nvidia",
        "AAPL": "comp_apple",
        "BMW.DE": "comp_bmw",
        "TSM": "sup_tsmc",
        "BASF": "sup_basf",
    }

    def __init__(self, datasets_dir: Optional[str] = None):
        if datasets_dir:
            self.datasets_dir = Path(datasets_dir)
        else:
            # Check standard relative paths
            candidates = [
                Path("datasets"),
                Path("../datasets"),
                Path("fusion_r2/datasets"),
                Path("c:/Users/Lenovo/Desktop/fusion_r2/datasets"),
            ]
            self.datasets_dir = next((p for p in candidates if p.exists()), Path("datasets"))

        self.json_path = self.datasets_dir / "sectivia-supply-chain.json"
        self.companies_csv = self.datasets_dir / "sectivia-companies.csv"
        self.relations_csv = self.datasets_dir / "sectivia-relations.csv"

    def load_dataset(self) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]], Dict[str, Any]]:
        """Loads companies, relations, and metadata from Sectivia JSON or CSV files."""
        if self.json_path.exists():
            try:
                with open(self.json_path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    companies = data.get("companies", [])
                    relations = data.get("relations", [])
                    metadata = {
                        "name": data.get("name"),
                        "description": data.get("description"),
                        "license": data.get("license", "CC BY 4.0"),
                        "attribution": data.get("attribution", SECTIVIA_ATTRIBUTION),
                        "url": data.get("url", SECTIVIA_URL),
                        "caveat": data.get("caveat"),
                    }
                    return companies, relations, metadata
            except Exception as e:
                logger.warning(f"Error reading Sectivia JSON: {e}")

        # Fallback to CSV if JSON fails
        companies: List[Dict[str, Any]] = []
        if self.companies_csv.exists():
            with open(self.companies_csv, "r", encoding="utf-8") as f:
                reader = csv.DictReader(f)
                for row in reader:
                    companies.append(row)

        relations: List[Dict[str, Any]] = []
        if self.relations_csv.exists():
            with open(self.relations_csv, "r", encoding="utf-8") as f:
                reader = csv.DictReader(f)
                for row in reader:
                    relations.append({
                        "supplier": row.get("supplier_id"),
                        "supplierTicker": row.get("supplier_ticker"),
                        "customer": row.get("customer_id"),
                        "customerTicker": row.get("customer_ticker"),
                        "sector": row.get("sector") or row.get("supplier_sector"),
                    })

        metadata = {
            "name": "Sectivia U.S. supply-chain graph (CSV)",
            "license": "CC BY 4.0",
            "attribution": SECTIVIA_ATTRIBUTION,
            "url": SECTIVIA_URL,
        }
        return companies, relations, metadata

    def reconcile_with_graph(
        self, engine: DependencyGraphEngine, max_nodes: Optional[int] = None
    ) -> Dict[str, Any]:
        """Reconciles Sectivia supply-chain records into the given DependencyGraphEngine.
        
        Preserves existing nodes, adds new companies with stable IDs, builds directed
        supplier -> customer edges, and includes CC BY 4.0 attribution without treating
        links as climate damage.
        """
        companies, relations, metadata = self.load_dataset()
        if not companies:
            logger.warning("No Sectivia companies found to reconcile.")
            return {"nodes_added": 0, "edges_added": 0}

        # Index existing graph nodes by ticker
        existing_tickers: Dict[str, str] = {}
        for node_id, node in engine.node_metadata.items():
            if node.properties and "ticker" in node.properties:
                existing_tickers[node.properties["ticker"].upper()] = node_id
            # Also check label for ticker like (AAPL)
            if "(" in node.label and ")" in node.label:
                possible_ticker = node.label.split("(")[-1].split(")")[0].strip().upper()
                existing_tickers[possible_ticker] = node_id

        # Also add our explicit core mappings
        for t, nid in self.CORE_TICKER_TO_NODE_ID.items():
            if nid in engine.node_metadata:
                existing_tickers[t.upper()] = nid

        company_id_to_graph_node_id: Dict[str, str] = {}
        nodes_added = 0
        edges_added = 0

        # Step 1: Add or link companies
        for c in companies:
            if max_nodes and nodes_added >= max_nodes:
                break

            c_id = str(c.get("id", "")).strip().lower()
            ticker = str(c.get("ticker", "")).strip().upper()
            name = c.get("name", ticker or c_id)

            if not c_id:
                continue

            # Check if this company already exists in the graph
            if ticker in existing_tickers:
                existing_node_id = existing_tickers[ticker]
                company_id_to_graph_node_id[c_id] = existing_node_id
                # Enrich existing node metadata with Sectivia attribution and sector info
                node = engine.node_metadata[existing_node_id]
                node.properties["sectivia_id"] = c_id
                node.properties["sectivia_attribution"] = SECTIVIA_ATTRIBUTION
                node.properties["sectivia_url"] = SECTIVIA_URL
                if not node.sector and c.get("sector"):
                    node.sector = c.get("sector")
                continue

            # Create new GraphNode for Sectivia company
            graph_node_id = f"sectivia_{c_id}"
            company_id_to_graph_node_id[c_id] = graph_node_id

            new_node = GraphNode(
                id=graph_node_id,
                label=f"{name} ({ticker})" if ticker else name,
                type=NodeType.COMPANY,
                risk_level=RiskLevel.LOW,
                risk_score=0.0,  # Explicit: supply chain link != climate damage
                sector=c.get("sector"),
                location=c.get("country", "Global"),
                properties={
                    "ticker": ticker,
                    "exchange": c.get("exchange"),
                    "country": c.get("country"),
                    "sector": c.get("sector"),
                    "segment": c.get("segment"),
                    "is_listed": c.get("listed", True),
                    "attribution": SECTIVIA_ATTRIBUTION,
                    "source_url": SECTIVIA_URL,
                    "is_commercial_link_only": True,
                },
            )
            engine.add_node(new_node)
            nodes_added += 1

        # Step 2: Add directed supplier -> customer edges (deduplicated)
        seen_edges: Set[Tuple[str, str]] = set()

        for r in relations:
            supp_id = str(r.get("supplier", "")).strip().lower()
            cust_id = str(r.get("customer", "")).strip().lower()

            supp_node_id = company_id_to_graph_node_id.get(supp_id)
            cust_node_id = company_id_to_graph_node_id.get(cust_id)

            if not supp_node_id or not cust_node_id:
                continue

            if supp_node_id == cust_node_id:
                continue

            edge_key = (supp_node_id, cust_node_id)
            if edge_key in seen_edges or engine.graph.has_edge(supp_node_id, cust_node_id):
                continue
            seen_edges.add(edge_key)

            edge_id = f"sec_edge_{supp_id}_to_{cust_id}"
            new_edge = GraphEdge(
                id=edge_id,
                source=supp_node_id,
                target=cust_node_id,
                relationship=EdgeType.SUPPLIES_TO,
                label=f"supplies {r.get('sector', 'goods')}",
                weight=0.85,
                properties={
                    "sector": r.get("sector"),
                    "attribution": SECTIVIA_ATTRIBUTION,
                    "source_url": SECTIVIA_URL,
                    "is_commercial_link": True,
                },
            )
            engine.add_edge(new_edge)
            edges_added += 1

        logger.info(
            f"Reconciled Sectivia dataset: {nodes_added} new nodes, {edges_added} supplier edges added."
        )
        return {
            "nodes_added": nodes_added,
            "edges_added": edges_added,
            "total_nodes": len(engine.node_metadata),
            "total_edges": len(engine.edge_metadata),
            "attribution": SECTIVIA_ATTRIBUTION,
        }
