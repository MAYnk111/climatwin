import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/currency_utils.dart';
import '../../core/api_client.dart';

class MarketScreen extends StatefulWidget {
  final ApiClient? apiClient;

  const MarketScreen({super.key, this.apiClient});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  int _selectedTab = 0; // 0: Indices, 1: Commodities, 2: Sectors

  double _currentFxRate = CurrencyFormatter.usdToInrRate;
  String _rateStatus = 'benchmark_fallback';
  String _rateSource = 'Standard Benchmark FX';
  String? _lastUpdated;
  bool _isLoadingRate = false;

  @override
  void initState() {
    super.initState();
    _fetchLiveFxRate();
  }

  Future<void> _fetchLiveFxRate() async {
    setState(() => _isLoadingRate = true);
    try {
      final client = widget.apiClient ?? ApiClient.instance;
      final record = await client.fetchMarketFxRate();
      final payload = record['payload'] as Map<String, dynamic>? ?? {};
      final rate = payload['exchange_rate'] as num?;
      final status = record['status'] as String? ?? 'benchmark_fallback';
      final attribution = record['attribution'] as Map<String, dynamic>? ?? {};
      final source = attribution['source_name'] as String? ?? 'Open Exchange Rates';
      final vintage = attribution['data_vintage'] as String? ?? 'Latest';

      if (mounted && rate != null) {
        setState(() {
          _currentFxRate = rate.toDouble();
          _rateStatus = status;
          _rateSource = source;
          _lastUpdated = vintage;
          _isLoadingRate = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingRate = false);
      }
    }
  }

  final List<Map<String, dynamic>> _indices = [
    {
      'name': 'NIFTY 50',
      'region': 'India (NSE)',
      'inrPrice': 24964.25,
      'change': 112.40,
      'changePct': 0.45,
      'isDomestic': true,
    },
    {
      'name': 'BSE SENSEX',
      'region': 'India (BSE)',
      'inrPrice': 81634.80,
      'change': 324.10,
      'changePct': 0.40,
      'isDomestic': true,
    },
    {
      'name': 'S&P 500',
      'region': 'US (NYSE)',
      'usdPrice': 5815.20,
      'change': 28.50,
      'changePct': 0.49,
      'isDomestic': false,
    },
    {
      'name': 'NASDAQ 100',
      'region': 'US (NASDAQ)',
      'usdPrice': 20240.00,
      'change': -84.30,
      'changePct': -0.41,
      'isDomestic': false,
    },
  ];

  final List<Map<String, dynamic>> _commodities = [
    {
      'name': 'Brent Crude Oil',
      'unit': 'per barrel',
      'usdPrice': 78.40,
      'changePct': 1.85,
      'climateRiskTag': 'Energy Transition & Freight',
      'riskLevel': 'High',
    },
    {
      'name': 'Lithium Carbonate',
      'unit': 'per metric ton',
      'usdPrice': 10450.00,
      'changePct': -2.10,
      'climateRiskTag': 'Battery & EV Supply Chains',
      'riskLevel': 'Critical',
    },
    {
      'name': 'Polysilicon (Solar Grade)',
      'unit': 'per kg',
      'usdPrice': 6.30,
      'changePct': 0.80,
      'climateRiskTag': 'Wafer Manufacturing & Grid',
      'riskLevel': 'High',
    },
    {
      'name': 'Copper Grade A',
      'unit': 'per pound',
      'usdPrice': 4.42,
      'changePct': 0.45,
      'climateRiskTag': 'Electrification & Data Centers',
      'riskLevel': 'Medium',
    },
    {
      'name': 'EU Carbon Allowance (EUA)',
      'unit': 'per tCO2e',
      'usdPrice': 71.50,
      'changePct': 3.20,
      'climateRiskTag': 'Regulatory CBAM Taxation',
      'riskLevel': 'Medium',
    },
  ];

  final List<Map<String, dynamic>> _sectors = [
    {
      'sector': 'Semiconductor Foundries',
      'riskScore': 82,
      'riskLevel': 'Critical',
      'inrCap': 125000000000.0, // In INR directly
      'hazard': 'Drought, Water rationing, Single-point fabrication',
    },
    {
      'sector': 'Automotive & Logistics',
      'riskScore': 68,
      'riskLevel': 'High',
      'inrCap': 94000000000.0,
      'hazard': 'River navigability, Freight delays, Battery inputs',
    },
    {
      'sector': 'Renewable Energy & Utilities',
      'riskScore': 46,
      'riskLevel': 'Medium',
      'inrCap': 68000000000.0,
      'hazard': 'Grid connection constraints, Wind volatility',
    },
    {
      'sector': 'Cloud & Enterprise Tech',
      'riskScore': 34,
      'riskLevel': 'Low',
      'inrCap': 210000000000.0,
      'hazard': 'Thermal stress on data centers, Power surges',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Markets & Commodities'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Standard Currency Benchmark Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ClimatwinTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ClimatwinTheme.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(Icons.currency_exchange, size: 20, color: ClimatwinTheme.accentTeal),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Normalized to Indian Rupee (₹)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ClimatwinTheme.textPrimary),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _rateStatus == 'live_verified'
                                    ? ClimatwinTheme.lightGreenSurface
                                    : ClimatwinTheme.surfaceCard,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: _rateStatus == 'live_verified'
                                      ? ClimatwinTheme.darkGreenPrimary
                                      : ClimatwinTheme.borderSubtle,
                                ),
                              ),
                              child: Text(
                                _rateStatus == 'live_verified' ? 'LIVE FX' : 'BENCHMARK FX',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: _rateStatus == 'live_verified'
                                      ? ClimatwinTheme.darkGreenPrimary
                                      : ClimatwinTheme.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '1 USD = ₹${_currentFxRate.toStringAsFixed(2)} • Source: $_rateSource (${_lastUpdated ?? "Fallback"})',
                          style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Tab Buttons
            Row(
              children: [
                _buildTabButton(0, 'Key Indices', Icons.stacked_line_chart),
                const SizedBox(width: 8),
                _buildTabButton(1, 'Commodities', Icons.diamond_outlined),
                const SizedBox(width: 8),
                _buildTabButton(2, 'Sectors', Icons.pie_chart_outline),
              ],
            ),
            const SizedBox(height: 14),

            // Content based on tab
            if (_selectedTab == 0) _buildIndicesView(),
            if (_selectedTab == 1) _buildCommoditiesView(),
            if (_selectedTab == 2) _buildSectorsView(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String title, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? ClimatwinTheme.darkGreenPrimary : ClimatwinTheme.surfaceCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? ClimatwinTheme.darkGreenPrimary : ClimatwinTheme.borderSubtle,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: isSelected ? Colors.white : ClimatwinTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : ClimatwinTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicesView() {
    return Column(
      children: _indices.map((idx) {
        final isDomestic = idx['isDomestic'] as bool;
        final double inrPrice = isDomestic
            ? (idx['inrPrice'] as num).toDouble()
            : (idx['usdPrice'] as num).toDouble() * CurrencyFormatter.usdToInrRate;
        final double changePct = (idx['changePct'] as num).toDouble();
        final bool isPositive = changePct >= 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        idx['name'] as String,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ClimatwinTheme.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${idx['region']} • ${isDomestic ? "Domestic Direct" : "Converted FX"}',
                        style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.formatPrice(inrPrice),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ClimatwinTheme.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                          size: 16,
                          color: isPositive ? ClimatwinTheme.riskLow : ClimatwinTheme.riskHigh,
                        ),
                        Text(
                          '${isPositive ? "+" : ""}${changePct.toStringAsFixed(2)}%',
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
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCommoditiesView() {
    return Column(
      children: _commodities.map((comm) {
        final double inrPrice = (comm['usdPrice'] as num).toDouble() * CurrencyFormatter.usdToInrRate;
        final double changePct = (comm['changePct'] as num).toDouble();
        final bool isPositive = changePct >= 0;
        final String riskLevel = comm['riskLevel'] as String;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comm['name'] as String,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ClimatwinTheme.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            comm['unit'] as String,
                            style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.formatPrice(inrPrice),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ClimatwinTheme.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                              size: 16,
                              color: isPositive ? ClimatwinTheme.riskLow : ClimatwinTheme.riskHigh,
                            ),
                            Text(
                              '${isPositive ? "+" : ""}${changePct.toStringAsFixed(2)}%',
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
                const Divider(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: ClimatwinTheme.getRiskColor(riskLevel).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$riskLevel Risk',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: ClimatwinTheme.getRiskColor(riskLevel),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        comm['climateRiskTag'] as String,
                        style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectorsView() {
    return Column(
      children: _sectors.map((sec) {
        final riskScore = sec['riskScore'] as int;
        final riskLevel = sec['riskLevel'] as String;
        final double inrCap = sec['inrCap'] as double;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      sec['sector'] as String,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ClimatwinTheme.textPrimary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: ClimatwinTheme.getRiskColor(riskLevel).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$riskScore/100',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: ClimatwinTheme.getRiskColor(riskLevel),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Estimated Climate Value-at-Risk: ${CurrencyFormatter.formatInr(inrCap)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ClimatwinTheme.accentTeal),
                ),
                const SizedBox(height: 6),
                Text(
                  'Key Drivers: ${sec['hazard']}',
                  style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textSecondary),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
