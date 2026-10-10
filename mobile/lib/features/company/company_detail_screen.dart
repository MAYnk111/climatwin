import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/currency_utils.dart';

class CompanyDetailScreen extends StatefulWidget {
  final String ticker;
  final String name;
  final String sector;
  final double basePriceUsd;
  final int climateRiskScore;
  final String riskLevel;
  final VoidCallback? onInspectGraph;
  final VoidCallback? onSimulate;
  final VoidCallback? onInvestigate;

  const CompanyDetailScreen({
    super.key,
    required this.ticker,
    required this.name,
    this.sector = 'Technology & Hardware',
    this.basePriceUsd = 124.50,
    this.climateRiskScore = 74,
    this.riskLevel = 'High',
    this.onInspectGraph,
    this.onSimulate,
    this.onInvestigate,
  });

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen> {
  String _selectedTimeframe = '1M';
  bool _showCandlesticks = true;
  bool _isWatchlisted = true;
  int? _hoveredIndex;

  late List<_CandleData> _candles;

  @override
  void initState() {
    super.initState();
    _candles = _generateMarketData(widget.basePriceUsd, _selectedTimeframe);
  }

  void _onTimeframeChanged(String tf) {
    setState(() {
      _selectedTimeframe = tf;
      _candles = _generateMarketData(widget.basePriceUsd, tf);
      _hoveredIndex = null;
    });
  }

  List<_CandleData> _generateMarketData(double baseUsd, String timeframe) {
    final int count = switch (timeframe) {
      '1D' => 24,
      '1W' => 28,
      '1M' => 30,
      '1Y' => 52,
      _ => 30,
    };

    final random = math.Random(widget.ticker.hashCode ^ timeframe.hashCode);
    double currentInr = baseUsd * CurrencyFormatter.usdToInrRate;
    final List<_CandleData> list = [];

    for (int i = 0; i < count; i++) {
      final changePercent = (random.nextDouble() - 0.48) * 0.04;
      final open = currentInr;
      final close = open * (1 + changePercent);
      final high = math.max(open, close) * (1 + random.nextDouble() * 0.015);
      final low = math.min(open, close) * (1 - random.nextDouble() * 0.015);
      final volume = 50000 + random.nextInt(250000);

      list.add(_CandleData(
        index: i,
        open: open,
        high: high,
        low: low,
        close: close,
        volume: volume.toDouble(),
        dateLabel: 'P$i',
      ));
      currentInr = close;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final currentCandle = _hoveredIndex != null && _hoveredIndex! < _candles.length
        ? _candles[_hoveredIndex!]
        : _candles.last;

    final double priceChange = _candles.last.close - _candles.first.open;
    final double pctChange = (priceChange / _candles.first.open) * 100;
    final bool isPositive = priceChange >= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.ticker} • Overview'),
        actions: [
          IconButton(
            icon: Icon(
              _isWatchlisted ? Icons.bookmark : Icons.bookmark_border,
              color: _isWatchlisted ? ClimatwinTheme.darkGreenPrimary : ClimatwinTheme.textMuted,
            ),
            tooltip: _isWatchlisted ? 'Remove from Watchlist' : 'Add to Watchlist',
            onPressed: () {
              setState(() {
                _isWatchlisted = !_isWatchlisted;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isWatchlisted
                      ? '${widget.ticker} added to Watchlist'
                      : '${widget.ticker} removed from Watchlist'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Header Banner
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: ClimatwinTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: ClimatwinTheme.borderSubtle),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.ticker,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: ClimatwinTheme.darkGreenPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: ClimatwinTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: ClimatwinTheme.surfaceElevated,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  widget.sector,
                                  style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textSecondary),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('•  NSE / NASDAQ Listed',
                                  style: TextStyle(fontSize: 11, color: ClimatwinTheme.textMuted)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Price & Benchmark Conversion Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          CurrencyFormatter.formatPrice(currentCandle.close),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: ClimatwinTheme.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                          color: isPositive ? ClimatwinTheme.riskLow : ClimatwinTheme.riskHigh,
                          size: 24,
                        ),
                        Text(
                          '${isPositive ? "+" : ""}${pctChange.toStringAsFixed(2)}% (${CurrencyFormatter.formatPrice(priceChange.abs())})',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isPositive ? ClimatwinTheme.riskLow : ClimatwinTheme.riskHigh,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.currency_exchange, size: 14, color: ClimatwinTheme.accentTeal),
                        const SizedBox(width: 6),
                        Text(
                          CurrencyFormatter.exchangeRateNote,
                          style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textMuted),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ClimatwinTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Demo Market Feed',
                            style: TextStyle(fontSize: 10, color: ClimatwinTheme.textMuted),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Timeframe and Chart Type Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: ['1D', '1W', '1M', '1Y'].map((tf) {
                            final isSel = tf == _selectedTimeframe;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: InkWell(
                                onTap: () => _onTimeframeChanged(tf),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSel ? ClimatwinTheme.darkGreenPrimary : ClimatwinTheme.surfaceElevated,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    tf,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                      color: isSel ? Colors.white : ClimatwinTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.candlestick_chart,
                                color: _showCandlesticks ? ClimatwinTheme.darkGreenPrimary : ClimatwinTheme.textMuted,
                                size: 20,
                              ),
                              tooltip: 'Candlestick Chart',
                              onPressed: () => setState(() => _showCandlesticks = true),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.show_chart,
                                color: !_showCandlesticks ? ClimatwinTheme.darkGreenPrimary : ClimatwinTheme.textMuted,
                                size: 20,
                              ),
                              tooltip: 'Area Chart',
                              onPressed: () => setState(() => _showCandlesticks = false),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Interactive Chart Canvas
                    SizedBox(
                      height: 200,
                      child: GestureDetector(
                        onHorizontalDragUpdate: (details) {
                          final RenderBox box = context.findRenderObject() as RenderBox;
                          final localX = details.localPosition.dx;
                          final ratio = (localX / box.size.width).clamp(0.0, 1.0);
                          final index = (ratio * (_candles.length - 1)).round();
                          setState(() => _hoveredIndex = index);
                        },
                        onTapDown: (details) {
                          final RenderBox box = context.findRenderObject() as RenderBox;
                          final localX = details.localPosition.dx;
                          final ratio = (localX / box.size.width).clamp(0.0, 1.0);
                          final index = (ratio * (_candles.length - 1)).round();
                          setState(() => _hoveredIndex = index);
                        },
                        child: CustomPaint(
                          size: const Size(double.infinity, 200),
                          painter: _StockChartPainter(
                            candles: _candles,
                            showCandlesticks: _showCandlesticks,
                            hoveredIndex: _hoveredIndex,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Climate Risk Breakdown Card
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
                          'CLIMATE RISK PROFILE',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ClimatwinTheme.textMuted),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: ClimatwinTheme.getRiskColor(widget.riskLevel).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${widget.riskLevel.toUpperCase()} RISK (${widget.climateRiskScore}/100)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: ClimatwinTheme.getRiskColor(widget.riskLevel),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildRiskFactorRow(
                      'Physical Water Stress',
                      'High exposure at Tier-1 wafer fabrication fabs (Hsinchu / Tainan).',
                      82,
                      ClimatwinTheme.riskCritical,
                    ),
                    const SizedBox(height: 10),
                    _buildRiskFactorRow(
                      'Supply Chain Logistics',
                      'Moderate transit fragility via Taiwan Strait & Malacca corridors.',
                      64,
                      ClimatwinTheme.riskMedium,
                    ),
                    const SizedBox(height: 10),
                    _buildRiskFactorRow(
                      'Carbon Border Adjustment',
                      'Low exposure due to high value-to-mass semiconductor ratio.',
                      35,
                      ClimatwinTheme.riskLow,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Navigation and Exploration Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ClimatwinTheme.textPrimary,
                      side: const BorderSide(color: ClimatwinTheme.borderSubtle),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.account_tree_outlined, size: 18, color: ClimatwinTheme.darkGreenPrimary),
                    label: const Text('View in Graph', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    onPressed: widget.onInspectGraph ?? () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ClimatwinTheme.darkGreenPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.science_outlined, size: 18),
                    label: const Text('Simulate Shock', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    onPressed: widget.onSimulate ?? () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskFactorRow(String title, String subtitle, int score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ClimatwinTheme.textPrimary)),
            Text('$score%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: score / 100.0,
            backgroundColor: ClimatwinTheme.surfaceElevated,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: ClimatwinTheme.textSecondary)),
      ],
    );
  }
}

class _CandleData {
  final int index;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final String dateLabel;

  _CandleData({
    required this.index,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.dateLabel,
  });
}

class _StockChartPainter extends CustomPainter {
  final List<_CandleData> candles;
  final bool showCandlesticks;
  final int? hoveredIndex;

  _StockChartPainter({
    required this.candles,
    required this.showCandlesticks,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    double minPrice = double.infinity;
    double maxPrice = -double.infinity;
    double maxVol = 0;

    for (var c in candles) {
      if (c.low < minPrice) minPrice = c.low;
      if (c.high > maxPrice) maxPrice = c.high;
      if (c.volume > maxVol) maxVol = c.volume;
    }

    final double priceRange = math.max(1.0, maxPrice - minPrice);
    final double chartHeight = size.height * 0.75;
    final double volumeHeight = size.height * 0.20;
    final double candleWidth = (size.width / candles.length) * 0.65;
    final double stepX = size.width / (candles.length - 1);

    // Subtle Grid Lines
    final gridPaint = Paint()
      ..color = ClimatwinTheme.borderSubtle.withOpacity(0.5)
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 3; i++) {
      final y = chartHeight * (i / 4.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (showCandlesticks) {
      // Candlestick rendering
      for (int i = 0; i < candles.length; i++) {
        final c = candles[i];
        final x = i * stepX;
        final isBullish = c.close >= c.open;
        final color = isBullish ? ClimatwinTheme.riskLow : ClimatwinTheme.riskHigh;

        final yHigh = chartHeight - ((c.high - minPrice) / priceRange) * chartHeight;
        final yLow = chartHeight - ((c.low - minPrice) / priceRange) * chartHeight;
        final yOpen = chartHeight - ((c.open - minPrice) / priceRange) * chartHeight;
        final yClose = chartHeight - ((c.close - minPrice) / priceRange) * chartHeight;

        // Wick
        final wickPaint = Paint()
          ..color = color
          ..strokeWidth = 1.5;
        canvas.drawLine(Offset(x, yHigh), Offset(x, yLow), wickPaint);

        // Body
        final bodyTop = math.min(yOpen, yClose);
        final bodyBottom = math.max(yOpen, yClose);
        final bodyHeight = math.max(2.0, bodyBottom - bodyTop);

        final bodyPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, bodyTop + bodyHeight / 2), width: candleWidth, height: bodyHeight),
            const Radius.circular(2),
          ),
          bodyPaint,
        );

        // Volume Bar
        final vHeight = (c.volume / (maxVol == 0 ? 1 : maxVol)) * volumeHeight;
        final volPaint = Paint()
          ..color = color.withOpacity(0.35)
          ..style = PaintingStyle.fill;
        canvas.drawRect(
          Rect.fromLTWH(x - candleWidth / 2, size.height - vHeight, candleWidth, vHeight),
          volPaint,
        );
      }
    } else {
      // Area Chart (Line + Gradient fill)
      final path = Path();
      final fillPath = Path();

      for (int i = 0; i < candles.length; i++) {
        final c = candles[i];
        final x = i * stepX;
        final y = chartHeight - ((c.close - minPrice) / priceRange) * chartHeight;

        if (i == 0) {
          path.moveTo(x, y);
          fillPath.moveTo(x, chartHeight);
          fillPath.lineTo(x, y);
        } else {
          path.lineTo(x, y);
          fillPath.lineTo(x, y);
        }
      }

      fillPath.lineTo(size.width, chartHeight);
      fillPath.close();

      final gradientPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ClimatwinTheme.darkGreenPrimary.withOpacity(0.35),
            ClimatwinTheme.darkGreenPrimary.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight))
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, gradientPaint);

      final linePaint = Paint()
        ..color = ClimatwinTheme.darkGreenPrimary
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, linePaint);
    }

    // Hover Indicator
    if (hoveredIndex != null && hoveredIndex! < candles.length) {
      final hx = hoveredIndex! * stepX;
      final hoverPaint = Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(hx, 0), Offset(hx, size.height), hoverPaint);

      final c = candles[hoveredIndex!];
      final hy = chartHeight - ((c.close - minPrice) / priceRange) * chartHeight;
      canvas.drawCircle(Offset(hx, hy), 4.5, Paint()..color = ClimatwinTheme.darkGreenPrimary);
      canvas.drawCircle(Offset(hx, hy), 2.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _StockChartPainter oldDelegate) => true;
}
