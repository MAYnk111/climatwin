"""Tests for CLIMATWIN Phase 3.5: Risk Calibration & Explainable AI.

Verifies:
1. Dataset audit correctly identifies zero empirical loss labels in Sectivia.
2. Simplex weight validation enforces sum=1.0 and non-negativity.
3. Sensitivity analysis evaluates alternative profiles with Spearman rank correlation.
4. Exact closed-form component attribution achieves mathematical closure.
5. NetworkX structural path explanation produces transparent hop narratives.
6. Financial numerical decomposition accurately reflects deterministic arithmetic.
7. Segregated SHAP interface maintains strict safety policy.
8. Gemini numerical isolation ensures Python numbers are never modified.
9. End-to-end PhysicalRiskEngine calculation integrates calibration and explainability.
"""

import pytest
import numpy as np
from app.simulations.calibration import (
    RiskCalibrationManager,
    DatasetAuditReport,
    SensitivityAnalysisReport,
    RequiredCalibrationDataSpec,
)
from app.simulations.explainability import (
    ExplainabilityEngine,
    ComponentAttributionReport,
    NetworkXPathExplanation,
    NumericalDecompositionReport,
    ShapExplanationResult,
)
from app.simulations.risk_engine import PhysicalRiskEngine, RiskCalculationResult
from app.graph.demo_data import build_demo_graph


class TestDatasetAuditAndCalibrationConstraints:
    """Verifies empirical label audit and weight simplex constraints."""

    def test_dataset_audit_verifies_absence_of_empirical_loss_labels(self):
        manager = RiskCalibrationManager()
        report = manager.audit_datasets()

        assert isinstance(report, DatasetAuditReport)
        assert report.total_companies > 0
        assert report.total_relations > 0
        # Scientific honesty: Sectivia contains buyer-supplier relations, NOT loss labels
        assert report.has_empirical_loss_labels is False
        assert report.target_variables_found == []
        assert report.calibration_status == "uncalibrated_provisional"
        assert len(report.leakage_risks_identified) >= 3
        assert "Sectivia relationships represent topological buyer-supplier connections only" in report.audit_findings

    def test_simplex_weights_validation_success(self):
        manager = RiskCalibrationManager()
        valid_weights = {"hazard": 0.35, "exposure": 0.35, "vulnerability": 0.30}
        assert manager.validate_weights(valid_weights) is True

        equal_weights = {"hazard": 0.333, "exposure": 0.333, "vulnerability": 0.334}
        assert manager.validate_weights(equal_weights) is True

    def test_simplex_weights_validation_fails_on_non_sum_one(self):
        manager = RiskCalibrationManager()
        # Sum != 1.0
        invalid_sum = {"hazard": 0.50, "exposure": 0.50, "vulnerability": 0.50}
        with pytest.raises(ValueError, match="Weights must sum to 1.0"):
            manager.validate_weights(invalid_sum)

    def test_simplex_weights_validation_fails_on_negative_or_exceeding(self):
        manager = RiskCalibrationManager()
        negative_weight = {"hazard": -0.10, "exposure": 0.60, "vulnerability": 0.50}
        with pytest.raises(ValueError, match="must be non-negative"):
            manager.validate_weights(negative_weight)

    def test_simplex_weights_validation_fails_on_missing_keys(self):
        manager = RiskCalibrationManager()
        missing_key = {"hazard": 0.50, "exposure": 0.50}
        with pytest.raises(ValueError, match="Weights must include"):
            manager.validate_weights(missing_key)


