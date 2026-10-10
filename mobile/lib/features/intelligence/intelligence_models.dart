class EvidenceItemModel {
  final String id;
  final String sourceName;
  final String? sourceUrl;
  final String title;
  final String snippet;
  final String timestamp;
  final double reliabilityScore;

  const EvidenceItemModel({
    required this.id,
    required this.sourceName,
    this.sourceUrl,
    required this.title,
    required this.snippet,
    required this.timestamp,
    required this.reliabilityScore,
  });

  factory EvidenceItemModel.fromJson(Map<String, dynamic> json) {
    return EvidenceItemModel(
      id: json['id']?.toString() ?? '',
      sourceName: json['source_name']?.toString() ?? 'Verified Feed',
      sourceUrl: json['source_url']?.toString(),
      title: json['title']?.toString() ?? '',
      snippet: json['snippet']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
      reliabilityScore: (json['reliability_score'] is num)
          ? (json['reliability_score'] as num).toDouble()
          : 0.9,
    );
  }
}

class ImpactedHoldingModel {
  final String ticker;
  final String holdingName;
  final double weight;
  final int tierExposure;
  final bool directImpact;

  const ImpactedHoldingModel({
    required this.ticker,
    required this.holdingName,
    required this.weight,
    required this.tierExposure,
    required this.directImpact,
  });

  factory ImpactedHoldingModel.fromJson(Map<String, dynamic> json) {
    return ImpactedHoldingModel(
      ticker: json['ticker']?.toString() ?? '',
      holdingName: json['holding_name']?.toString() ?? '',
      weight: (json['weight'] is num) ? (json['weight'] as num).toDouble() : 0.0,
      tierExposure: (json['tier_exposure'] is int) ? json['tier_exposure'] as int : 1,
      directImpact: json['direct_impact'] == true,
    );
  }
}

class MitigationRecommendationModel {
  final String action;
  final double impactReductionPct;
  final String feasibility;
  final double savingsUsd;

  const MitigationRecommendationModel({
    required this.action,
    required this.impactReductionPct,
    required this.feasibility,
    this.savingsUsd = 0.0,
  });

  factory MitigationRecommendationModel.fromJson(Map<String, dynamic> json) {
    return MitigationRecommendationModel(
      action: json['action']?.toString() ?? '',
      impactReductionPct: (json['impact_reduction_pct'] is num)
          ? (json['impact_reduction_pct'] as num).toDouble()
          : 0.0,
      feasibility: json['feasibility']?.toString() ?? 'Feasible',
      savingsUsd: (json['savings_usd'] is num)
          ? (json['savings_usd'] as num).toDouble()
          : 0.0,
    );
  }
}

class AgentExecutionStepModel {
  final String agentId;
  final String agentName;
  final String role;
  final String status;
  final String timestamp;
  final String summary;
  final List<String> keyFindings;

  const AgentExecutionStepModel({
    required this.agentId,
    required this.agentName,
    required this.role,
    this.status = 'completed',
    required this.timestamp,
    required this.summary,
    this.keyFindings = const [],
  });

  factory AgentExecutionStepModel.fromJson(Map<String, dynamic> json) {
    return AgentExecutionStepModel(
      agentId: json['agent_id']?.toString() ?? '',
      agentName: json['agent_name']?.toString() ?? 'Specialist Agent',
      role: json['role']?.toString() ?? 'Analyst',
      status: json['status']?.toString() ?? 'completed',
      timestamp: json['timestamp']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      keyFindings: (json['key_findings'] as List?)
              ?.map((k) => k.toString())
              .toList() ??
          [],
    );
  }
}

class ClimateObservationMetricModel {
  final String metricName;
  final dynamic observedValue;
  final String unit;
  final String? historicalBaseline;
  final String? anomalyIndicator;
  final String source;
  final String? sourceUrl;
  final String timestamp;
  final String dataProvenance;

  const ClimateObservationMetricModel({
    required this.metricName,
    required this.observedValue,
    required this.unit,
    this.historicalBaseline,
    this.anomalyIndicator,
    required this.source,
    this.sourceUrl,
    required this.timestamp,
    this.dataProvenance = 'observed_telemetry',
  });

