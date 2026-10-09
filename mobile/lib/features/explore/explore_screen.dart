import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'graph_canvas.dart';

class ExploreScreen extends StatefulWidget {
  final int initialTabIndex;

  const ExploreScreen({super.key, this.initialTabIndex = 0});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late int _selectedSegment;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _holdings = [
    {
      "ticker": "AAPL",
      "name": "Apple Inc.",
      "weight": "12.0%",
      "climate_risk": "Moderate",
      "score": 62,
      "risk_color": ClimatwinTheme.riskMedium,
      "bottleneck": "Taiwan packaging tier",
    },
    {
      "ticker": "NVDA",
      "name": "NVIDIA Corp",
      "weight": "9.0%",
      "climate_risk": "High",
      "score": 79,
      "risk_color": ClimatwinTheme.riskHigh,
      "bottleneck": "Foundry water supply",
    },
    {
      "ticker": "BMW.DE",
      "name": "BMW Group",
      "weight": "5.0%",
      "climate_risk": "Moderate",
      "score": 58,
      "risk_color": ClimatwinTheme.riskMedium,
      "bottleneck": "Rhine river logistics",
    },
    {
      "ticker": "MSFT",
      "name": "Microsoft Corp",
      "weight": "14.0%",
      "climate_risk": "Low",
      "score": 38,
      "risk_color": ClimatwinTheme.riskLow,
      "bottleneck": "Data center thermal load",
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
              ? const InteractiveDependencyGraph()
              : _buildHoldingsView(),
        ),
      ],
    );
  }

  Widget _buildHoldingsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search box
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search portfolio company or supplier...',
              hintStyle: const TextStyle(fontSize: 13, color: ClimatwinTheme.textMuted),
              prefixIcon: const Icon(Icons.search, size: 20, color: ClimatwinTheme.textSecondary),
              filled: true,
              fillColor: ClimatwinTheme.surfaceCard,
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

          const Text(
            'Portfolio Holdings (Ranked by Climate Risk)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: ClimatwinTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          ..._holdings.map((h) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: ClimatwinTheme.surfaceBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: ClimatwinTheme.borderSubtle),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          h["ticker"],
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: ClimatwinTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              h["name"],
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
                            h["climate_risk"],
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
              )),
        ],
      ),
    );
  }
}
