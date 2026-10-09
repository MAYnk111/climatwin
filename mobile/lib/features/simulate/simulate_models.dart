class HoldingStressedModel {
  final String ticker;
  final String name;
  final double baselineValueUsd;
  final stressedValueUsd;
  final double lossUsd;
  final double drawdownPct;
  final double mitigationSavingsUsd;

  const HoldingStressedModel({
    required this.ticker,
    required this.name,
    required this.baselineValueUsd,
    required this.stressedValueUsd,
    required this.lossUsd,
    required this.drawdownPct,
    this.mitigationSavingsUsd = 0.0,
  });

  factory HoldingStressedModel.fromJson(Map<String, dynamic> json) {
    return HoldingStressedModel(
      ticker: json['ticker']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      baselineValueUsd: (json['baseline_value_usd'] is num)
          ? (json['baseline_value_usd'] as num).toDouble()
          : 0.0,
      stressedValueUsd: (json['stressed_value_usd'] is num)
          ? (json['stressed_value_usd'] as num).toDouble()
          : 0.0,
      lossUsd: (json['loss_usd'] is num) ? (json['loss_usd'] as num).toDouble() : 0.0,
      drawdownPct: (json['drawdown_pct'] is num)
          ? (json['drawdown_pct'] as num).toDouble()
          : 0.0,
      mitigationSavingsUsd: (json['mitigation_savings_usd'] is num)
          ? (json['mitigation_savings_usd'] as num).toDouble()
          : 0.0,
    );
  }
}

class SimulationResult {
  final String scenarioId;
  final String scenarioName;
  final double baselineTotalAum;
  final double stressedTotalAum;
  final double netPortfolioLossUsd;
  final double portfolioDrawdownPct;
  final List<HoldingStressedModel> stressedHoldings;
  final Map<String, double> branchComparison;
  final bool isModelledData;

  const SimulationResult({
    required this.scenarioId,
    required this.scenarioName,
    required this.baselineTotalAum,
    required this.stressedTotalAum,
    required this.netPortfolioLossUsd,
    required this.portfolioDrawdownPct,
    required this.stressedHoldings,
    this.branchComparison = const {},
    this.isModelledData = true,
  });

  factory SimulationResult.fromJson(Map<String, dynamic> json) {
    final holdings = (json['stressed_holdings'] as List?)
            ?.map((h) => HoldingStressedModel.fromJson(h as Map<String, dynamic>))
            .toList() ??
        [];

    final branches = <String, double>{};
    if (json['branch_comparison'] is Map) {
      (json['branch_comparison'] as Map).forEach((k, v) {
        if (v is num) {
          branches[k.toString()] = v.toDouble();
        }
      });
    }

    return SimulationResult(
      scenarioId: json['scenario_id']?.toString() ?? '',
      scenarioName: json['scenario_name']?.toString() ?? 'Climate Stress Test',
      baselineTotalAum: (json['baseline_total_aum'] is num)
          ? (json['baseline_total_aum'] as num).toDouble()
          : 0.0,
      stressedTotalAum: (json['stressed_total_aum'] is num)
          ? (json['stressed_total_aum'] as num).toDouble()
          : 0.0,
      netPortfolioLossUsd: (json['net_portfolio_loss_usd'] is num)
          ? (json['net_portfolio_loss_usd'] as num).toDouble()
          : 0.0,
      portfolioDrawdownPct: (json['portfolio_drawdown_pct'] is num)
          ? (json['portfolio_drawdown_pct'] as num).toDouble()
          : 0.0,
      stressedHoldings: holdings,
      branchComparison: branches,
      isModelledData: json['is_modelled_data'] != false,
    );
  }
}