  factory ClimateObservationMetricModel.fromJson(Map<String, dynamic> json) {
    return ClimateObservationMetricModel(
      metricName: json['metric_name']?.toString() ?? '',
      observedValue: json['observed_value'],
      unit: json['unit']?.toString() ?? '',
      historicalBaseline: json['historical_baseline']?.toString(),
      anomalyIndicator: json['anomaly_indicator']?.toString(),
      source: json['source']?.toString() ?? 'Sensor Telemetry',
      sourceUrl: json['source_url']?.toString(),
      timestamp: json['timestamp']?.toString() ?? '',
      dataProvenance: json['data_provenance']?.toString() ?? 'observed_telemetry',
    );
  }
}

class ClimateIntelligenceModel {
  final String region;
  final String hazardType;
  final String droughtStressLevel;
  final List<ClimateObservationMetricModel> observations;
  final double? reservoirStoragePct;
  final double? precipitationDeficitPct;
  final double? spei12DroughtIndex;
  final List<String> dataSources;

  const ClimateIntelligenceModel({
    required this.region,
    required this.hazardType,
    required this.droughtStressLevel,
    this.observations = const [],
    this.reservoirStoragePct,
    this.precipitationDeficitPct,
    this.spei12DroughtIndex,
    this.dataSources = const [],
  });

  factory ClimateIntelligenceModel.fromJson(Map<String, dynamic> json) {
    return ClimateIntelligenceModel(
      region: json['region']?.toString() ?? '',
      hazardType: json['hazard_type']?.toString() ?? '',
      droughtStressLevel: json['drought_stress_level']?.toString() ?? '',
      observations: (json['observations'] as List?)
              ?.map((o) => ClimateObservationMetricModel.fromJson(o as Map<String, dynamic>))
              .toList() ??
          [],
      reservoirStoragePct: (json['reservoir_storage_pct'] is num)
          ? (json['reservoir_storage_pct'] as num).toDouble()
          : null,
      precipitationDeficitPct: (json['precipitation_deficit_pct'] is num)
          ? (json['precipitation_deficit_pct'] as num).toDouble()
          : null,
      spei12DroughtIndex: (json['spei12_drought_index'] is num)
          ? (json['spei12_drought_index'] as num).toDouble()
          : null,
      dataSources: (json['data_sources'] as List?)
              ?.map((d) => d.toString())
              .toList() ??
          [],
    );
  }
}

class ScenarioAnalysisModel {
  final String baselinePeriod;
  final List<String> testedScenarios;
  final String anomalyDelta;
  final String projectedTemperatureShift;
  final String projectedPrecipitationShift;
  final Map<String, dynamic> ensemblePercentiles;
  final String returnPeriodEstimate;
  final bool thresholdBreached;
  final String scenarioRiskClassification;

  const ScenarioAnalysisModel({
    required this.baselinePeriod,
    this.testedScenarios = const [],
    required this.anomalyDelta,
    required this.projectedTemperatureShift,
    required this.projectedPrecipitationShift,
    this.ensemblePercentiles = const {},
    required this.returnPeriodEstimate,
    this.thresholdBreached = true,
    this.scenarioRiskClassification = 'critical',
  });

  factory ScenarioAnalysisModel.fromJson(Map<String, dynamic> json) {
    return ScenarioAnalysisModel(
      baselinePeriod: json['baseline_period']?.toString() ?? '1950-2014',
      testedScenarios: (json['tested_scenarios'] as List?)
              ?.map((s) => s.toString())
              .toList() ??
          [],
      anomalyDelta: json['anomaly_delta']?.toString() ?? '',
      projectedTemperatureShift: json['projected_temperature_shift']?.toString() ?? '',
      projectedPrecipitationShift: json['projected_precipitation_shift']?.toString() ?? '',
      ensemblePercentiles: json['ensemble_percentiles'] as Map<String, dynamic>? ?? {},
      returnPeriodEstimate: json['return_period_estimate']?.toString() ?? '',
      thresholdBreached: json['threshold_breached'] != false,
      scenarioRiskClassification: json['scenario_risk_classification']?.toString() ?? 'critical',
    );
  }
}

class VerificationReportModel {
  final List<String> verifiedSources;
  final String consensusStatus;
  final List<String> verifiedClaims;
  final List<String> unsupportedOrFlaggedClaims;
  final String? telemetryConflictNotes;
  final double confidenceLevel;

