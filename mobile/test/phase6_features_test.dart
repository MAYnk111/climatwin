import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:climatwin_mobile/core/auth_service.dart';
import 'package:climatwin_mobile/core/firestore_service.dart';
import 'package:climatwin_mobile/core/notification_service.dart';
import 'package:climatwin_mobile/core/theme.dart';
import 'package:climatwin_mobile/features/news/climate_news_screen.dart';
import 'package:climatwin_mobile/features/transparency/data_status_screen.dart';

void main() {
  group('1. Phase 6 AuthService & Error Mapping Tests', () {
    test('mapAuthError returns helpful user messages for typed auth errors', () {
      expect(
        AuthService.mapAuthError(Exception('user-not-found')),
        contains('user-not-found'),
      );
      expect(
        AuthService.instance.isAuthenticated,
        isFalse,
      );
    });

    test('AuthService password reset can be invoked safely in fallback mode', () async {
      await AuthService.instance.sendPasswordResetEmail(email: 'analyst@fund.com');
      expect(AuthService.instance.currentUser, isNull);
    });
  });

  group('2. Phase 6 Firestore User Profiles & Portfolios', () {
    final fs = FirestoreService.instance;

    test('Saves and retrieves user profile with isolation', () async {
      await fs.saveUserProfile(
        userId: 'analyst_42',
        profile: {
          'name': 'Jane Doe',
          'fund': 'Alpine Climate Ventures',
          'role': 'Senior ESG Analyst',
        },
      );

      final p = await fs.getUserProfile(userId: 'analyst_42');
      expect(p, isNotNull);
      expect(p!['name'], equals('Jane Doe'));
      expect(p['fund'], equals('Alpine Climate Ventures'));

      // Check other user doesn't see it
      final other = await fs.getUserProfile(userId: 'analyst_99');
      expect(other, isNull);
    });

    test('Saves and retrieves user portfolios under /users/{uid}/portfolios', () async {
      await fs.saveUserPortfolio(
        userId: 'analyst_42',
        portfolioId: 'port_tech_01',
        data: {
          'name': 'Taiwan Semi & Hardware Fund',
          'aum_usd': 350000000.0,
          'holdings_count': 12,
        },
      );

      final portfolios = await fs.getUserPortfolios(userId: 'analyst_42');
      expect(portfolios.length, equals(1));
      expect(portfolios.first['portfolio_id'], equals('port_tech_01'));
      expect(portfolios.first['name'], equals('Taiwan Semi & Hardware Fund'));
    });

    test('Returns diagnostics describing storage backend', () {
      final diag = fs.getDiagnostics();
      expect(diag.containsKey('backend'), isTrue);
      expect(diag['offlinePersistence'], isTrue);
    });
  });

  group('3. Phase 6 Notification Delivery & Diagnostics', () {
    test('NotificationDeliveryResult model integrity', () {
      const res = NotificationDeliveryResult(
        isPermissionGranted: true,
        isCreated: true,
        notificationId: 98765,
      );

      expect(res.isPermissionGranted, isTrue);
      expect(res.isCreated, isTrue);
      expect(res.notificationId, equals(98765));
      expect(res.errorMessage, isNull);
    });

    test('NotificationService diagnostics returns channel and init status', () async {
      final diag = await NotificationService.instance.getDiagnostics();
      expect(diag['channelKey'], equals('climatwin_alerts'));
      expect(diag['channelName'], equals('CLIMATWIN Climate Risk Alerts'));
    });
  });

  group('4. Phase 6 Screen Widget Tests', () {
    testWidgets('ClimateNewsScreen renders search, filter chips, and attribution banner', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClimatwinTheme.darkTheme,
          home: const ClimateNewsScreen(),
        ),
      );

      // Verify app bar title
      expect(find.text('Live Climate Disruption News'), findsOneWidget);

      // Verify topic preset chips
      expect(find.text('Taiwan Drought'), findsOneWidget);
      expect(find.text('Rhine River Shipping'), findsOneWidget);
      expect(find.text('Kaohsiung Port / Typhoon'), findsOneWidget);
    });

    testWidgets('DataStatusScreen renders pipeline architecture flowchart and audit trail', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClimatwinTheme.darkTheme,
          home: const DataStatusScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify audit trail header
      expect(find.text('Data Provenance & System Status'), findsOneWidget);
      expect(find.text('CLIMATWIN Enterprise Audit Trail'), findsOneWidget);
      expect(find.text('End-to-End Data Pipeline Architecture'), findsOneWidget);

      // Verify pipeline stage 1
      expect(find.text('1. External Climate & Supply Data Ingestion'), findsOneWidget);
      expect(find.text('2. FastAPI & NetworkX Dependency Engine'), findsOneWidget);
      expect(find.text('3. Quantitative Risk & Calibration Engine'), findsOneWidget);
      expect(find.text('4. LangGraph Workflow & Gemini Flash Synthesis'), findsOneWidget);
      expect(find.text('5. Investor Mobile Application & Alerts'), findsOneWidget);

      // Verify open data attribution notice
      expect(find.text('Open Data Attribution & Integrity Notice'), findsOneWidget);
    });
  });
}
