import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/currency_utils.dart';
import '../../core/auth_service.dart';
import '../../core/firestore_service.dart';
import '../company/company_detail_screen.dart';

class WatchlistScreen extends StatefulWidget {
  final void Function(String ticker)? onInspectInGraph;
  final void Function(String ticker)? onSimulateShock;

  const WatchlistScreen({
    super.key,
    this.onInspectInGraph,
    this.onSimulateShock,
  });

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistItem {
  final String ticker;
  final String name;
  final String sector;
  final double priceUsd;
  final double changePct;
  final int riskScore;
  final String riskLevel;
  final List<double> sparkline;
  // Alert settings
  double priceAlertPct;
  int riskAlertThreshold;
  bool newsAlertsEnabled;

  _WatchlistItem({
    required this.ticker,
    required this.name,
    required this.sector,
    required this.priceUsd,
    required this.changePct,
    required this.riskScore,
    required this.riskLevel,
    required this.sparkline,
    this.priceAlertPct = 5.0,
    this.riskAlertThreshold = 70,
    this.newsAlertsEnabled = true,
  });
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<_WatchlistItem> _items = [
    _WatchlistItem(
      ticker: 'NVDA',
      name: 'NVIDIA Corporation',
      sector: 'Semiconductors',
      priceUsd: 118.20,
      changePct: 2.85,
      riskScore: 79,
      riskLevel: 'High',
      sparkline: [112.0, 114.5, 113.8, 116.2, 115.0, 117.4, 118.2],
    ),
    _WatchlistItem(
      ticker: 'TSMC',
      name: 'Taiwan Semiconductor Mfg.',
      sector: 'Foundry & Wafers',
      priceUsd: 172.50,
      changePct: -1.20,
      riskScore: 84,
      riskLevel: 'Critical',
      sparkline: [178.0, 176.5, 175.0, 173.2, 174.0, 171.8, 172.5],
    ),
    _WatchlistItem(
      ticker: 'AAPL',
      name: 'Apple Inc.',
      sector: 'Consumer Electronics',
      priceUsd: 228.40,
      changePct: 0.65,
      riskScore: 62,
      riskLevel: 'Medium',
      sparkline: [224.0, 225.0, 226.2, 225.8, 227.1, 227.9, 228.4],
    ),
    _WatchlistItem(
      ticker: 'BMW.DE',
      name: 'BMW Group',
      sector: 'Automotive & Freight',
      priceUsd: 88.60,
      changePct: -0.45,
      riskScore: 58,
      riskLevel: 'Medium',
      sparkline: [90.0, 89.4, 89.8, 88.9, 89.1, 88.2, 88.6],
    ),
    _WatchlistItem(
      ticker: 'MSFT',
      name: 'Microsoft Corporation',
      sector: 'Cloud & AI Infrastructure',
      priceUsd: 442.10,
      changePct: 1.15,
      riskScore: 38,
      riskLevel: 'Low',
      sparkline: [435.0, 437.2, 436.0, 439.4, 440.0, 441.5, 442.1],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAlertSettingsModal(_WatchlistItem item) {
    double tempPricePct = item.priceAlertPct;
    int tempRisk = item.riskAlertThreshold;
    bool tempNews = item.newsAlertsEnabled;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ClimatwinTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Configure Alerts • ${item.ticker}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ClimatwinTheme.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Receive proactive notifications when price volatility or climate vulnerability changes.',
                style: TextStyle(fontSize: 12, color: ClimatwinTheme.textSecondary),
              ),
              const Divider(height: 24),

              // Price Threshold Slider
              Text(
                'Price Movement Trigger: ±${tempPricePct.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ClimatwinTheme.textPrimary),
              ),
              Slider(
                value: tempPricePct,
                min: 1.0,
                max: 15.0,
                divisions: 14,
                activeColor: ClimatwinTheme.darkGreenPrimary,
                inactiveColor: ClimatwinTheme.surfaceElevated,
                label: '${tempPricePct.toStringAsFixed(1)}%',
                onChanged: (v) => setModalState(() => tempPricePct = v),
              ),
              const SizedBox(height: 12),

              // Climate Risk Threshold Slider
              Text(
                'Climate Risk Threshold: Score >= $tempRisk / 100',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ClimatwinTheme.textPrimary),
              ),
              Slider(
                value: tempRisk.toDouble(),
                min: 30,
                max: 95,
                divisions: 13,
                activeColor: ClimatwinTheme.riskHigh,
                inactiveColor: ClimatwinTheme.surfaceElevated,
                label: '$tempRisk',
                onChanged: (v) => setModalState(() => tempRisk = v.round()),
              ),
              const SizedBox(height: 12),

              // News Toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Climate & Geopolitical News Alerts',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ClimatwinTheme.textPrimary),
                ),
                subtitle: const Text(
                  'Notify when supplier flood, drought, or grid disruptions occur.',
                  style: TextStyle(fontSize: 11, color: ClimatwinTheme.textSecondary),
                ),
                value: tempNews,
                activeColor: ClimatwinTheme.darkGreenPrimary,
                onChanged: (v) => setModalState(() => tempNews = v),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ClimatwinTheme.darkGreenPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    setState(() {
                      item.priceAlertPct = tempPricePct;
                      item.riskAlertThreshold = tempRisk;
                      item.newsAlertsEnabled = tempNews;
                    });
                    final uid = AuthService.instance.currentUser?.uid ?? 'default_analyst';
                    FirestoreService.instance.saveAlertRule(
                      userId: uid,
                      ticker: item.ticker,
                      priceAlertPct: tempPricePct,
                      riskAlertThreshold: tempRisk,
                      newsAlertsEnabled: tempNews,
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Alert rules updated for ${item.ticker} (Synced to Cloud)'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text('Save Alert Preferences', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCompanyDialog() {
    final available = [
      {'ticker': 'RELIANCE.NS', 'name': 'Reliance Industries', 'sector': 'Energy & Petrochemicals', 'usd': 34.2, 'risk': 68, 'lvl': 'Medium'},
      {'ticker': 'TCS.NS', 'name': 'Tata Consultancy Services', 'sector': 'IT & Cloud Services', 'usd': 46.5, 'risk': 32, 'lvl': 'Low'},
      {'ticker': 'INTC', 'name': 'Intel Corporation', 'sector': 'Semiconductors', 'usd': 21.8, 'risk': 65, 'lvl': 'Medium'},
      {'ticker': 'ASML', 'name': 'ASML Holding', 'sector': 'Lithography Systems', 'usd': 810.0, 'risk': 71, 'lvl': 'High'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: ClimatwinTheme.surfaceCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add to Watchlist',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ClimatwinTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Select an asset to track its climate dependency risk and financial impact.',
              style: TextStyle(fontSize: 12, color: ClimatwinTheme.textSecondary),
            ),
            const Divider(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: available.length,
                itemBuilder: (ctx, i) {
                  final a = available[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: ClimatwinTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        (a['ticker'] as String).split('.').first,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ClimatwinTheme.darkGreenPrimary),
                      ),
                    ),
                    title: Text(a['name'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ClimatwinTheme.textPrimary)),
                    subtitle: Text(
                      '${a['sector']} • Climate Risk: ${a['risk']}',
                      style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textSecondary),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle, color: ClimatwinTheme.darkGreenPrimary),
                      onPressed: () {
                        setState(() {
                          _items.add(_WatchlistItem(
                            ticker: a['ticker'] as String,
                            name: a['name'] as String,
                            sector: a['sector'] as String,
                            priceUsd: (a['usd'] as num).toDouble(),
                            changePct: 1.2,
                            riskScore: a['risk'] as int,
                            riskLevel: a['lvl'] as String,
                            sparkline: [20.0, 21.0, 20.8, 21.5, 22.0, 21.8],
                          ));
                        });
                        final uid = AuthService.instance.currentUser?.uid ?? 'default_analyst';
                        FirestoreService.instance.saveWatchlistItem(
                          userId: uid,
                          item: {
                            'ticker': a['ticker'],
                            'name': a['name'],
                            'sector': a['sector'],
                            'price_usd': a['usd'],
                            'risk_score': a['risk'],
                            'risk_level': a['lvl'],
                          },
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${a['ticker']} added to watchlist (Synced)')),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _items.where((item) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return item.ticker.toLowerCase().contains(q) ||
          item.name.toLowerCase().contains(q) ||
          item.sector.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio Watchlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: ClimatwinTheme.darkGreenPrimary),
            tooltip: 'Add Company',
            onPressed: _showAddCompanyDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search watchlist by ticker, company, or sector...',
                hintStyle: const TextStyle(fontSize: 13, color: ClimatwinTheme.textMuted),
                prefixIcon: const Icon(Icons.search, size: 20, color: ClimatwinTheme.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),

          // FX Benchmark note
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 13, color: ClimatwinTheme.textMuted),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Prices converted to INR (₹) using benchmark FX (1 USD = ₹83.50)',
                    style: TextStyle(fontSize: 11, color: ClimatwinTheme.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${filteredItems.length} Assets',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ClimatwinTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Watchlist Feed
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bookmark_border, size: 48, color: ClimatwinTheme.textMuted),
                        const SizedBox(height: 12),
                        const Text(
                          'No assets match your search',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ClimatwinTheme.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Try searching for another ticker or add one to your watchlist.',
                          style: TextStyle(fontSize: 12, color: ClimatwinTheme.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _showAddCompanyDialog,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Asset'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: filteredItems.length,
                    itemBuilder: (ctx, idx) {
                      final item = filteredItems[idx];
                      final isPositive = item.changePct >= 0;
                      final inrPrice = item.priceUsd * CurrencyFormatter.usdToInrRate;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => CompanyDetailScreen(
                                  ticker: item.ticker,
                                  name: item.name,
                                  sector: item.sector,
                                  basePriceUsd: item.priceUsd,
                                  climateRiskScore: item.riskScore,
                                  riskLevel: item.riskLevel,
                                  onInspectGraph: widget.onInspectInGraph != null
                                      ? () {
                                          Navigator.pop(ctx);
                                          widget.onInspectInGraph!(item.ticker);
                                        }
                                      : null,
                                  onSimulate: widget.onSimulateShock != null
                                      ? () {
                                          Navigator.pop(ctx);
                                          widget.onSimulateShock!(item.ticker);
                                        }
                                      : null,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    // Ticker badge
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: ClimatwinTheme.surfaceElevated,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: ClimatwinTheme.borderSubtle),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        item.ticker.split('.').first,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: ClimatwinTheme.darkGreenPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Name & Sector
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: ClimatwinTheme.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item.sector,
                                            style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Price & Sparkline
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          CurrencyFormatter.formatPrice(inrPrice),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: ClimatwinTheme.textPrimary,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Icon(
                                              isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                              color: isPositive ? ClimatwinTheme.riskLow : ClimatwinTheme.riskHigh,
                                              size: 16,
                                            ),
                                            Text(
                                              '${isPositive ? "+" : ""}${item.changePct.toStringAsFixed(2)}%',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: isPositive ? ClimatwinTheme.riskLow : ClimatwinTheme.riskHigh,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Divider(height: 18),
                                // Bottom info row: Risk score + Actions
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: ClimatwinTheme.getRiskColor(item.riskLevel).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            size: 12,
                                            color: ClimatwinTheme.getRiskColor(item.riskLevel),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Risk: ${item.riskScore}/100 (${item.riskLevel})',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: ClimatwinTheme.getRiskColor(item.riskLevel),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.notifications_active_outlined, size: 18, color: ClimatwinTheme.textSecondary),
                                      tooltip: 'Alert Rules',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _showAlertSettingsModal(item),
                                    ),
                                    const SizedBox(width: 14),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: ClimatwinTheme.textMuted),
                                      tooltip: 'Remove',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        setState(() {
                                          _items.remove(item);
                                        });
                                        final uid = AuthService.instance.currentUser?.uid ?? 'default_analyst';
                                        FirestoreService.instance.removeWatchlistItem(
                                          userId: uid,
                                          ticker: item.ticker,
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('${item.ticker} removed from watchlist'),
                                            action: SnackBarAction(
                                              label: 'Undo',
                                              onPressed: () => setState(() => _items.insert(idx, item)),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