  const VerificationReportModel({
    this.verifiedSources = const [],
    this.consensusStatus = 'high_consensus',
    this.verifiedClaims = const [],
    this.unsupportedOrFlaggedClaims = const [],
    this.telemetryConflictNotes,
    this.confidenceLevel = 0.94,
  });

  factory VerificationReportModel.fromJson(Map<String, dynamic> json) {
    return VerificationReportModel(
      verifiedSources: (json['verified_sources'] as List?)
              ?.map((v) => v.toString())
              .toList() ??
          [],
      consensusStatus: json['consensus_status']?.toString() ?? 'high_consensus',
      verifiedClaims: (json['verified_claims'] as List?)
              ?.map((c) => c.toString())
              .toList() ??
          [],
      unsupportedOrFlaggedClaims: (json['unsupported_or_flagged_claims'] as List?)
              ?.map((u) => u.toString())
              .toList() ??
          [],
      telemetryConflictNotes: json['telemetry_conflict_notes']?.toString(),
      confidenceLevel: (json['confidence_level'] is num)
          ? (json['confidence_level'] as num).toDouble()
          : 0.94,
    );
  }
}

class SupplyChainImpactModel {
  final List<Map<String, dynamic>> affectedFacilities;
  final List<String> criticalCommodities;
  final List<String> logisticsCorridors;
  final String physicalBottleneckDescription;
  final List<String> adaptationRecommendations;

  const SupplyChainImpactModel({
    this.affectedFacilities = const [],
    this.criticalCommodities = const [],
    this.logisticsCorridors = const [],
    required this.physicalBottleneckDescription,
    this.adaptationRecommendations = const [],
  });

  factory SupplyChainImpactModel.fromJson(Map<String, dynamic> json) {
    return SupplyChainImpactModel(
      affectedFacilities: (json['affected_facilities'] as List?)
              ?.map((f) => f as Map<String, dynamic>)
              .toList() ??
          [],
      criticalCommodities: (json['critical_commodities'] as List?)
              ?.map((c) => c.toString())
              .toList() ??
          [],
      logisticsCorridors: (json['logistics_corridors'] as List?)
              ?.map((l) => l.toString())
              .toList() ??
          [],
      physicalBottleneckDescription: json['physical_bottleneck_description']?.toString() ?? '',
      adaptationRecommendations: (json['adaptation_recommendations'] as List?)
              ?.map((a) => a.toString())
              .toList() ??
          [],
    );
  }
}

class InvestigationResult {
  final String investigationId;
  final String portfolioId;
  final String hazardEventId;
  final String hazardTitle;
  final String hazardDescription;
  final String? riskSummary;
  final double estimatedPortfolioImpactPct;
  final double confidenceScore;
  final List<double> uncertaintyRangePct;
  final List<EvidenceItemModel> evidenceItems;
  final List<ImpactedHoldingModel> impactedHoldings;
  final List<List<String>> graphPropagationPaths;
  final List<MitigationRecommendationModel> mitigationRecommendations;
  final Map<String, dynamic>? mitigationComparisons;
  final String status;
  final bool isModelledData;
  final String? modelType;
  final String? fallbackLabel;

  // Multi-Agent Findings
  final List<AgentExecutionStepModel> agentTimeline;
  final ClimateIntelligenceModel? climateIntelligence;
  final ScenarioAnalysisModel? scenarioAnalysis;
  final VerificationReportModel? verificationReport;
  final SupplyChainImpactModel? supplyChainImpact;
  final Map<String, dynamic>? riskEngineResult;

  const InvestigationResult({
    required this.investigationId,
    required this.portfolioId,
    required this.hazardEventId,
    required this.hazardTitle,
    required this.hazardDescription,
    this.riskSummary,
    required this.estimatedPortfolioImpactPct,
    this.confidenceScore = 0.88,
    this.uncertaintyRangePct = const [-5.8, -3.1],
    this.evidenceItems = const [],
    this.impactedHoldings = const [],
    this.graphPropagationPaths = const [],
    this.mitigationRecommendations = const [],
    this.mitigationComparisons,
    this.status = 'completed',
    this.isModelledData = true,
    this.modelType,
    this.fallbackLabel,
    this.agentTimeline = const [],
    this.climateIntelligence,
    this.scenarioAnalysis,
    this.verificationReport,
    this.supplyChainImpact,
    this.riskEngineResult,
  });

