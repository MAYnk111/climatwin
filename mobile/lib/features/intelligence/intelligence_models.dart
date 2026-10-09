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

  const MitigationRecommendationModel({
    required this.action,
    required this.impactReductionPct,
    required this.feasibility,
  });

  factory MitigationRecommendationModel.fromJson(Map<String, dynamic> json) {
    return MitigationRecommendationModel(
      action: json['action']?.toString() ?? '',
      impactReductionPct: (json['impact_reduction_pct'] is num)
          ? (json['impact_reduction_pct'] as num).toDouble()
          : 0.0,
      feasibility: json['feasibility']?.toString() ?? 'Feasible',
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
  final String status;
  final bool isModelledData;

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
    this.status = 'completed',
    this.isModelledData = true,
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
      status: json['status']?.toString() ?? 'completed',
      isModelledData: json['is_modelled_data'] != false,
    );
  }
}