class TestSensitivityAnalysis:
    """Verifies systematic sensitivity analysis across the 3-pillar simplex."""

    def test_sensitivity_analysis_across_profiles(self):
        manager = RiskCalibrationManager()
        benchmark_scores = {
            "NVDA": {"hazard": 88.0, "exposure": 65.0, "vulnerability": 85.0},
            "AAPL": {"hazard": 88.0, "exposure": 55.0, "vulnerability": 78.0},
            "TSM": {"hazard": 92.0, "exposure": 85.0, "vulnerability": 75.0},
            "BMW": {"hazard": 62.0, "exposure": 45.0, "vulnerability": 68.0},
            "AMZN": {"hazard": 45.0, "exposure": 35.0, "vulnerability": 40.0},
            "MSFT": {"hazard": 50.0, "exposure": 40.0, "vulnerability": 45.0},
        }

        report = manager.run_sensitivity_analysis(benchmark_scores)
        assert isinstance(report, SensitivityAnalysisReport)
        assert len(report.tested_profiles) == 6
        assert report.ranking_stability_index >= 0.80
        assert isinstance(report.is_ranking_robust, bool)
        assert len(report.tier_flip_summary) == 6

        # Check Spearman rank correlations are bounded between -1.0 and 1.0
        for profile in report.tested_profiles:
            assert -1.0 <= profile.spearman_rank_correlation <= 1.0
            assert set(profile.scores_by_entity.keys()) == set(benchmark_scores.keys())

    def test_required_calibration_data_spec(self):
        manager = RiskCalibrationManager()
        spec = manager.get_calibration_data_spec()
        assert isinstance(spec, RequiredCalibrationDataSpec)
        assert spec.minimum_sample_size >= 100
        assert "SEC 10-K" in spec.primary_sources[0]
        assert "leakage" in spec.leakage_prevention_protocol.lower()

    def test_sensitivity_reconciles_monotonic_and_asymmetric_stability(self):
        manager = RiskCalibrationManager()
        # 1. Monotonic dominance benchmark: All pillars monotonically ordered -> rho = 1.000
        mono_report = manager.run_sensitivity_analysis(manager.STANDARD_BENCHMARK_PORTFOLIO)
        assert mono_report.ranking_stability_index == 1.000

        # 2. Diversified asymmetric portfolio: Trade-offs across pillars -> rho = 0.867
        asym_report = manager.run_sensitivity_analysis(manager.DIVERSIFIED_ASYMMETRIC_PORTFOLIO)
        assert asym_report.ranking_stability_index == 0.867

        # 3. Reconciliation notes are populated and explain the difference
        assert asym_report.reconciliation_notes is not None
        assert "discrepancy_explanation" in asym_report.reconciliation_notes
        assert asym_report.reconciliation_notes["monotonic_benchmark_stability"] == 1.000
        assert asym_report.reconciliation_notes["diversified_asymmetric_stability"] == 0.867


class TestExplainableAIModule:
    """Verifies closed-form component attribution, path explanation, and numerical breakdown."""

    def test_closed_form_component_attribution_mathematical_closure(self):
        h = 75.0
        e = 60.0
        v = 80.0
        weights = {"hazard": 0.35, "exposure": 0.35, "vulnerability": 0.30}

        report = ExplainabilityEngine.compute_component_attribution(
            hazard_score=h,
            exposure_score=e,
            vulnerability_score=v,
            weights=weights,
        )

        assert isinstance(report, ComponentAttributionReport)
        # Mathematical closure: points sum to composite risk score
        points_sum = (
            report.hazard_contribution_pts
            + report.exposure_contribution_pts
            + report.vulnerability_contribution_pts
        )
        assert pytest.approx(points_sum, abs=0.05) == report.composite_risk_score

        # Percentage closure: percentages sum to 100%
        pct_sum = (
            report.hazard_percentage
            + report.exposure_percentage
            + report.vulnerability_percentage
        )
        assert pytest.approx(pct_sum, abs=0.5) == 100.0

        # Sub-factor list has 3 pillars
        assert len(report.sub_factor_breakdown) == 3

    def test_networkx_path_explanation(self):
        graph = build_demo_graph()
        path_nodes = ["hz_taiwan_drought", "reg_hsinchu_basin", "fac_tsmc_fab12", "comm_3nm_wafers", "comp_nvidia"]
        tier_depth = 3
        tier_discount = 0.55

        explanation = ExplainabilityEngine.explain_networkx_propagation(
            graph_engine=graph,
            path_nodes=path_nodes,
            tier_depth=tier_depth,
            tier_discount=tier_discount,
        )

        assert isinstance(explanation, NetworkXPathExplanation)
        assert explanation.total_hops == len(path_nodes) - 1
        assert len(explanation.hop_explanations) == explanation.total_hops
        assert explanation.tier_discount_applied == tier_discount
        assert "Disruption originates at acute climate hazard" in explanation.overall_transmission_narrative

    def test_numerical_decomposition(self):
        decomp = ExplainabilityEngine.explain_numerical_calculations(
            baseline_value_usd=22_500_000.0,
            hazard_score=85.0,
            vulnerability_score=70.0,
            unmitigated_drawdown_pct=13.09,
            unmitigated_loss_usd=2_945_250.0,
            mitigated_drawdown_pct=3.93,
            mitigated_loss_usd=884_250.0,
            capital_preserved_usd=2_061_000.0,
            has_secondary_supplier=True,
            has_onsite_mitigation=True,
        )

        assert isinstance(decomp, NumericalDecompositionReport)
        assert decomp.baseline_value_usd == 22_500_000.0
        assert decomp.capital_preserved_usd == 2_061_000.0
        assert decomp.mitigation_efficiency_pct > 0.0
        assert len(decomp.step_by_step_explanation) >= 6

    def test_segregated_shap_interface_safety(self):
        shap_res = ExplainabilityEngine.explain_with_shap()
        assert isinstance(shap_res, ShapExplanationResult)
        assert shap_res.is_applicable is False
        assert shap_res.status == "omitted_by_design"
        assert "SHAP (SHapley Additive exPlanations) is designed for non-linear machine learning models" in shap_res.explanation_policy


