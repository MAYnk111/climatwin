import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/currency_utils.dart';
import '../company/company_detail_screen.dart';
import 'graph_canvas.dart';
import 'graph_models.dart';

class ExploreScreen extends StatefulWidget {
  final int initialTabIndex;
  final void Function(ClimaNode node)? onInvestigateNode;

  const ExploreScreen({
    super.key,
    this.initialTabIndex = 0,
    this.onInvestigateNode,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late int _selectedSegment;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _holdings = [
    {
      "ticker": "AAPL",
      "name": "Apple Inc.",
      "weight": "12.0%",
      "climate_risk": "Moderate",
      "score": 62,
      "risk_color": ClimatwinTheme.riskMedium,
      "bottleneck": "Taiwan packaging tier",
      "sector": "Consumer Electronics",
      "price_usd": 228.40,
    },
    {
      "ticker": "NVDA",
      "name": "NVIDIA Corp",
      "weight": "9.0%",
      "climate_risk": "High",
      "score": 79,
      "risk_color": ClimatwinTheme.riskHigh,
      "bottleneck": "Foundry water supply",
      "sector": "Semiconductors & AI",
      "price_usd": 118.20,
    },
    {
      "ticker": "BMW.DE",
      "name": "BMW Group",
      "weight": "5.0%",
      "climate_risk": "Moderate",
      "score": 58,
      "risk_color": ClimatwinTheme.riskMedium,
      "bottleneck": "Rhine river logistics",
      "sector": "Automotive & Freight",
      "price_usd": 88.60,
    },
    {
      "ticker": "MSFT",
      "name": "Microsoft Corp",
      "weight": "14.0%",
      "climate_risk": "Low",
      "score": 38,
      "risk_color": ClimatwinTheme.riskLow,
      "bottleneck": "Data center thermal load",
      "sector": "Cloud Infrastructure",
      "price_usd": 442.10,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedSegment = widget.initialTabIndex;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sub-navigation bar: Graph vs Holdings / Search
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: ClimatwinTheme.surfaceCard,
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 0,
                      label: Text('Dependency Graph', style: TextStyle(fontSize: 12)),
                      icon: Icon(Icons.account_tree_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text('Holdings & Search', style: TextStyle(fontSize: 12)),
                      icon: Icon(Icons.list_alt, size: 16),
                    ),
                  ],
                  selected: {_selectedSegment},
                  style: SegmentedButton.styleFrom(
                    backgroundColor: ClimatwinTheme.surfaceBackground,
                    selectedBackgroundColor: ClimatwinTheme.lightGreenSurface,
                    selectedForegroundColor: ClimatwinTheme.darkGreenPrimary,
                  ),
                  onSelectionChanged: (Set<int> newSelection) {
                    setState(() {
                      _selectedSegment = newSelection.first;
                    });
                  },
                ),
              ),
            ],
          ),
        ),

        // Body content
        Expanded(
          child: _selectedSegment == 0
              ? InteractiveDependencyGraph(
                  onInvestigateNode: widget.onInvestigateNode,
                )
              : _buildHoldingsView(),
        ),
      ],
    );
  }

  Widget _buildHoldingsView() {
    final filtered = _holdings.where((h) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final ticker = (h["ticker"] as String).toLowerCase();
      final name = (h["name"] as String).toLowerCase();
      final bottleneck = (h["bottleneck"] as String).toLowerCase();
      return ticker.contains(q) || name.contains(q) || bottleneck.contains(q);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search box
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search portfolio company or supplier...',
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
              filled: true,
              fillColor: ClimatwinTheme.surfaceElevated,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: ClimatwinTheme.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: ClimatwinTheme.borderSubtle),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Portfolio Holdings (Ranked by Climate Risk)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ClimatwinTheme.textPrimary,
                ),
              ),
              Text(
                '${filtered.length} Entities',
                style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ...filtered.map((h) {
            final double inrPrice = (h["price_usd"] as double) * CurrencyFormatter.usdToInrRate;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CompanyDetailScreen(
                        ticker: h["ticker"] as String,
                        name: h["name"] as String,
                        sector: h["sector"] as String,
                        basePriceUsd: h["price_usd"] as double,
                        climateRiskScore: h["score"] as int,
                        riskLevel: h["climate_risk"] as String,
                        onInspectGraph: () {
                          Navigator.pop(context);
                          setState(() => _selectedSegment = 0);
                        },
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
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
                          (h["ticker"] as String).split('.').first,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: ClimatwinTheme.darkGreenPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              h["name"] as String,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: ClimatwinTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Weight: ${h["weight"]} • Hazard: ${h["bottleneck"]}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: ClimatwinTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Price: ${CurrencyFormatter.formatPrice(inrPrice)}',
                              style: const TextStyle(fontSize: 10, color: ClimatwinTheme.accentTeal, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${h["score"]}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: h["risk_color"] as Color,
                            ),
                          ),
                          Text(
                            h["climate_risk"] as String,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: h["risk_color"] as Color,
                            ),
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
      ),
    );
  }
}
