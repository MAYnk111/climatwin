import 'package:flutter/material.dart';
import '../../core/theme.dart';

class IntelligenceScreen extends StatelessWidget {
  const IntelligenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
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
                          'LANGGRAPH AGENT INVESTIGATION',
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
                  const Text(
                    'Taiwan Drought: Semiconductor Wafer Bottleneck',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ClimatwinTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Multi-agent investigation synthesized 4 hydrological feeds and supply chain dependencies. '
                    'Estimated -4.2% portfolio shock on unhedged holdings.',
                    style: TextStyle(fontSize: 12, color: ClimatwinTheme.textSecondary),
                  ),
                  const Divider(height: 20, color: ClimatwinTheme.borderSubtle),

                  // Impacted holdings summary
                  const Text(
                    'Transmission Path to Portfolio',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ClimatwinTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Drought Hazard → Baoshan Reservoir → Fab 12 → TSMC → NVDA (9%) & AAPL (12%)',
                    style: TextStyle(fontSize: 11, color: ClimatwinTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Source Evidence Section
          const Text(
            'Verified Source Evidence',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: ClimatwinTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          _EvidenceCard(
            source: 'Taiwan Water Resources Agency (WRA)',
            title: 'Reservoir Capacity Drops to 17.8%',
            timestamp: '2026-10-08 14:00 UTC',
            reliability: '95% Confidence',
            snippet: 'Water rationing Stage 2 activated in Hsinchu Science Park zone.',
          ),
          const SizedBox(height: 8),

          _EvidenceCard(
            source: 'Copernicus Climate Change Service',
            title: 'Sub-Seasonal Precipitation Anomaly: -45mm',
            timestamp: '2026-10-08 09:30 UTC',
            reliability: '92% Confidence',
            snippet: 'Forecast projects continued high pressure blocking monsoon rains across central basin.',
          ),
          const SizedBox(height: 16),

          // Mitigation Recommendations
          const Text(
            'Actionable Mitigation Recommendations',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: ClimatwinTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          _MitigationCard(
            action: 'Foundry Diversification Allocation',
            impactReduction: 'Reduces Drawdown by 1.8%',
            horizon: '1-3 Quarters',
            icon: Icons.alt_route,
          ),
          const SizedBox(height: 8),

          _MitigationCard(
            action: 'Semiconductor Volatility Tail Hedge',
            impactReduction: 'Reduces Drawdown by 2.1%',
            horizon: 'Immediate Execution',
            icon: Icons.shield_outlined,
          ),
        ],
      ),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  final String source;
  final String title;
  final String timestamp;
  final String reliability;
  final String snippet;

  const _EvidenceCard({
    required this.source,
    required this.title,
    required this.timestamp,
    required this.reliability,
    required this.snippet,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
                    source,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ClimatwinTheme.darkGreenPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  reliability,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ClimatwinTheme.riskLow),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ClimatwinTheme.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              snippet,
              style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              timestamp,
              style: const TextStyle(fontSize: 9, color: ClimatwinTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _MitigationCard extends StatelessWidget {
  final String action;
  final String impactReduction;
  final String horizon;
  final IconData icon;

  const _MitigationCard({
    required this.action,
    required this.impactReduction,
    required this.horizon,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
              child: Icon(icon, size: 18, color: ClimatwinTheme.darkGreenPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ClimatwinTheme.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$impactReduction • $horizon',
                    style: const TextStyle(fontSize: 11, color: ClimatwinTheme.riskLow, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: ClimatwinTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
