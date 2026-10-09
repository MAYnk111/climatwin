import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import 'intelligence_models.dart';

class IntelligenceScreen extends StatefulWidget {
  final ApiClient? apiClient;
  final String? targetId;
  final String? hazardEventId;
  final String? hazardTitle;
  final String? hazardDescription;
  final Map<String, dynamic>? graphContext;

  const IntelligenceScreen({
    super.key,
    this.apiClient,
    this.targetId,
    this.hazardEventId,
    this.hazardTitle,
    this.hazardDescription,
    this.graphContext,
  });

  @override
  State<IntelligenceScreen> createState() => _IntelligenceScreenState();
}

class _IntelligenceScreenState extends State<IntelligenceScreen> {
  late final ApiClient _apiClient;
  InvestigationResult? _investigationResult;
  bool _isLoading = false;
  String? _errorMessage;

  late String _hazardEventId;
  String? _targetId;
  String? _hazardTitle;

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient ?? ApiClient.instance;
    _hazardEventId = widget.hazardEventId ?? 'hz_taiwan_drought';
    _targetId = widget.targetId;
    _hazardTitle = widget.hazardTitle ?? 'Central Taiwan Extreme Drought';
    _runInvestigation();
  }

  Future<void> _runInvestigation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiClient.runInvestigation(
        hazardEventId: _hazardEventId,
        targetId: _targetId,
        hazardTitle: _hazardTitle,
        hazardDescription: widget.hazardDescription,
        graphContext: widget.graphContext,
      );

      if (mounted) {
        setState(() {
          _investigationResult = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e is ApiException
              ? e.message
              : 'Failed to run investigation on backend: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter / Context Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: ClimatwinTheme.surfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ClimatwinTheme.borderSubtle),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, size: 16, color: ClimatwinTheme.darkGreenPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Target: ${_targetId != null ? _targetId!.replaceAll('_', ' ').toUpperCase() : "PORTFOLIO FUND"} • Hazard: ${_hazardEventId.replaceAll('_', ' ')}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ClimatwinTheme.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18, color: ClimatwinTheme.darkGreenPrimary),
                  tooltip: 'Rerun Investigation',
                  onPressed: _runInvestigation,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (_isLoading)
            _buildLoadingCard()
          else if (_errorMessage != null)
            _buildErrorCard()
          else if (_investigationResult != null)
            _buildResultContent(_investigationResult!),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Center(
          child: Column(
            children: [
              const CircularProgressIndicator(
                strokeWidth: 2.5,
                color: ClimatwinTheme.darkGreenPrimary,
              ),
              const SizedBox(height: 16),
              const Text(
                'Running LangGraph Risk Investigation...',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ClimatwinTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Traversing NetworkX dependency graph and synthesizing evidence from ${_apiClient.baseUrl}',
                style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: ClimatwinTheme.riskHigh, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Agent Investigation Failed',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ClimatwinTheme.riskHigh),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: ClimatwinTheme.darkGreenPrimary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry Investigation'),
              onPressed: _runInvestigation,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultContent(InvestigationResult res) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Active Investigation Card
        Card(
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: ClimatwinTheme.darkGreenPrimary, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: ClimatwinTheme.lightGreenSurface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'LANGGRAPH AGENT WORKFLOW',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: ClimatwinTheme.darkGreenPrimary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.check_circle_outline, size: 14, color: ClimatwinTheme.riskLow),
                    const SizedBox(width: 4),
                    const Text(
                      'LangSmith Traced',
                      style: TextStyle(fontSize: 10, color: ClimatwinTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  res.hazardTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ClimatwinTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  res.riskSummary ?? res.hazardDescription,
                  style: const TextStyle(fontSize: 12, color: ClimatwinTheme.textSecondary),
                ),
                const Divider(height: 20, color: ClimatwinTheme.borderSubtle),

                // Uncertainty and Portfolio Shock Metrics
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Estimated Portfolio Shock', style: TextStyle(fontSize: 10, color: ClimatwinTheme.textMuted)),
                          const SizedBox(height: 2),
                          Text(
                            '${res.estimatedPortfolioImpactPct.toStringAsFixed(1)}%',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ClimatwinTheme.riskHigh),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Agent Confidence Score', style: TextStyle(fontSize: 10, color: ClimatwinTheme.textMuted)),
                          const SizedBox(height: 2),
                          Text(
                            '${(res.confidenceScore * 100).toInt()}%',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ClimatwinTheme.riskLow),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Uncertainty Range', style: TextStyle(fontSize: 10, color: ClimatwinTheme.textMuted)),
                          const SizedBox(height: 2),
                          Text(
                            '${res.uncertaintyRangePct.first}% to ${res.uncertaintyRangePct.last}%',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ClimatwinTheme.riskMedium),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20, color: ClimatwinTheme.borderSubtle),

                // Transmission Paths
                const Text(
                  'Active Graph Transmission Paths',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ClimatwinTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                if (res.graphPropagationPaths.isEmpty)
                  const Text('No direct transmission path discovered.', style: TextStyle(fontSize: 11, color: ClimatwinTheme.textMuted))
                else
                  ...res.graphPropagationPaths.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: ClimatwinTheme.surfaceBackground,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: ClimatwinTheme.borderSubtle),
                          ),
                          child: Text(
                            p.map((node) => node.replaceAll('hz_', '').replaceAll('comp_', '').replaceAll('sup_', '').replaceAll('fac_', '').replaceAll('reg_', '')).join(' → '),
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: ClimatwinTheme.textPrimary),
                          ),
                        ),
                      )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Impacted Holdings / Entities Section
        const Text(
          'Impacted Portfolio Holdings',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: ClimatwinTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        ...res.impactedHoldings.map((h) => Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: ClimatwinTheme.surfaceBackground,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: ClimatwinTheme.borderSubtle),
                      ),
                      child: Text(
                        h.ticker,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(h.holdingName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text(
                            'Weight: ${(h.weight * 100).toStringAsFixed(1)}% • Tier-${h.tierExposure} Supplier Exposure',
                            style: const TextStyle(fontSize: 10, color: ClimatwinTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: ClimatwinTheme.riskHigh.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'HIGH RISK',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: ClimatwinTheme.riskHigh),
                      ),
                    ),
                  ],
                ),
              ),
            )),

        const SizedBox(height: 16),

        // Verified Source Evidence Section
        const Text(
          'Verified Source Evidence (LangGraph Extracted)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: ClimatwinTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        ...res.evidenceItems.map((e) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified, size: 14, color: ClimatwinTheme.darkGreenPrimary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            e.sourceName,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ClimatwinTheme.darkGreenPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${(e.reliabilityScore * 100).toInt()}% Confidence',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ClimatwinTheme.riskLow),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      e.title,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ClimatwinTheme.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      e.snippet,
                      style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      e.timestamp,
                      style: const TextStyle(fontSize: 9, color: ClimatwinTheme.textMuted),
                    ),
                  ],
                ),
              ),
            )),

        const SizedBox(height: 16),

        // Actionable Mitigation Recommendations
        const Text(
          'Synthesized Mitigation Actions',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: ClimatwinTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        ...res.mitigationRecommendations.map((m) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ClimatwinTheme.lightGreenSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.shield_outlined, size: 18, color: ClimatwinTheme.darkGreenPrimary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.action,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ClimatwinTheme.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Reduces Drawdown by ${m.impactReductionPct.toStringAsFixed(1)}% • ${m.feasibility}',
                            style: const TextStyle(fontSize: 11, color: ClimatwinTheme.riskLow, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}