class TestPhysicalRiskEngineEndToEnd:
    """Verifies full PhysicalRiskEngine workflow and LLM numerical isolation."""

    def test_calculate_entity_risk_includes_phase_3_5_fields(self):
        graph = build_demo_graph()
        engine = PhysicalRiskEngine(graph)

        result = engine.calculate_entity_risk(
            hazard_id="hz_taiwan_drought",
            hazard_title="Central Taiwan Extreme Drought",
            target_node_id="comp_nvidia",
            portfolio_aum_usd=250_000_000.0,
            has_secondary_supplier=True,
            has_onsite_mitigation=True,
        )

        assert isinstance(result, RiskCalculationResult)
        assert result.model_calibration_status == "provisional_engineering_model"
        assert result.calibration_metadata is not None
        assert result.component_attribution is not None
        assert result.networkx_path_explanation is not None
        assert result.numerical_decomposition is not None
        assert result.sensitivity_analysis is not None
        assert result.shap_status is not None

        # Verify numerical integrity
        assert result.hazard_score > 0
        assert result.composite_risk_score > 0
        assert result.baseline_value_usd > 0
        assert result.unmitigated_loss_usd > 0
        assert result.mitigated_loss_usd >= 0
        assert result.capital_preserved_usd >= 0

    def test_gemini_numerical_isolation(self):
        graph = build_demo_graph()
        engine = PhysicalRiskEngine(graph)

        result_pre = engine.calculate_entity_risk(
            hazard_id="hz_taiwan_drought",
            hazard_title="Central Taiwan Extreme Drought",
            target_node_id="comp_nvidia",
        )

        # Record exact Python pre-computed numbers
        pre_hazard = result_pre.hazard_score
        pre_exposure = result_pre.exposure_score
        pre_vuln = result_pre.vulnerability_score
        pre_composite = result_pre.composite_risk_score
        pre_unmit_loss = result_pre.unmitigated_loss_usd
        pre_mit_loss = result_pre.mitigated_loss_usd
        pre_preserved = result_pre.capital_preserved_usd

        # Run synthesis (either Gemini or fallback)
        result_post = engine.synthesize_risk_with_gemini(result_pre)

        # Numbers MUST NOT be modified or overridden
        assert result_post.hazard_score == pre_hazard
        assert result_post.exposure_score == pre_exposure
        assert result_post.vulnerability_score == pre_vuln
        assert result_post.composite_risk_score == pre_composite
        assert result_post.unmitigated_loss_usd == pre_unmit_loss
        assert result_post.mitigated_loss_usd == pre_mit_loss
        assert result_post.capital_preserved_usd == pre_preserved
        assert result_post.executive_synthesis is not None
        assert len(result_post.executive_synthesis) > 20
