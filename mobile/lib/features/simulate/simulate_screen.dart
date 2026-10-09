import 'package:flutter/material.dart';
import '../../core/theme.dart';

class SimulateScreen extends StatefulWidget {
  const SimulateScreen({super.key});

  @override
  State<SimulateScreen> createState() => _SimulateScreenState();
}

class _SimulateScreenState extends State<SimulateScreen> {
  double _severityMultiplier = 1.8;
  int _durationMonths = 4;
  bool _adaptationActive = true;
  bool _alternativeSupplierActive = true;

  @override
  Widget build(BuildContext context) {
    // Financial simulation calculations matching backend logic
    const double baselineAum = 250.0; // $250M
    final double rawDrawdownPct = 0.05 * _severityMultiplier * 1.2 * (_durationMonths / 3.0);
    double mitigationFactor = 0.0;
    if (_adaptationActive) mitigationFactor += 0.4;
    if (_alternativeSupplierActive) mitigationFactor += 0.3;

    final double effectiveDrawdownPct = (rawDrawdownPct * (1.0 - mitigationFactor)).clamp(0.0, 1.0);
    final double unmitigatedDrawdownPct = rawDrawdownPct.clamp(0.0, 1.0);

    final double unmitigatedLossM = baselineAum * unmitigatedDrawdownPct;
    final double effectiveLossM = baselineAum * effectiveDrawdownPct;
    final double savingsM = unmitigatedLossM - effectiveLossM;
    final double stressedAum = baselineAum - effectiveLossM;

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
                  const Text(
                    'SCENARIO CONFIGURATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ClimatwinTheme.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'East Asia Severe Drought & Packaging Shock',
                    style: TextStyle(
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
                      const Text('Hazard Severity Multiplier', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('${_severityMultiplier.toStringAsFixed(1)}x', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: ClimatwinTheme.darkGreenPrimary)),
                    ],
                  ),
                  Slider(
                    value: _severityMultiplier,
                    min: 1.0,
                    max: 3.0,
                    divisions: 20,
                    activeColor: ClimatwinTheme.darkGreenPrimary,
                    onChanged: (val) => setState(() => _severityMultiplier = val),
                  ),

                  // Duration Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Duration (Months)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('$_durationMonths Months', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: ClimatwinTheme.darkGreenPrimary)),
                    ],
                  ),
                  Slider(
                    value: _durationMonths.toDouble(),
                    min: 1,
                    max: 12,
                    divisions: 11,
                    activeColor: ClimatwinTheme.darkGreenPrimary,
                    onChanged: (val) => setState(() => _durationMonths = val.toInt()),
                  ),

                  const Divider(height: 20, color: ClimatwinTheme.borderSubtle),

                  // Mitigation Switches (Scenario Branches)
                  SwitchListTile(
                    title: const Text('Water Recycling & Adaptation Protocol', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    subtitle: const Text('-40% physical vulnerability damping', style: TextStyle(fontSize: 11, color: ClimatwinTheme.textMuted)),
                    value: _adaptationActive,
                    activeColor: ClimatwinTheme.darkGreenPrimary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _adaptationActive = val),
                  ),
                  SwitchListTile(
                    title: const Text('Secondary Foundry Dual-Sourcing', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    subtitle: const Text('-30% Tier-1 supply disruption damping', style: TextStyle(fontSize: 11, color: ClimatwinTheme.textMuted)),
                    value: _alternativeSupplierActive,
                    activeColor: ClimatwinTheme.darkGreenPrimary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _alternativeSupplierActive = val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Baseline vs Stressed Comparison Card
          const Text(
            'Baseline vs. Stressed Comparison',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: ClimatwinTheme.textPrimary,
            ),
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
                            const Text('Baseline AUM', style: TextStyle(fontSize: 11, color: ClimatwinTheme.textMuted)),
                            const SizedBox(height: 4),
                            Text('\$${baselineAum.toStringAsFixed(1)}M', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ClimatwinTheme.textPrimary)),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 40, color: ClimatwinTheme.borderSubtle),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Simulated Stressed AUM', style: TextStyle(fontSize: 11, color: ClimatwinTheme.textMuted)),
                            const SizedBox(height: 4),
                            Text(
                              '\$${stressedAum.toStringAsFixed(1)}M',
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
                      const Text('Simulated Portfolio Drawdown', style: TextStyle(fontSize: 12, color: ClimatwinTheme.textSecondary)),
                      Text(
                        '-${(effectiveDrawdownPct * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: ClimatwinTheme.riskHigh),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Mitigation Capital Saved', style: TextStyle(fontSize: 12, color: ClimatwinTheme.textSecondary)),
                      Text(
                        '+\$${savingsM.toStringAsFixed(1)}M',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: ClimatwinTheme.riskLow),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stressed Holdings Breakdown
          const Text(
            'Stressed Holdings Impact',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: ClimatwinTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          _HoldingStressRow(ticker: 'NVDA', name: 'NVIDIA Corp', baselineM: '\$22.5M', lossM: '-\$1.8M', drawdown: '-8.0%'),
          const SizedBox(height: 6),
          _HoldingStressRow(ticker: 'AAPL', name: 'Apple Inc.', baselineM: '\$30.0M', lossM: '-\$1.6M', drawdown: '-5.3%'),
          const SizedBox(height: 6),
          _HoldingStressRow(ticker: 'BMW.DE', name: 'BMW Group', baselineM: '\$12.5M', lossM: '-\$0.4M', drawdown: '-3.2%'),
        ],
      ),
    );
  }
}

class _HoldingStressRow extends StatelessWidget {
  final String ticker;
  final String name;
  final String baselineM;
  final String lossM;
  final String drawdown;

  const _HoldingStressRow({
    required this.ticker,
    required this.name,
    required this.baselineM,
    required this.lossM,
    required this.drawdown,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text(
              ticker,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: ClimatwinTheme.textPrimary),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textSecondary),
              ),
            ),
            Text(
              '$baselineM → $lossM ($drawdown)',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ClimatwinTheme.riskHigh),
            ),
          ],
        ),
      ),
    );
  }
}
