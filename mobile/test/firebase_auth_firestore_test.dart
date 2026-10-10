import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:climatwin_mobile/core/theme.dart';
import 'package:climatwin_mobile/core/auth_service.dart';
import 'package:climatwin_mobile/core/firestore_service.dart';
import 'package:climatwin_mobile/features/auth/auth_screen.dart';

void main() {
  group('1. AuthService Tests', () {
    test('Anonymous guest login creates user and updates currentUser', () async {
      final auth = AuthService.instance;
      final user = await auth.signInAnonymously();

      expect(user.uid, startsWith('guest_'));
      expect(user.email, 'guest@climatwin.local');
      expect(auth.currentUser?.uid, user.uid);

      await auth.signOut();
      expect(auth.currentUser, isNull);
    });

    test('Email and password sign up and sign in flow', () async {
      final auth = AuthService.instance;
      final user = await auth.createUserWithEmailAndPassword(
        email: 'risk.analyst@fund.com',
        password: 'securePassword123',
      );

      expect(user.email, 'risk.analyst@fund.com');
      expect(auth.currentUser?.email, 'risk.analyst@fund.com');

      await auth.signOut();
      expect(auth.currentUser, isNull);

      final loggedIn = await auth.signInWithEmailAndPassword(
        email: 'risk.analyst@fund.com',
        password: 'securePassword123',
      );
      expect(loggedIn.email, 'risk.analyst@fund.com');
      expect(auth.currentUser?.email, 'risk.analyst@fund.com');

      await auth.signOut();
    });
  });

  group('2. FirestoreService User-Scoped Persistence Tests', () {
    test('User-scoped watchlist persistence & data isolation', () async {
      final firestore = FirestoreService.instance;
      const userA = 'user_analyst_A';
      const userB = 'user_analyst_B';

      // User A saves TSMC
      await firestore.saveWatchlistItem(
        userId: userA,
        item: {
          'ticker': 'TSMC',
          'name': 'Taiwan Semiconductor',
          'risk_score': 84,
        },
      );

      // User B saves BMW
      await firestore.saveWatchlistItem(
        userId: userB,
        item: {
          'ticker': 'BMW.DE',
          'name': 'BMW Group',
          'risk_score': 58,
        },
      );

      final listA = await firestore.getWatchlist(userId: userA);
      final listB = await firestore.getWatchlist(userId: userB);

      expect(listA.any((item) => item['ticker'] == 'TSMC'), isTrue);
      expect(listA.any((item) => item['ticker'] == 'BMW.DE'), isFalse);

      expect(listB.any((item) => item['ticker'] == 'BMW.DE'), isTrue);
      expect(listB.any((item) => item['ticker'] == 'TSMC'), isFalse);

      // Remove from User A
      await firestore.removeWatchlistItem(userId: userA, ticker: 'TSMC');
      final listAAfter = await firestore.getWatchlist(userId: userA);
      expect(listAAfter.any((item) => item['ticker'] == 'TSMC'), isFalse);
    });

    test('User-scoped simulation scenarios and investigations persistence', () async {
      final firestore = FirestoreService.instance;
      const userA = 'user_scenario_tester';

      await firestore.saveSimulationScenario(
        userId: userA,
        scenarioId: 'scen_water_2026',
        scenarioName: 'East Asia Drought Stress',
        severityMultiplier: 2.2,
        durationMonths: 6,
        results: {
          'drawdown_pct': 5.8,
          'mitigation_savings_inr': 45000000.0,
        },
      );

      final saved = await firestore.getSavedScenarios(userId: userA);
      expect(saved.length, 1);
      expect(saved.first['scenario_id'], 'scen_water_2026');
      expect(saved.first['severity_multiplier'], 2.2);

      // Save investigation
      await firestore.saveInvestigation(
        userId: userA,
        investigationId: 'inv_drought_tsmc',
        targetNodeId: 'comp_tsmc',
        hazardTitle: 'Taiwan Baoshan Rationing',
        findings: {'portfolio_impact_pct': 4.2},
      );
    });
  });

  group('3. AuthScreen Widget Tests', () {
    testWidgets('Renders sign in / register form and guest login button', (tester) async {
      bool authSuccessTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ClimatwinTheme.darkTheme,
          home: AuthScreen(
            onAuthSuccess: () {
              authSuccessTriggered = true;
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sign In to CLIMATWIN'), findsOneWidget);
      expect(find.text('Firebase Cloud Authentication'), findsOneWidget);
      expect(find.text('Sign In'), findsWidgets);
      expect(find.text('Register'), findsOneWidget);
      expect(find.text('Continue as Guest Analyst'), findsOneWidget);

      // Tap Continue as Guest Analyst
      await tester.tap(find.text('Continue as Guest Analyst'));
      await tester.pumpAndSettle();

      expect(authSuccessTriggered, isTrue);
    });
  });
}
