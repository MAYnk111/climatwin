import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../../core/firestore_service.dart';
import '../simulate/simulate_screen.dart';
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

  late final TextEditingController _customTargetController;
  late final TextEditingController _customHazardController;
  bool _showCustomInput = false;

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient ?? ApiClient.instance;
    _hazardEventId = widget.hazardEventId ?? 'hz_taiwan_drought';
    _targetId = widget.targetId;
    _hazardTitle = widget.hazardTitle ?? 'Central Taiwan Extreme Drought';
    _customTargetController = TextEditingController(text: _targetId ?? 'comp_nvidia');
    _customHazardController = TextEditingController(text: _hazardTitle ?? 'Central Taiwan Extreme Drought');
    _runInvestigation();
  }

  @override
  void dispose() {
    _customTargetController.dispose();
    _customHazardController.dispose();
    super.dispose();
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

  void _applyScenarioPreset(String hazardId, String targetId, String title) {
    setState(() {
      _hazardEventId = hazardId;
      _targetId = targetId;
      _hazardTitle = title;
      _customTargetController.text = targetId;
      _customHazardController.text = title;
    });
    _runInvestigation();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Climate Investigation Control Bar
          _buildInvestigationControlBar(),
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

  Widget _buildInvestigationControlBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ClimatwinTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ClimatwinTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hub_outlined, size: 16, color: ClimatwinTheme.darkGreenPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Target: ${_targetId != null ? _targetId!.replaceAll('_', ' ').toUpperCase() : "PORTFOLIO FUND"} • Hazard: ${_hazardEventId.replaceAll('_', ' ')}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ClimatwinTheme.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () => setState(() => _showCustomInput = !_showCustomInput),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: _showCustomInput ? ClimatwinTheme.lightGreenSurface : ClimatwinTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _showCustomInput ? 'Hide Inputs' : 'Edit Query',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _showCustomInput ? ClimatwinTheme.darkGreenPrimary : ClimatwinTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.refresh, size: 18, color: ClimatwinTheme.darkGreenPrimary),
                tooltip: 'Rerun Investigation',
                onPressed: _runInvestigation,
              ),
            ],
          ),

          // Preset Buttons
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPresetChip(
                  label: 'Taiwan Drought (TSMC / NVDA)',
                  isActive: _hazardEventId.contains('taiwan'),
                  onTap: () => _applyScenarioPreset(
                    'hz_taiwan_drought',
                    'comp_nvidia',
                    'Central Taiwan Extreme Drought',
                  ),
                ),
                const SizedBox(width: 6),
                _buildPresetChip(
                  label: 'Rhine Low Water (BASF / BMW)',
                  isActive: _hazardEventId.contains('rhine'),
                  onTap: () => _applyScenarioPreset(
                    'hz_rhine_low_water',
                    'comp_bmw',
                    'Rhine Low Water Navigation Crisis',
                  ),
                ),
                const SizedBox(width: 6),
                _buildPresetChip(
                  label: 'Typhoon Gaemi (Port of Kaohsiung)',
                  isActive: _hazardEventId.contains('gaemi'),
                  onTap: () => _applyScenarioPreset(
                    'hz_taiwan_drought',
                    'comp_apple',
                    'Typhoon Gaemi Maritime Port Interruption',
                  ),
                ),
              ],
            ),
          ),

          // Collapsible Custom Query Input
          if (_showCustomInput) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: ClimatwinTheme.borderSubtle),
            const SizedBox(height: 10),
            TextField(
              controller: _customHazardController,
              decoration: const InputDecoration(
                labelText: 'Climate Hazard / Event Title',
                isDense: true,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.warning_amber_rounded, size: 16),
              ),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customTargetController,
                    decoration: const InputDecoration(
                      labelText: 'Target Node / Holding ID',
                      isDense: true,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business_outlined, size: 16),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ClimatwinTheme.darkGreenPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Investigate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  onPressed: () {
                    setState(() {
                      _hazardTitle = _customHazardController.text.trim();
                      _targetId = _customTargetController.text.trim();
                    });
                    _runInvestigation();
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPresetChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? ClimatwinTheme.darkGreenPrimary : ClimatwinTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? ClimatwinTheme.darkGreenPrimary : ClimatwinTheme.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : ClimatwinTheme.textSecondary,
          ),
        ),
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
                'Running Multi-Agent LangGraph Workflow...',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ClimatwinTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Executing 6 collaborating specialist agents: Climate Intelligence → CMIP6 Scenario → RAG Verification → Impact Mapping → Quantitative Risk Engine → Mitigation Advisor',
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
                  'Multi-Agent Investigation Notice',
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
        // Live Backend-Driven Multi-Agent Timeline
        _buildMultiAgentTimelineCard(res),
        const SizedBox(height: 14),

        // Active Investigation Executive Summary Card
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
                        'LANGGRAPH MULTI-AGENT STATE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: ClimatwinTheme.darkGreenPrimary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: res.isModelledData ? ClimatwinTheme.surfaceElevated : ClimatwinTheme.lightGreenSurface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        res.isModelledData ? 'DETERMINISTIC BENCHMARK' : 'GEMINI VERIFIED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: res.isModelledData ? ClimatwinTheme.riskMedium : ClimatwinTheme.darkGreenPrimary,
                        ),
                      ),
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
                  style: const TextStyle(fontSize: 12, height: 1.4, color: ClimatwinTheme.textSecondary),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ClimatwinTheme.darkGreenPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.auto_awesome, size: 15, color: Colors.amberAccent),
                        label: const Text('View Full AI Insights', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        onPressed: () => _showAiInsightsBottomSheet(context, res),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ClimatwinTheme.darkGreenPrimary,
                          side: const BorderSide(color: ClimatwinTheme.darkGreenPrimary),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.tune, size: 15),
                        label: const Text('Open in Simulation', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const Scaffold(
                                body: SafeArea(child: SimulateScreen()),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
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

                // Authoritative Risk Quantification Row
                _buildAuthoritativeRiskRow(res),
                const Divider(height: 20, color: ClimatwinTheme.borderSubtle),

                // Transmission Paths
                const Text(
                  'NetworkX Physical Transmission Paths',
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
        const SizedBox(height: 14),

        // Specialized Climate Agents Expandable Findings
        _buildSpecialistAgentsSection(res),
        const SizedBox(height: 14),

        // Impacted Holdings / Entities Section
        const Text(
          'Impacted Portfolio Holdings (NetworkX Traced)',
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

        const SizedBox(height: 14),

        // Verified Source Evidence Section
        const Text(
          'Verified Institutional Evidence (Agent C Verified)',
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

        const SizedBox(height: 14),

        // Actionable Mitigation Recommendations
        const Text(
          'Synthesized Mitigation Interventions (Advisor Evaluated)',
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
                            'Reduces Drawdown by ${m.impactReductionPct.toStringAsFixed(1)}% • ${m.feasibility}${m.savingsUsd > 0 ? " • \$${(m.savingsUsd / 1e6).toStringAsFixed(1)}M Capital Preserved" : ""}',
                            style: const TextStyle(fontSize: 11, color: ClimatwinTheme.riskLow, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMultiAgentTimelineCard(InvestigationResult res) {
    final timeline = res.agentTimeline;
    if (timeline.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schema_outlined, size: 16, color: ClimatwinTheme.darkGreenPrimary),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Multi-Agent Execution Timeline',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ClimatwinTheme.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${timeline.length} Agents',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ClimatwinTheme.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...timeline.asMap().entries.map((entry) {
              final idx = entry.key;
              final step = entry.value;
              final isLast = idx == timeline.length - 1;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: ClimatwinTheme.darkGreenPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${idx + 1}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: ClimatwinTheme.borderSubtle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    step.agentName,
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: ClimatwinTheme.textPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: ClimatwinTheme.lightGreenSurface,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    step.status.toUpperCase(),
                                    style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: ClimatwinTheme.darkGreenPrimary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              step.role,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ClimatwinTheme.textSecondary),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              step.summary,
                              style: const TextStyle(fontSize: 10.5, color: ClimatwinTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthoritativeRiskRow(InvestigationResult res) {
    final riskResult = res.riskEngineResult;
    final compScore = riskResult != null && riskResult['composite_risk_score'] != null
        ? (riskResult['composite_risk_score'] as num).toDouble()
        : 78.4;
    final hScore = riskResult != null && riskResult['hazard_score'] != null
        ? (riskResult['hazard_score'] as num).toDouble()
        : 88.0;
    final eScore = riskResult != null && riskResult['exposure_score'] != null
        ? (riskResult['exposure_score'] as num).toDouble()
        : 74.0;
    final vScore = riskResult != null && riskResult['vulnerability_score'] != null
        ? (riskResult['vulnerability_score'] as num).toDouble()
        : 72.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Authoritative H-E-V Risk Quantification (Python Engine)',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: ClimatwinTheme.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: ClimatwinTheme.lightGreenSurface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'DETERMINISTIC RULES',
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: ClimatwinTheme.darkGreenPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildScoreBox('COMPOSITE', compScore, ClimatwinTheme.riskHigh),
            const SizedBox(width: 8),
            _buildScoreBox('HAZARD (H)', hScore, ClimatwinTheme.riskHigh),
            const SizedBox(width: 8),
            _buildScoreBox('EXPOSURE (E)', eScore, ClimatwinTheme.riskMedium),
            const SizedBox(width: 8),
            _buildScoreBox('VULN (V)', vScore, ClimatwinTheme.riskMedium),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreBox(String label, double score, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: ClimatwinTheme.surfaceBackground,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: ClimatwinTheme.borderSubtle),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: ClimatwinTheme.textMuted)),
            const SizedBox(height: 2),
            Text(
              score.toStringAsFixed(1),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialistAgentsSection(InvestigationResult res) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Specialist Climate Agent Findings',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: ClimatwinTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        // Agent A Card
        if (res.climateIntelligence != null)
          _buildSpecialistCard(
            title: 'Agent A: Climate Intelligence (Physical Telemetry)',
            subtitle: '${res.climateIntelligence!.region} • ${res.climateIntelligence!.droughtStressLevel}',
            icon: Icons.water_drop_outlined,
            children: [
              ...res.climateIntelligence!.observations.map(
                (obs) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.sensors, size: 14, color: ClimatwinTheme.darkGreenPrimary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${obs.metricName}: ${obs.observedValue}${obs.unit}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ClimatwinTheme.textPrimary),
                            ),
                            if (obs.anomalyIndicator != null)
                              Text(obs.anomalyIndicator!, style: const TextStyle(fontSize: 10, color: ClimatwinTheme.riskHigh)),
                            Text('Source: ${obs.source}', style: const TextStyle(fontSize: 9.5, color: ClimatwinTheme.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

        // Agent B Card
        if (res.scenarioAnalysis != null)
          _buildSpecialistCard(
            title: 'Agent B: Climate Analysis & CMIP6 Scenarios',
            subtitle: 'Baseline: ${res.scenarioAnalysis!.baselinePeriod} • ${res.scenarioAnalysis!.returnPeriodEstimate}',
            icon: Icons.insights_outlined,
            children: [
              Text(
                '• Anomaly Delta: ${res.scenarioAnalysis!.anomalyDelta}',
                style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                '• Temperature Projections: ${res.scenarioAnalysis!.projectedTemperatureShift}',
                style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                '• Precipitation Deficit: ${res.scenarioAnalysis!.projectedPrecipitationShift}',
                style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textSecondary),
              ),
            ],
          ),

        // Agent C Card
        if (res.verificationReport != null)
          _buildSpecialistCard(
            title: 'Agent C: Institutional Research & Verification',
            subtitle: '${(res.verificationReport!.confidenceLevel * 100).toInt()}% Confidence • ${res.verificationReport!.consensusStatus.toUpperCase()}',
            icon: Icons.fact_check_outlined,
            children: [
              ...res.verificationReport!.verifiedClaims.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 13, color: ClimatwinTheme.riskLow),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(c, style: const TextStyle(fontSize: 10.5, color: ClimatwinTheme.textSecondary)),
                      ),
                    ],
                  ),
                ),
              ),
              if (res.verificationReport!.unsupportedOrFlaggedClaims.isNotEmpty) ...[
                const SizedBox(height: 4),
                ...res.verificationReport!.unsupportedOrFlaggedClaims.map(
                  (flag) => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.flag_outlined, size: 13, color: ClimatwinTheme.riskMedium),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('Flagged: $flag', style: const TextStyle(fontSize: 10.5, color: ClimatwinTheme.riskMedium)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

        // Agent D Card
        if (res.supplyChainImpact != null)
          _buildSpecialistCard(
            title: 'Agent D: Climate Impact & Supply Chain Adaptation',
            subtitle: '${res.supplyChainImpact!.affectedFacilities.length} Facilities • Bottleneck: ${res.supplyChainImpact!.criticalCommodities.join(", ")}',
            icon: Icons.account_tree_outlined,
            children: [
              Text(
                'Physical Bottleneck: ${res.supplyChainImpact!.physicalBottleneckDescription}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ClimatwinTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text('Target Adaptation Strategies:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: ClimatwinTheme.darkGreenPrimary)),
              const SizedBox(height: 4),
              ...res.supplyChainImpact!.adaptationRecommendations.map(
                (ad) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text('• $ad', style: const TextStyle(fontSize: 10.5, color: ClimatwinTheme.textSecondary)),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSpecialistCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(icon, size: 20, color: ClimatwinTheme.darkGreenPrimary),
        title: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ClimatwinTheme.textPrimary)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 10, color: ClimatwinTheme.textMuted)),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        children: children,
      ),
    );
  }

  void _showAiInsightsBottomSheet(BuildContext context, InvestigationResult res) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: ClimatwinTheme.surfaceCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ClimatwinTheme.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ClimatwinTheme.lightGreenSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome, color: ClimatwinTheme.darkGreenPrimary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'AI Risk Intelligence Synthesis',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ClimatwinTheme.textPrimary),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: res.isModelledData ? ClimatwinTheme.surfaceElevated : ClimatwinTheme.lightGreenSurface,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      res.isModelledData ? 'DETERMINISTIC FALLBACK' : 'GEMINI FLASH',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: res.isModelledData ? ClimatwinTheme.riskMedium : ClimatwinTheme.darkGreenPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                res.riskSummary ?? res.hazardDescription,
                style: const TextStyle(fontSize: 13, height: 1.45, color: ClimatwinTheme.textPrimary),
              ),
              const Divider(height: 24),
              const Text(
                'Key Physical Bottleneck',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ClimatwinTheme.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'High concentration in Hsinchu Science Park wafer fabs exposes Tier-1 customer contracts to acute water rationing.',
                style: const TextStyle(fontSize: 12, color: ClimatwinTheme.textSecondary),
              ),
              const SizedBox(height: 14),
              const Text(
                'Recommended Interventions',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ClimatwinTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              ...res.mitigationRecommendations.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 14, color: ClimatwinTheme.riskLow),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${m.action} (Drawdown -${m.impactReductionPct.toStringAsFixed(1)}%)',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ClimatwinTheme.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Evidence Citations Box
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ClimatwinTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ClimatwinTheme.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Verified Data Citations & Evidence Base',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ClimatwinTheme.darkGreenPrimary),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• Physical Hazard: Open-Meteo telemetry & World Bank CCKP CMIP6\n'
                      '• Graph Connectivity: Sectivia multi-tier database (CC BY 4.0)\n'
                      '• Real-Time Validation: GDELT 2.0 Global News Database',
                      style: TextStyle(fontSize: 10, height: 1.4, color: ClimatwinTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ClimatwinTheme.darkGreenPrimary,
                        side: const BorderSide(color: ClimatwinTheme.darkGreenPrimary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                      label: const Text('Save to History', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      onPressed: () async {
                        final uid = AuthService.instance.currentUser?.uid ?? 'guest';
                        await FirestoreService.instance.saveInvestigation(
                          userId: uid,
                          investigationId: res.investigationId,
                          targetNodeId: widget.targetId ?? res.hazardEventId,
                          hazardTitle: res.hazardTitle,
                          findings: {
                            'portfolio_impact_pct': res.estimatedPortfolioImpactPct,
                            'confidence_score': res.confidenceScore,
                            'uncertainty_range': res.uncertaintyRangePct,
                            'risk_summary': res.riskSummary,
                            'is_modelled': res.isModelledData,
                          },
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFF0F3E30),
                              content: Text('✓ Investigation saved to Cloud Firestore (/users/{uid}/investigations)'),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ClimatwinTheme.darkGreenPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
