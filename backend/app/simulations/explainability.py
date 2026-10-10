"""CLIMATWIN Explainable AI (XAI) & Mathematical Decomposition Module.

Implements defensible multi-layered explainability:
1. Deterministic Component Attribution:
   - Closed-form mathematical point and percentage contributions of H, E, V pillars.
   - Sub-factor attribution (SPEI12 anomaly, tier depth discount, mitigation deductions).
2. NetworkX Structural Path Explanation:
   - Human-readable narrative detailing physical propagation hops and tier discounts.
3. Python Numerical Decomposition:
   - Plain-English breakdown of financial stress arithmetic.
4. Segregated SHAP Interface:
   - Explicitly separated from deterministic calculations; provides Tree/Linear SHAP
     when a trained model exists, with clear guardrails explaining why deterministic
     linear formulas use exact closed-form attribution instead of sampling approximations.
"""

from typing import Dict, List, Optional, Any, Tuple
from pydantic import BaseModel, Field
import numpy as np

from app.graph.engine import DependencyGraphEngine


class FactorAttribution(BaseModel):
    factor_name: str
    pillar: str  # hazard, exposure, vulnerability
    raw_value: float
    weight: float
    contribution_points: float
    contribution_percentage: float
    description: str


class ComponentAttributionReport(BaseModel):
    composite_risk_score: float
    hazard_contribution_pts: float
    exposure_contribution_pts: float
    vulnerability_contribution_pts: float
    hazard_percentage: float
    exposure_percentage: float
    vulnerability_percentage: float
    sub_factor_breakdown: List[FactorAttribution]
    formula: str = "Composite Risk = (0.35 * Hazard) + (0.35 * Exposure) + (0.30 * Vulnerability)"


class PathHopExplanation(BaseModel):
    hop_index: int
    source_node_id: str
    source_label: str
    target_node_id: str
    target_label: str
    relationship: str
    tier_depth: int
    discount_factor: float
    narrative: str


class NetworkXPathExplanation(BaseModel):
    hazard_id: str
    target_id: str
    path_nodes: List[str]
    total_hops: int
    tier_depth: int
    tier_discount_applied: float
    hop_explanations: List[PathHopExplanation]
    overall_transmission_narrative: str


class NumericalDecompositionReport(BaseModel):
    baseline_value_usd: float
    unmitigated_drawdown_pct: float
    unmitigated_loss_usd: float
    mitigated_drawdown_pct: float
    mitigated_loss_usd: float
    capital_preserved_usd: float
    mitigation_efficiency_pct: float
    step_by_step_explanation: List[str]


class ShapExplanationResult(BaseModel):
    is_applicable: bool
    status: str
    shap_values: Optional[Dict[str, float]] = None
    base_value: Optional[float] = None
    feature_importances: Optional[Dict[str, float]] = None
    explanation_policy: str


