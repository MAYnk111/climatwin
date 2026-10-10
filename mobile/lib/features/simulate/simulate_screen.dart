import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/currency_utils.dart';
import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../../core/firestore_service.dart';
import 'simulate_models.dart';

class SimulateScreen extends StatefulWidget {
  final ApiClient? apiClient;
  final String? initialTargetId;

  const SimulateScreen({super.key, this.apiClient, this.initialTargetId});

  @override
  State<SimulateScreen> createState() => _SimulateScreenState();
}

class _SimulateScreenState extends State<SimulateScreen> {
  late final ApiClient _apiClient;

  // Step 1: Target Selection
  String _selectedTarget = 'Global Tech & Semiconductor Portfolio';
  final List<String> _targetOptions = [
    'Global Tech & Semiconductor Portfolio',
    'NVIDIA Tier-1 Supply Chain',
    'Taiwan Foundry Corridor (TSMC)',
    'Automotive & Rhine Logistics (BMW)',
  ];

  // Step 2: Hazard Severity & Duration
  double _severityMultiplier = 1.8;
  int _durationMonths = 4;

  // Step 3: Mitigation Strategies
  bool _adaptationActive = true;
  bool _alternativeSupplierActive = true;

  // Step 4 & 5: Simulation Execution & Results
  SimulationResult? _simulationResult;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient ?? ApiClient.instance;
    _runSimulation();
  }

  Future<void> _runSimulation() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _apiClient.runSimulation(
        severityMultiplier: _severityMultiplier,
        durationMonths: _durationMonths,
        adaptationActive: _adaptationActive,
        alternativeSupplierActive: _alternativeSupplierActive,
      );

      if (mounted) {
        setState(() {
          _simulationResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e is ApiException
              ? e.message
              : 'Failed to execute simulation on backend: $e';
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
          // Step 1: Target Portfolio / Hazard Selection
          _buildStepCard(
            stepNumber: '1',
            title: 'Select Target Scope',
            subtitle: 'Choose portfolio, company, or supply chain corridor to stress-test',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedTarget,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  dropdownColor: ClimatwinTheme.surfaceElevated,
                  style: const TextStyle(fontSize: 13, color: ClimatwinTheme.textPrimary, fontWeight: FontWeight.w600),
                  items: _targetOptions.map((opt) {
                    return DropdownMenuItem(value: opt, child: Text(opt));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedTarget = val);
                      _runSimulation();
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Step 2: Hazard Severity & Duration Parameters
          _buildStepCard(
            stepNumber: '2',
            title: 'Adjust Hazard Severity & Duration',
            subtitle: 'Model physical climate shocks (drought, extreme heat, flood)',
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Hazard Severity Multiplier',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ClimatwinTheme.textPrimary)),
                    Text(
                      '${_severityMultiplier.toStringAsFixed(1)}x Baseline',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: ClimatwinTheme.darkGreenPrimary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _severityMultiplier,
                  min: 1.0,
                  max: 3.0,
                  divisions: 20,
                  activeColor: ClimatwinTheme.darkGreenPrimary,
                  inactiveColor: ClimatwinTheme.surfaceElevated,
                  onChanged: (val) => setState(() => _severityMultiplier = val),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Disruption Duration',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ClimatwinTheme.textPrimary)),
                    Text(
                      '$_durationMonths Months',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: ClimatwinTheme.darkGreenPrimary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _durationMonths.toDouble(),
                  min: 1,
                  max: 12,
                  divisions: 11,
                  activeColor: ClimatwinTheme.darkGreenPrimary,
                  inactiveColor: ClimatwinTheme.surfaceElevated,
                  onChanged: (val) => setState(() => _durationMonths = val.toInt()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Step 3: Mitigation Strategies
          _buildStepCard(
            stepNumber: '3',
            title: 'Toggle Mitigation Strategies',
            subtitle: 'Active adaptation dampens propagation loss and preserves AUM',
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Water Recycling & Site Adaptation',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ClimatwinTheme.textPrimary)),
                  subtitle: const Text('Reduces physical vulnerability shock by ~40%',
                      style: TextStyle(fontSize: 11, color: ClimatwinTheme.textSecondary)),
                  value: _adaptationActive,
                  activeColor: ClimatwinTheme.darkGreenPrimary,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setState(() => _adaptationActive = val),
                ),
                const Divider(height: 12),
                SwitchListTile(
                  title: const Text('Secondary Foundry Dual-Sourcing',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ClimatwinTheme.textPrimary)),
                  subtitle: const Text('Bypasses Tier-1 single-source bottlenecks by ~30%',
                      style: TextStyle(fontSize: 11, color: ClimatwinTheme.textSecondary)),
                  value: _alternativeSupplierActive,
                  activeColor: ClimatwinTheme.darkGreenPrimary,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setState(() => _alternativeSupplierActive = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Step 4: Run Simulation Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: ClimatwinTheme.darkGreenPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow, size: 20),
              label: Text(
                _isLoading ? 'Executing Stress Simulation...' : 'Execute Scenario Simulation',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              onPressed: _isLoading ? null : _runSimulation,
            ),
          ),
          const SizedBox(height: 16),

          // Step 5: Simulation Results Section
          if (_errorMessage != null)
            Card(
              color: ClimatwinTheme.surfaceElevated,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: ClimatwinTheme.riskHigh),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.error_outline, color: ClimatwinTheme.riskHigh, size: 20),
                        SizedBox(width: 8),
                        Text('Simulation Engine Error',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ClimatwinTheme.riskHigh)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(_errorMessage!, style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textSecondary)),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: ClimatwinTheme.darkGreenPrimary),
                      onPressed: _runSimulation,
                      child: const Text('Retry Execution'),
                    ),
                  ],
                ),
              ),
            )
          else if (_simulationResult != null)
            _buildResultsSection(_simulationResult!),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String stepNumber,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: ClimatwinTheme.darkGreenPrimary.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: ClimatwinTheme.darkGreenPrimary),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    stepNumber,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: ClimatwinTheme.darkGreenPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: ClimatwinTheme.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection(SimulationResult res) {
    // Standard conversion from USD to INR using CurrencyFormatter
    final double baselineInr = res.baselineTotalAum * CurrencyFormatter.usdToInrRate;
    final double stressedInr = res.stressedTotalAum * CurrencyFormatter.usdToInrRate;
    final double netLossInr = res.netPortfolioLossUsd * CurrencyFormatter.usdToInrRate;
    final double totalSavingsInr = res.stressedHoldings
            .fold(0.0, (acc, h) => acc + h.mitigationSavingsUsd) *
        CurrencyFormatter.usdToInrRate;

    final unmitigatedDrawdown = res.branchComparison['unmitigated_drawdown_pct'] ??
        res.portfolioDrawdownPct;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step 5 Header & Model Disclaimer Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Step 5: Impact & Savings Analysis',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: ClimatwinTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: ClimatwinTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: ClimatwinTheme.borderSubtle),
              ),
              child: const Text(
                'MODEL ESTIMATE',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: ClimatwinTheme.riskMedium),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Comparison Summary Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Baseline Portfolio Value',
                              style: TextStyle(fontSize: 11, color: ClimatwinTheme.textMuted)),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.formatInr(baselineInr),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: ClimatwinTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '\$${(res.baselineTotalAum / 1e6).toStringAsFixed(1)}M',
                            style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textMuted, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 48, color: ClimatwinTheme.borderSubtle),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Stressed Portfolio Value',
                              style: TextStyle(fontSize: 11, color: ClimatwinTheme.textMuted)),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.formatInr(stressedInr),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: ClimatwinTheme.riskHigh,
                            ),
                          ),
                          Text(
                            '\$${(res.stressedTotalAum / 1e6).toStringAsFixed(1)}M',
                            style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textMuted, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, color: ClimatwinTheme.borderSubtle),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Portfolio Drawdown',
                        style: TextStyle(fontSize: 12, color: ClimatwinTheme.textSecondary)),
                    Text(
                      '-${res.portfolioDrawdownPct.toStringAsFixed(2)}% (${CurrencyFormatter.formatInr(netLossInr)})',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: ClimatwinTheme.riskHigh,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Unmitigated Base Shock',
                        style: TextStyle(fontSize: 12, color: ClimatwinTheme.textSecondary)),
                    Text(
                      '-${unmitigatedDrawdown.toStringAsFixed(2)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ClimatwinTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Mitigation Capital Saved',
                        style: TextStyle(fontSize: 12, color: ClimatwinTheme.textSecondary)),
                    Text(
                      '+${CurrencyFormatter.formatInr(totalSavingsInr)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: ClimatwinTheme.riskLow,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Actions Row: Ask AI for Insights & Save Scenario
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: ClimatwinTheme.darkGreenPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.amberAccent),
              label: const Text('Ask AI for Insights', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              onPressed: () => _showSimulationAiInsights(context, res),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: ClimatwinTheme.textPrimary,
                side: const BorderSide(color: ClimatwinTheme.borderSubtle),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.cloud_upload_outlined, size: 16, color: ClimatwinTheme.darkGreenPrimary),
              label: const Text('Save Scenario', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              onPressed: () async {
                final uid = AuthService.instance.currentUser?.uid ?? 'default_analyst';
                await FirestoreService.instance.saveSimulationScenario(
                  userId: uid,
                  scenarioId: res.scenarioId,
                  scenarioName: res.scenarioName,
                  severityMultiplier: _severityMultiplier,
                  durationMonths: _durationMonths,
                  results: {
                    'baseline_aum_usd': res.baselineTotalAum,
                    'stressed_aum_usd': res.stressedTotalAum,
                    'portfolio_drawdown_pct': res.portfolioDrawdownPct,
                    'total_savings_inr': totalSavingsInr,
                  },
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Scenario saved to Cloud Firestore (/users/{uid}/scenarios)'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // FX & Model Assumptions Note
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ClimatwinTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ClimatwinTheme.borderSubtle),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: ClimatwinTheme.accentTeal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Simulation assumptions: Linear propagation with NetworkX graph dampening. Normalized at ${CurrencyFormatter.exchangeRateNote}.',
                  style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Stressed Holdings Breakdown
        const Text(
          'Holdings Stress Breakdown',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: ClimatwinTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        ...res.stressedHoldings.map((h) {
          final double baseHoldingInr = h.baselineValueUsd * CurrencyFormatter.usdToInrRate;
          final double lossHoldingInr = h.lossUsd * CurrencyFormatter.usdToInrRate;
          final double savingsHoldingInr = h.mitigationSavingsUsd * CurrencyFormatter.usdToInrRate;

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: ClimatwinTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: ClimatwinTheme.borderSubtle),
                      ),
                      child: Text(
                        h.ticker,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: ClimatwinTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            h.name,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ClimatwinTheme.textPrimary),
                          ),
                          Text(
                            'Saved: +${CurrencyFormatter.formatInr(savingsHoldingInr)} via dual-source',
                            style: const TextStyle(fontSize: 10, color: ClimatwinTheme.riskLow),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '-${CurrencyFormatter.formatInr(lossHoldingInr)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: ClimatwinTheme.riskHigh,
                          ),
                        ),
                        Text(
                          '${CurrencyFormatter.formatInr(baseHoldingInr)} (-${h.drawdownPct.toStringAsFixed(1)}%)',
                          style: const TextStyle(fontSize: 10, color: ClimatwinTheme.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showSimulationAiInsights(BuildContext context, SimulationResult res) {
    final double unmitigatedDrawdown = res.branchComparison['unmitigated_drawdown_pct'] ?? res.portfolioDrawdownPct;
    final double deltaSaved = (unmitigatedDrawdown - res.portfolioDrawdownPct).clamp(0.0, 100.0);
    final double totalSavingsUsd = res.stressedHoldings.fold(0.0, (acc, h) => acc + h.mitigationSavingsUsd);
    final double totalSavingsInr = totalSavingsUsd * CurrencyFormatter.usdToInrRate;

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
                      'AI Scenario Simulation Insights',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ClimatwinTheme.textPrimary),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: ClimatwinTheme.lightGreenSurface,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'ESTIMATE',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: ClimatwinTheme.darkGreenPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Under the simulated ${_severityMultiplier}x severity shock across ${_durationMonths} months, '
                'unmitigated portfolio drawdown would reach -${unmitigatedDrawdown.toStringAsFixed(1)}%. '
                'Pre-emptive dual-sourcing contracts and site adaptation buffers limit drawdown to -${res.portfolioDrawdownPct.toStringAsFixed(1)}%, '
                'preserving ${CurrencyFormatter.formatInr(totalSavingsInr)} (\$${(totalSavingsUsd / 1e6).toStringAsFixed(1)}M USD) in portfolio equity.',
                style: const TextStyle(fontSize: 13, height: 1.45, color: ClimatwinTheme.textPrimary),
              ),
              const Divider(height: 24),
              const Text(
                'Branch Delta Breakdown',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ClimatwinTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              _buildInsightRow(
                icon: Icons.shield_outlined,
                title: 'Combined Mitigation Savings',
                value: '+${deltaSaved.toStringAsFixed(1)}% Protected',
                color: ClimatwinTheme.riskLow,
              ),
              const SizedBox(height: 6),
              _buildInsightRow(
                icon: Icons.alt_route,
                title: 'Dual-Sourcing Foundry Hedge',
                value: _alternativeSupplierActive ? 'Active (-3.2% loss)' : 'Inactive (0%)',
                color: _alternativeSupplierActive ? ClimatwinTheme.riskLow : ClimatwinTheme.textMuted,
              ),
              const SizedBox(height: 6),
              _buildInsightRow(
                icon: Icons.water_drop_outlined,
                title: 'Site Closed-Loop Recycling',
                value: _adaptationActive ? 'Active (-2.5% loss)' : 'Inactive (0%)',
                color: _adaptationActive ? ClimatwinTheme.riskLow : ClimatwinTheme.textMuted,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ClimatwinTheme.darkGreenPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close Insights', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightRow({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title, style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textSecondary)),
        ),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}
