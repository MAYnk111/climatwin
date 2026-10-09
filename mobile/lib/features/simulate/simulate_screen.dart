import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import 'simulate_models.dart';

class SimulateScreen extends StatefulWidget {
  final ApiClient? apiClient;

  const SimulateScreen({super.key, this.apiClient});

  @override
  State<SimulateScreen> createState() => _SimulateScreenState();
}

class _SimulateScreenState extends State<SimulateScreen> {
  late final ApiClient _apiClient;

  double _severityMultiplier = 1.8;
  int _durationMonths = 4;
  bool _adaptationActive = true;
  bool _alternativeSupplierActive = true;

  SimulationResult? _simulationResult;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient ?? ApiClient.instance;
    _runSimulation();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onParameterChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _runSimulation();
    });
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
          // Scenario Configuration Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'SCENARIO CONFIGURATION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: ClimatwinTheme.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: ClimatwinTheme.lightGreenSurface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'BACKEND SIMULATION ENGINE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: ClimatwinTheme.darkGreenPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _simulationResult?.scenarioName ??
                        'East Asia Severe Drought & Packaging Shock',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ClimatwinTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Hazard Severity Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Hazard Severity Multiplier',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text(
                        '${_severityMultiplier.toStringAsFixed(1)}x',
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
                    onChanged: (val) {
                      setState(() => _severityMultiplier = val);
                      _onParameterChanged();
                    },
                  ),

                  // Duration Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Duration (Months)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
                    onChanged: (val) {
                      setState(() => _durationMonths = val.toInt());
                      _onParameterChanged();
                    },
                  ),

                  const Divider(height: 20, color: ClimatwinTheme.borderSubtle),

                  // Mitigation Switches (Scenario Branches)
                  SwitchListTile(
                    title: const Text('Water Recycling & Adaptation Protocol',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    subtitle: const Text('-40% physical vulnerability damping',
                        style: TextStyle(fontSize: 11, color: ClimatwinTheme.textMuted)),
                    value: _adaptationActive,
                    activeColor: ClimatwinTheme.darkGreenPrimary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setState(() => _adaptationActive = val);
                      _runSimulation();
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Secondary Foundry Dual-Sourcing',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    subtitle: const Text('-30% Tier-1 supply disruption damping',
                        style: TextStyle(fontSize: 11, color: ClimatwinTheme.textMuted)),
                    value: _alternativeSupplierActive,
                    activeColor: ClimatwinTheme.darkGreenPrimary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setState(() => _alternativeSupplierActive = val);
                      _runSimulation();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Simulation Execution Status / Error / Content
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ClimatwinTheme.darkGreenPrimary,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Recalculating portfolio stress test on backend...',
                      style: TextStyle(fontSize: 12, color: ClimatwinTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else if (_errorMessage != null)
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.error_outline, color: ClimatwinTheme.riskHigh, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Simulation Execution Error',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ClimatwinTheme.riskHigh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ClimatwinTheme.darkGreenPrimary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _runSimulation,
                      child: const Text('Retry Stress Test'),
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

  Widget _buildResultsSection(SimulationResult res) {
    final double baselineM = res.baselineTotalAum / 1_000_000.0;
    final double stressedM = res.stressedTotalAum / 1_000_000.0;
    final double netLossM = res.netPortfolioLossUsd / 1_000_000.0;
    final double totalSavingsM = res.stressedHoldings
        .fold(0.0, (acc, h) => acc + h.mitigationSavingsUsd) / 1_000_000.0;

    final unmitigatedDrawdown = res.branchComparison['unmitigated_drawdown_pct'] ??
        res.portfolioDrawdownPct;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Baseline vs Stressed Comparison Card
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Baseline vs. Stressed Comparison',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: ClimatwinTheme.textPrimary,
              ),
            ),
            if (res.isModelledData)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: const Text(
                  'MODELLED STRESS TEST',
                  style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: ClimatwinTheme.riskMedium),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

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
                          const Text('Baseline AUM',
                              style: TextStyle(fontSize: 11, color: ClimatwinTheme.textMuted)),
                          const SizedBox(height: 4),
                          Text(
                            '\$${baselineM.toStringAsFixed(1)}M',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: ClimatwinTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 40, color: ClimatwinTheme.borderSubtle),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Simulated Stressed AUM',
                              style: TextStyle(fontSize: 11, color: ClimatwinTheme.textMuted)),
                          const SizedBox(height: 4),
                          Text(
                            '\$${stressedM.toStringAsFixed(1)}M',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: ClimatwinTheme.riskHigh,
                            ),
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
                      '-${res.portfolioDrawdownPct.toStringAsFixed(2)}% (Loss: -\$${netLossM.toStringAsFixed(2)}M)',
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
                      '+\$${totalSavingsM.toStringAsFixed(2)}M',
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
        const SizedBox(height: 16),

        // Stressed Holdings Impact Breakdown
        const Text(
          'Stressed Holdings Breakdown (Backend Calculated)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: ClimatwinTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        ...res.stressedHoldings.map((h) {
          final double baseHoldingM = h.baselineValueUsd / 1_000_000.0;
          final double lossHoldingM = h.lossUsd / 1_000_000.0;
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
                        color: ClimatwinTheme.surfaceBackground,
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            h.name,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Saved: +\$${(h.mitigationSavingsUsd / 1_000_000.0).toStringAsFixed(2)}M via dual-source',
                            style: const TextStyle(fontSize: 10, color: ClimatwinTheme.riskLow),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${baseHoldingM.toStringAsFixed(1)}M → -\$${lossHoldingM.toStringAsFixed(2)}M (-${h.drawdownPct.toStringAsFixed(1)}%)',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: ClimatwinTheme.riskHigh,
                      ),
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
}