  factory InvestigationResult.fromJson(Map<String, dynamic> json) {
    final evidenceList = (json['evidence_items'] as List?)
            ?.map((e) => EvidenceItemModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final holdingsList = (json['impacted_holdings'] as List?)
            ?.map((e) => ImpactedHoldingModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final pathsList = (json['graph_propagation_paths'] as List?)
            ?.map((p) => (p as List).map((node) => node.toString()).toList())
            .toList() ??
        [];

    final mitigationsList = (json['mitigation_recommendations'] as List?)
            ?.map((m) =>
                MitigationRecommendationModel.fromJson(m as Map<String, dynamic>))
            .toList() ??
        [];

    final uncertainty = (json['uncertainty_range_pct'] as List?)
            ?.map((u) => (u as num).toDouble())
            .toList() ??
        [-5.8, -3.1];

    final timelineList = (json['agent_timeline'] as List?)
            ?.map((t) => AgentExecutionStepModel.fromJson(t as Map<String, dynamic>))
            .toList() ??
        [];

    return InvestigationResult(
      investigationId: json['investigation_id']?.toString() ?? '',
      portfolioId: json['portfolio_id']?.toString() ?? '',
      hazardEventId: json['hazard_event_id']?.toString() ?? '',
      hazardTitle: json['hazard_title']?.toString() ?? 'Hazard Event',
      hazardDescription: json['hazard_description']?.toString() ?? '',
      riskSummary: json['risk_summary']?.toString(),
      estimatedPortfolioImpactPct: (json['estimated_portfolio_impact_pct'] is num)
          ? (json['estimated_portfolio_impact_pct'] as num).toDouble()
          : 0.0,
      confidenceScore: (json['confidence_score'] is num)
          ? (json['confidence_score'] as num).toDouble()
          : 0.88,
      uncertaintyRangePct: uncertainty,
      evidenceItems: evidenceList,
      impactedHoldings: holdingsList,
      graphPropagationPaths: pathsList,
      mitigationRecommendations: mitigationsList,
      mitigationComparisons: json['mitigation_comparisons'] as Map<String, dynamic>?,
      status: json['status']?.toString() ?? 'completed',
      isModelledData: json['is_modelled_data'] != false,
      modelType: json['model_type']?.toString(),
      fallbackLabel: json['fallback_label']?.toString(),
      agentTimeline: timelineList,
      climateIntelligence: json['climate_intelligence'] != null
          ? ClimateIntelligenceModel.fromJson(json['climate_intelligence'] as Map<String, dynamic>)
          : null,
      scenarioAnalysis: json['scenario_analysis'] != null
          ? ScenarioAnalysisModel.fromJson(json['scenario_analysis'] as Map<String, dynamic>)
          : null,
      verificationReport: json['verification_report'] != null
          ? VerificationReportModel.fromJson(json['verification_report'] as Map<String, dynamic>)
          : null,
      supplyChainImpact: json['supply_chain_impact'] != null
          ? SupplyChainImpactModel.fromJson(json['supply_chain_impact'] as Map<String, dynamic>)
          : null,
      riskEngineResult: json['risk_engine_result'] as Map<String, dynamic>?,
    );
  }
}

class PhysicalRiskResult {
  final String calculationId;
  final String hazardId;
  final String hazardTitle;
  final String targetTicker;
  final String targetName;
  final String timestamp;
  final double hazardScore;
  final double exposureScore;
  final double vulnerabilityScore;
  final double compositeRiskScore;
  final String riskLevel;
  final double holdingWeight;
  final double baselineValueUsd;
  final double unmitigatedLossUsd;
  final double unmitigatedDrawdownPct;
  final double mitigatedLossUsd;
  final double mitigatedDrawdownPct;
  final double capitalPreservedUsd;
  final int tierDepth;
  final List<String> propagationPath;
  final String modelCalibrationStatus;
  final String? executiveSynthesis;
  final bool isModelledData;
  final Map<String, dynamic>? componentAttribution;
  final Map<String, dynamic>? calibrationMetadata;
  final Map<String, dynamic>? networkxPathExplanation;
  final Map<String, dynamic>? numericalDecomposition;
  final Map<String, dynamic>? sensitivityAnalysis;

  const PhysicalRiskResult({
    required this.calculationId,
    required this.hazardId,
    required this.hazardTitle,
    required this.targetTicker,
    required this.targetName,
    required this.timestamp,
    required this.hazardScore,
    required this.exposureScore,
    required this.vulnerabilityScore,
    required this.compositeRiskScore,
    required this.riskLevel,
    required this.holdingWeight,
    required this.baselineValueUsd,
    required this.unmitigatedLossUsd,
    required this.unmitigatedDrawdownPct,
    required this.mitigatedLossUsd,
    required this.mitigatedDrawdownPct,
    required this.capitalPreservedUsd,
    required this.tierDepth,
    required this.propagationPath,
    this.modelCalibrationStatus = 'provisional_engineering_model',
    this.executiveSynthesis,
    this.isModelledData = false,
    this.componentAttribution,
    this.calibrationMetadata,
    this.networkxPathExplanation,
    this.numericalDecomposition,
    this.sensitivityAnalysis,
  });

  factory PhysicalRiskResult.fromJson(Map<String, dynamic> json) {
    final path = (json['propagation_path'] as List?)
            ?.map((p) => p.toString())
            .toList() ??
        [];

    return PhysicalRiskResult(
      calculationId: json['calculation_id']?.toString() ?? '',
      hazardId: json['hazard_id']?.toString() ?? '',
      hazardTitle: json['hazard_title']?.toString() ?? '',
      targetTicker: json['target_ticker']?.toString() ?? '',
      targetName: json['target_name']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
      hazardScore: (json['hazard_score'] is num) ? (json['hazard_score'] as num).toDouble() : 0.0,
      exposureScore: (json['exposure_score'] is num) ? (json['exposure_score'] as num).toDouble() : 0.0,
      vulnerabilityScore: (json['vulnerability_score'] is num) ? (json['vulnerability_score'] as num).toDouble() : 0.0,
      compositeRiskScore: (json['composite_risk_score'] is num) ? (json['composite_risk_score'] as num).toDouble() : 0.0,
      riskLevel: json['risk_level']?.toString() ?? 'medium',
      holdingWeight: (json['holding_weight'] is num) ? (json['holding_weight'] as num).toDouble() : 0.0,
      baselineValueUsd: (json['baseline_value_usd'] is num) ? (json['baseline_value_usd'] as num).toDouble() : 0.0,
      unmitigatedLossUsd: (json['unmitigated_loss_usd'] is num) ? (json['unmitigated_loss_usd'] as num).toDouble() : 0.0,
      unmitigatedDrawdownPct: (json['unmitigated_drawdown_pct'] is num) ? (json['unmitigated_drawdown_pct'] as num).toDouble() : 0.0,
      mitigatedLossUsd: (json['mitigated_loss_usd'] is num) ? (json['mitigated_loss_usd'] as num).toDouble() : 0.0,
      mitigatedDrawdownPct: (json['mitigated_drawdown_pct'] is num) ? (json['mitigated_drawdown_pct'] as num).toDouble() : 0.0,
      capitalPreservedUsd: (json['capital_preserved_usd'] is num) ? (json['capital_preserved_usd'] as num).toDouble() : 0.0,
      tierDepth: (json['tier_depth'] is int) ? json['tier_depth'] as int : 1,
      propagationPath: path,
      modelCalibrationStatus: json['model_calibration_status']?.toString() ?? 'provisional_engineering_model',
      executiveSynthesis: json['executive_synthesis']?.toString(),
      isModelledData: json['is_modelled_data'] == true,
      componentAttribution: json['component_attribution'] as Map<String, dynamic>?,
      calibrationMetadata: json['calibration_metadata'] as Map<String, dynamic>?,
      networkxPathExplanation: json['networkx_path_explanation'] as Map<String, dynamic>?,
      numericalDecomposition: json['numerical_decomposition'] as Map<String, dynamic>?,
      sensitivityAnalysis: json['sensitivity_analysis'] as Map<String, dynamic>?,
    );
  }
}