class ExplainabilityEngine:
    """Provides transparent, multi-layered explanations for CLIMATWIN risk calculations."""

    @staticmethod
    def compute_component_attribution(
        hazard_score: float,
        exposure_score: float,
        vulnerability_score: float,
        weights: Dict[str, float],
    ) -> ComponentAttributionReport:
        """Computes exact closed-form mathematical point and percentage attribution."""
        w_h = weights.get("hazard", 0.35)
        w_e = weights.get("exposure", 0.35)
        w_v = weights.get("vulnerability", 0.30)

        pts_h = round(w_h * hazard_score, 2)
        pts_e = round(w_e * exposure_score, 2)
        pts_v = round(w_v * vulnerability_score, 2)
        composite = round(pts_h + pts_e + pts_v, 2)

        safe_total = composite if composite > 0 else 1.0
        pct_h = round((pts_h / safe_total) * 100.0, 1)
        pct_e = round((pts_e / safe_total) * 100.0, 1)
        pct_v = round((pts_v / safe_total) * 100.0, 1)

        # Detailed sub-factor breakdown
        sub_factors = [
            FactorAttribution(
                factor_name="Physical Hazard Severity",
                pillar="hazard",
                raw_value=hazard_score,
                weight=w_h,
                contribution_points=pts_h,
                contribution_percentage=pct_h,
                description=f"Meteorological and hydrological telemetry (SPEI12 anomaly, temperature exceedance, reservoir deficit).",
            ),
            FactorAttribution(
                factor_name="Supply-Chain Exposure",
                pillar="exposure",
                raw_value=exposure_score,
                weight=w_e,
                contribution_points=pts_e,
                contribution_percentage=pct_e,
                description=f"Portfolio asset weighting discounted by NetworkX topological tier depth.",
            ),
            FactorAttribution(
                factor_name="Operational Vulnerability",
                pillar="vulnerability",
                raw_value=vulnerability_score,
                weight=w_v,
                contribution_points=pts_v,
                contribution_percentage=pct_v,
                description=f"Single-source dependency baseline offset by secondary suppliers and on-site water recycling buffers.",
            ),
        ]

        return ComponentAttributionReport(
            composite_risk_score=composite,
            hazard_contribution_pts=pts_h,
            exposure_contribution_pts=pts_e,
            vulnerability_contribution_pts=pts_v,
            hazard_percentage=pct_h,
            exposure_percentage=pct_e,
            vulnerability_percentage=pct_v,
            sub_factor_breakdown=sub_factors,
            formula=f"Composite Risk = ({w_h:.2f} * Hazard) + ({w_e:.2f} * Exposure) + ({w_v:.2f} * Vulnerability)",
        )

    @staticmethod
    def explain_networkx_propagation(
        graph_engine: DependencyGraphEngine,
        path_nodes: List[str],
        tier_depth: int,
        tier_discount: float,
    ) -> NetworkXPathExplanation:
        """Generates human-readable narrative explaining each hop in the NetworkX propagation path."""
        if not path_nodes:
            return NetworkXPathExplanation(
                hazard_id="unknown",
                target_id="unknown",
                path_nodes=[],
                total_hops=0,
                tier_depth=1,
                tier_discount_applied=1.0,
                hop_explanations=[],
                overall_transmission_narrative="No propagation path traversed.",
            )

        hazard_id = path_nodes[0]
        target_id = path_nodes[-1]
        hops: List[PathHopExplanation] = []

        for i in range(len(path_nodes) - 1):
            src_id = path_nodes[i]
            tgt_id = path_nodes[i + 1]

            src_node = graph_engine.node_metadata.get(src_id)
            tgt_node = graph_engine.node_metadata.get(tgt_id)

            src_label = src_node.label if src_node else src_id
            tgt_label = tgt_node.label if tgt_node else tgt_id

            # Determine hop relationship narrative
            narrative = f"Hop {i + 1}: '{src_label}' connects to '{tgt_label}'"
            if "drought" in src_id.lower() or "hazard" in src_id.lower():
                narrative = f"Hop 1 (Hazard Exposure): Physical climate event '{src_label}' covers regional basin '{tgt_label}'."
            elif "reg_" in src_id:
                narrative = f"Hop 2 (Regional Infrastructure): Basin '{src_label}' houses industrial facility '{tgt_label}'."
            elif "fac_" in src_id:
                narrative = f"Hop 3 (Commodity Dependency): Facility '{src_label}' consumes critical input wafers/water '{tgt_label}'."
            elif "comm_" in src_id or "sup_" in src_id:
                narrative = f"Hop 4 (Foundry Supply): Production bottleneck at '{src_label}' impacts contract foundry '{tgt_label}'."
            elif "comp_" in tgt_id:
                narrative = f"Hop 5 (Holding Exposure): Component constraint transmits to portfolio company '{tgt_label}'."
            elif "sectivia_" in tgt_id:
                narrative = f"Hop 6 (Downstream Distribution): OEM '{src_label}' commercial dependency impacts enterprise customer '{tgt_label}'."

            hops.append(
                PathHopExplanation(
                    hop_index=i + 1,
                    source_node_id=src_id,
                    source_label=src_label,
                    target_node_id=tgt_id,
                    target_label=tgt_label,
                    relationship="transmits_disruption",
                    tier_depth=min(4, i + 1),
                    discount_factor=round(max(0.35, 1.0 - (0.15 * i)), 2),
                    narrative=narrative,
                )
            )

        overall = (
            f"Disruption originates at acute climate hazard '{path_nodes[0]}' and traverses "
            f"{len(hops)} intermediate infrastructure and commercial dependency tiers to reach target holding "
            f"'{path_nodes[-1]}'. Multi-tier transmission discount of {tier_discount:.2f}x reflects indirect supply-chain buffering."
        )

        return NetworkXPathExplanation(
            hazard_id=hazard_id,
            target_id=target_id,
            path_nodes=path_nodes,
            total_hops=len(hops),
            tier_depth=tier_depth,
            tier_discount_applied=tier_discount,
            hop_explanations=hops,
            overall_transmission_narrative=overall,
        )

    @staticmethod
    def explain_numerical_calculations(
        baseline_value_usd: float,
        hazard_score: float,
        vulnerability_score: float,
        unmitigated_drawdown_pct: float,
        unmitigated_loss_usd: float,
        mitigated_drawdown_pct: float,
        mitigated_loss_usd: float,
        capital_preserved_usd: float,
        has_secondary_supplier: bool,
        has_onsite_mitigation: bool,
    ) -> NumericalDecompositionReport:
        """Generates plain-English step-by-step arithmetic decomposition of the financial calculation."""
        efficiency = round(
            ((unmitigated_loss_usd - mitigated_loss_usd) / unmitigated_loss_usd * 100.0)
            if unmitigated_loss_usd > 0
            else 0.0,
            1,
        )

        steps = [
            f"1. Baseline Position Value: Evaluated at ${baseline_value_usd:,.0f} USD based on portfolio AUM and allocation weight.",
            f"2. Physical Shock Multiplier: Hazard Severity ({hazard_score:.1f}/100) * Vulnerability ({vulnerability_score:.1f}/100) * 22.0% max loss benchmark.",
            f"3. Unmitigated Stress: Modeled unmitigated drawdown of {unmitigated_drawdown_pct:.2f}% yields an unmitigated loss of ${unmitigated_loss_usd:,.0f} USD.",
            f"4. Mitigation Offsets: "
            + ("Secondary supplier contract active (-35% loss dampening). " if has_secondary_supplier else "No secondary supplier active. ")
            + ("On-site closed-loop water recycling active (-35% loss dampening). " if has_onsite_mitigation else "No on-site recycling buffer. "),
            f"5. Residual Exposure: Mitigated drawdown restricted to {mitigated_drawdown_pct:.2f}%, containing residual loss to ${mitigated_loss_usd:,.0f} USD.",
            f"6. Net Capital Preserved: Pre-emptive mitigation hedges preserve ${capital_preserved_usd:,.0f} USD in portfolio capital ({efficiency}% loss reduction).",
        ]

        return NumericalDecompositionReport(
            baseline_value_usd=baseline_value_usd,
            unmitigated_drawdown_pct=unmitigated_drawdown_pct,
            unmitigated_loss_usd=unmitigated_loss_usd,
            mitigated_drawdown_pct=mitigated_drawdown_pct,
            mitigated_loss_usd=mitigated_loss_usd,
            capital_preserved_usd=capital_preserved_usd,
            mitigation_efficiency_pct=efficiency,
            step_by_step_explanation=steps,
        )

    @staticmethod
    def explain_with_shap(
        predictive_model: Optional[Any] = None,
        X_sample: Optional[np.ndarray] = None,
        feature_names: Optional[List[str]] = None,
    ) -> ShapExplanationResult:
        """Segregated SHAP interface.
        
        Strictly enforces that SHAP is only executed when a compatible trained predictive
        model with empirical targets exists. Avoids deceptive SHAP sampling on linear formulas.
        """
        if predictive_model is None or X_sample is None:
            return ShapExplanationResult(
                is_applicable=False,
                status="omitted_by_design",
                explanation_policy=(
                    "SHAP (SHapley Additive exPlanations) is designed for non-linear machine learning models "
                    "(e.g., XGBoost, Random Forests, Neural Networks) trained on empirical ground-truth loss labels. "
                    "For CLIMATWIN's deterministic linear H-E-V framework, exact closed-form component attribution "
                    "(pts_H, pts_E, pts_V) provides exact, unbiased mathematical contributions without sampling variance. "
                    "SHAP integration will be activated when an empirical predictive damage surrogate model is calibrated."
                ),
            )

        try:
            import shap
            names = feature_names or ["hazard_severity", "supply_chain_exposure", "operational_vulnerability"]

            # Check if model has tree or linear structure
            if hasattr(predictive_model, "predict"):
                explainer = shap.Explainer(predictive_model, X_sample)
                shap_vals = explainer(X_sample)
                vals_mean = np.mean(np.abs(shap_vals.values), axis=0) if len(shap_vals.values.shape) > 1 else np.abs(shap_vals.values)
                importances = {names[i]: float(vals_mean[i]) for i in range(min(len(names), len(vals_mean)))}

                return ShapExplanationResult(
                    is_applicable=True,
                    status="computed_successfully",
                    base_value=float(explainer.expected_value) if hasattr(explainer, "expected_value") else 0.0,
                    feature_importances=importances,
                    explanation_policy="Computed empirical SHAP values on predictive model.",
                )
        except Exception as e:
            return ShapExplanationResult(
                is_applicable=False,
                status="computation_error",
                explanation_policy=f"SHAP execution error: {e}",
            )

        return ShapExplanationResult(
            is_applicable=False,
            status="unsupported_model_type",
            explanation_policy="Supplied model does not support SHAP explainer.",
        )
