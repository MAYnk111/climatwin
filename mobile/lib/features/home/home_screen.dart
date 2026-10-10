import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/currency_utils.dart';
import '../watchlist/watchlist_screen.dart';
import '../market/market_screen.dart';
import '../alerts/alerts_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onExploreGraph;
  final VoidCallback onInvestigate;
  final VoidCallback onSimulate;
  final VoidCallback? onOpenWatchlist;
  final VoidCallback? onOpenMarket;
  final VoidCallback? onOpenAlerts;

  const HomeScreen({
    super.key,
    required this.onExploreGraph,
    required this.onInvestigate,
    required this.onSimulate,
    this.onOpenWatchlist,
    this.onOpenMarket,
    this.onOpenAlerts,
  });

  @override
  Widget build(BuildContext context) {
    const double portfolioUsd = 10000000.0; // $10.0M
    const double portfolioInr = portfolioUsd * CurrencyFormatter.usdToInrRate; // ₹83.5 Cr

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Portfolio Climate-Risk Overview Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'PORTFOLIO CLIMATE RISK',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: ClimatwinTheme.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: ClimatwinTheme.riskMedium.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'MODERATE EXPOSURE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: ClimatwinTheme.riskMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text(
                        '68.5',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: ClimatwinTheme.textPrimary,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const Text(
                        ' / 100',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ClimatwinTheme.textMuted,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.trending_up, color: ClimatwinTheme.riskHigh, size: 18),
                      const SizedBox(width: 4),
                      const Text(
                        '+4.2 pts (7d)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ClimatwinTheme.riskHigh,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Elevated vulnerability driven by Tier-1 water dependency in East Asia tech supply chains.',
                    style: TextStyle(
                      fontSize: 13,
                      color: ClimatwinTheme.textSecondary,
                    ),
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Portfolio AUM', style: TextStyle(fontSize: 11, color: ClimatwinTheme.textMuted)),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.formatInr(portfolioInr),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ClimatwinTheme.textPrimary),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Climate Value-at-Risk', style: TextStyle(fontSize: 11, color: ClimatwinTheme.textMuted)),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.formatInr(portfolioInr * 0.182),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ClimatwinTheme.riskHigh),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quick Navigation Hub
          Row(
            children: [
              Expanded(
                child: _QuickHubButton(
                  icon: Icons.bookmark_outline,
                  label: 'Watchlist',
                  onTap: () {
                    if (onOpenWatchlist != null) {
                      onOpenWatchlist!();
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const WatchlistScreen()));
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickHubButton(
                  icon: Icons.candlestick_chart_outlined,
                  label: 'Markets (₹)',
                  onTap: () {
                    if (onOpenMarket != null) {
                      onOpenMarket!();
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketScreen()));
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickHubButton(
                  icon: Icons.notifications_active_outlined,
                  label: 'Alerts',
                  onTap: () {
                    if (onOpenAlerts != null) {
                      onOpenAlerts!();
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen()));
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Key Risk Indicators Grid
          const Text(
            'Risk Indicators',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: ClimatwinTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _IndicatorCard(
                  label: 'Physical Hazard',
                  score: '74',
                  level: 'High',
                  color: ClimatwinTheme.riskHigh,
                  detail: 'Drought & Water Stress',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _IndicatorCard(
                  label: 'Supply Chain',
                  score: '81',
                  level: 'Critical',
                  color: ClimatwinTheme.riskCritical,
                  detail: 'Foundry Bottleneck',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _IndicatorCard(
                  label: 'Transition',
                  score: '42',
                  level: 'Low',
                  color: ClimatwinTheme.riskLow,
                  detail: 'Carbon Border Tax',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Important Alerts Header & Feed
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Important Alerts',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: ClimatwinTheme.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen()));
                },
                child: const Text('View All', style: TextStyle(color: ClimatwinTheme.darkGreenPrimary, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _AlertCard(
            title: 'Taiwan Baoshan Reservoir Stage 2 Rationing',
            impact: 'Affects TSMC Fab 12 • Propagates to NVDA & AAPL',
            time: '2 hours ago',
            severityColor: ClimatwinTheme.riskCritical,
            onTap: onInvestigate,
          ),
          const SizedBox(height: 8),
          _AlertCard(
            title: 'Rhine River Water Levels at Kaub Gauge Falling',
            impact: 'Freight barge draft limited to 50% capacity',
            time: '5 hours ago',
            severityColor: ClimatwinTheme.riskHigh,
            onTap: onInvestigate,
          ),
          const SizedBox(height: 16),

          // Quick Primary Actions
          const Text(
            'Primary Actions',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: ClimatwinTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ClimatwinTheme.textPrimary,
                    side: const BorderSide(color: ClimatwinTheme.borderSubtle),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.account_tree_outlined, size: 18, color: ClimatwinTheme.darkGreenPrimary),
                  label: const Text('Inspect Graph', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  onPressed: onExploreGraph,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ClimatwinTheme.darkGreenPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.science_outlined, size: 18),
                  label: const Text('Simulate Stress', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  onPressed: onSimulate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _QuickHubButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickHubButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, size: 20, color: ClimatwinTheme.darkGreenPrimary),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ClimatwinTheme.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IndicatorCard extends StatelessWidget {
  final String label;
  final String score;
  final String level;
  final Color color;
  final String detail;

  const _IndicatorCard({
    required this.label,
    required this.score,
    required this.level,
    required this.color,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textSecondary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  score,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
                ),
                const SizedBox(width: 4),
                Text(
                  level,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              detail,
              style: const TextStyle(fontSize: 10, color: ClimatwinTheme.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final String title;
  final String impact;
  final String time;
  final Color severityColor;
  final VoidCallback onTap;

  const _AlertCard({
    required this.title,
    required this.impact,
    required this.time,
    required this.severityColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
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
                    const SizedBox(height: 3),
                    Text(
                      impact,
                      style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: const TextStyle(fontSize: 10, color: ClimatwinTheme.textMuted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: ClimatwinTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
