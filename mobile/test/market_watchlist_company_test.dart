import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:climatwin_mobile/core/theme.dart';
import 'package:climatwin_mobile/core/currency_utils.dart';
import 'package:climatwin_mobile/features/company/company_detail_screen.dart';
import 'package:climatwin_mobile/features/watchlist/watchlist_screen.dart';
import 'package:climatwin_mobile/features/market/market_screen.dart';
import 'package:climatwin_mobile/features/alerts/alerts_screen.dart';

void main() {
  group('1. CurrencyFormatter & FX Standard Tests', () {
    test('Converts USD to INR at standard 83.50 benchmark rate', () {
      expect(CurrencyFormatter.usdToInrRate, 83.50);
      expect(CurrencyFormatter.exchangeRateNote, contains('1 USD = ₹83.50'));

      // 10,000,000 USD = 835,000,000 INR = 83.5 Cr
      final formattedAum = CurrencyFormatter.formatUsdToInr(10000000);
      expect(formattedAum, contains('₹83.5'));
      expect(formattedAum, contains('Cr'));

      // 100 USD = 8,350 INR
      final formattedSmall = CurrencyFormatter.formatUsdToInr(100);
      expect(formattedSmall, contains('₹8.3k'));

      // Format Price
      expect(CurrencyFormatter.formatPrice(24964.25), '₹24964.25');
    });

    test('Formats Lakhs and Crores accurately', () {
      expect(CurrencyFormatter.formatInr(500000), '₹5.0 L');
      expect(CurrencyFormatter.formatInr(25000000), '₹2.50 Cr');
      expect(CurrencyFormatter.formatInr(1200000000), '₹120.0 Cr');
    });
  });

  group('2. CompanyDetailScreen Widget Tests', () {
    testWidgets('Renders ticker, INR price, candlestick chart, and risk factors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClimatwinTheme.darkTheme,
          home: const CompanyDetailScreen(
            ticker: 'NVDA',
            name: 'NVIDIA Corporation',
            sector: 'Semiconductors',
            basePriceUsd: 118.20,
            climateRiskScore: 79,
            riskLevel: 'High',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header and Ticker check
      expect(find.text('NVDA • Overview'), findsOneWidget);
      expect(find.text('NVIDIA Corporation'), findsOneWidget);
      expect(find.text('Semiconductors'), findsOneWidget);

      // Price converted to INR: 118.20 * 83.50 approx ₹9870
      expect(find.textContaining('₹'), findsWidgets);
      expect(find.textContaining('1 USD = ₹83.50'), findsOneWidget);

      // Timeframe buttons
      expect(find.text('1D'), findsOneWidget);
      expect(find.text('1W'), findsOneWidget);
      expect(find.text('1M'), findsOneWidget);
      expect(find.text('1Y'), findsOneWidget);

      // Climate Risk profile
      expect(find.text('CLIMATE RISK PROFILE'), findsOneWidget);
      expect(find.textContaining('79/100'), findsOneWidget);
      expect(find.text('Physical Water Stress'), findsOneWidget);

      // Action buttons
      expect(find.text('View in Graph'), findsOneWidget);
      expect(find.text('Simulate Shock'), findsOneWidget);
    });
  });

  group('3. WatchlistScreen Widget Tests', () {
    testWidgets('Renders watchlist assets, allows searching and alerts config', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClimatwinTheme.darkTheme,
          home: const WatchlistScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Screen title and benchmark note
      expect(find.text('Portfolio Watchlist'), findsOneWidget);
      expect(find.textContaining('1 USD = ₹83.50'), findsOneWidget);

      // Default assets rendered
      expect(find.text('NVDA'), findsOneWidget);
      expect(find.text('AAPL'), findsOneWidget);
      expect(find.text('TSMC'), findsOneWidget);

      // Search functionality
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'TSMC');
      await tester.pumpAndSettle();

      expect(find.text('Taiwan Semiconductor Mfg.'), findsOneWidget);
      expect(find.text('Apple Inc.'), findsNothing);

      // Clear search
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();
      expect(find.text('Apple Inc.'), findsOneWidget);

      // Tap alert rules icon on first asset
      final alertIcon = find.byIcon(Icons.notifications_active_outlined).first;
      await tester.tap(alertIcon);
      await tester.pumpAndSettle();

      // Alert preferences bottom sheet
      expect(find.textContaining('Configure Alerts'), findsOneWidget);
      expect(find.textContaining('Price Movement Trigger'), findsOneWidget);
      expect(find.text('Save Alert Preferences'), findsOneWidget);
    });
  });

  group('4. MarketScreen Widget Tests', () {
    testWidgets('Renders indices, commodities, and sectors with INR pricing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClimatwinTheme.darkTheme,
          home: const MarketScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Header and Currency Disclaimer
      expect(find.text('Markets & Commodities'), findsOneWidget);
      expect(find.text('Normalized to Indian Rupee (₹)'), findsOneWidget);

      // Key Indices Tab
      expect(find.text('NIFTY 50'), findsOneWidget);
      expect(find.text('BSE SENSEX'), findsOneWidget);
      expect(find.text('S&P 500'), findsOneWidget);

      // Switch to Commodities Tab
      await tester.tap(find.text('Commodities'));
      await tester.pumpAndSettle();

      expect(find.text('Brent Crude Oil'), findsOneWidget);
      expect(find.text('Lithium Carbonate'), findsOneWidget);
      expect(find.text('Copper Grade A'), findsOneWidget);

      // Switch to Sectors Tab
      await tester.tap(find.text('Sectors'));
      await tester.pumpAndSettle();

      expect(find.text('Semiconductor Foundries'), findsOneWidget);
      expect(find.text('Automotive & Logistics'), findsOneWidget);
      expect(find.textContaining('Climate Value-at-Risk'), findsWidgets);
    });
  });

  group('5. AlertsScreen Widget Tests', () {
    testWidgets('Renders alert items, severity filter chips, and investigate triggers', (tester) async {
      bool investigateTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ClimatwinTheme.darkTheme,
          home: AlertsScreen(
            onInvestigateAlert: (nodeId, title) {
              investigateTriggered = true;
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Screen title and Filter Chips
      expect(find.text('Climate & Supply Alerts'), findsOneWidget);
      expect(find.textContaining('All ('), findsOneWidget);
      expect(find.textContaining('Critical'), findsWidgets);

      // Verify specific alert titles
      expect(find.text('Taiwan Baoshan Reservoir Stage 2 Water Rationing'), findsOneWidget);
      expect(find.textContaining('Rhine River'), findsOneWidget);

      // Tap Investigate Propagation button
      final investigateBtn = find.text('Investigate Propagation').first;
      await tester.tap(investigateBtn);
      await tester.pumpAndSettle();

      expect(investigateTriggered, isTrue);
    });
  });
}
