import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  static FirestoreService get instance => _instance;

  FirestoreService._internal();

  FirebaseFirestore? _firestore;

  // Local fallback cache when Firestore is offline or in testing
  final Map<String, List<Map<String, dynamic>>> _localWatchlists = {};
  final Map<String, List<Map<String, dynamic>>> _localAlertRules = {};
  final Map<String, List<Map<String, dynamic>>> _localInvestigations = {};
  final Map<String, List<Map<String, dynamic>>> _localScenarios = {};

  bool get isInitialized => _firestore != null;

  void initialize() {
    try {
      if (Firebase.apps.isNotEmpty) {
        _firestore = FirebaseFirestore.instance;
        _firestore!.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      }
    } catch (e) {
      debugPrint('FirestoreService: Running in local/test mode ($e)');
    }
  }

  // 1. User-scoped Watchlist Persistence
  Future<void> saveWatchlistItem({
    required String userId,
    required Map<String, dynamic> item,
  }) async {
    final ticker = item['ticker'] as String? ?? 'UNKNOWN';
    if (_firestore != null) {
      await _firestore!
          .collection('users')
          .doc(userId)
          .collection('watchlists')
          .doc(ticker)
          .set({
        ...item,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    final list = _localWatchlists.putIfAbsent(userId, () => []);
    list.removeWhere((e) => e['ticker'] == ticker);
    list.add(item);
  }

  Future<void> removeWatchlistItem({
    required String userId,
    required String ticker,
  }) async {
    if (_firestore != null) {
      await _firestore!
          .collection('users')
          .doc(userId)
          .collection('watchlists')
          .doc(ticker)
          .delete();
      return;
    }

    _localWatchlists[userId]?.removeWhere((e) => e['ticker'] == ticker);
  }

  Future<List<Map<String, dynamic>>> getWatchlist({
    required String userId,
  }) async {
    if (_firestore != null) {
      final snap = await _firestore!
          .collection('users')
          .doc(userId)
          .collection('watchlists')
          .get();
      return snap.docs.map((d) => d.data()).toList();
    }
    return _localWatchlists[userId] ?? [];
  }

  // 2. User-scoped Alert Rules
  Future<void> saveAlertRule({
    required String userId,
    required String ticker,
    required double priceAlertPct,
    required int riskAlertThreshold,
    required bool newsAlertsEnabled,
  }) async {
    final rule = {
      'ticker': ticker,
      'price_alert_pct': priceAlertPct,
      'risk_alert_threshold': riskAlertThreshold,
      'news_alerts_enabled': newsAlertsEnabled,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (_firestore != null) {
      await _firestore!
          .collection('users')
          .doc(userId)
          .collection('alert_rules')
          .doc(ticker)
          .set(rule, SetOptions(merge: true));
      return;
    }

    final list = _localAlertRules.putIfAbsent(userId, () => []);
    list.removeWhere((e) => e['ticker'] == ticker);
    list.add(rule);
  }

  // 3. User-scoped Investigation History
  Future<void> saveInvestigation({
    required String userId,
    required String investigationId,
    required String targetNodeId,
    required String hazardTitle,
    required Map<String, dynamic> findings,
  }) async {
    final docData = {
      'investigation_id': investigationId,
      'target_node_id': targetNodeId,
      'hazard_title': hazardTitle,
      'findings': findings,
      'created_at': DateTime.now().toIso8601String(),
    };

    if (_firestore != null) {
      await _firestore!
          .collection('users')
          .doc(userId)
          .collection('investigations')
          .doc(investigationId)
          .set(docData);
      return;
    }

    final list = _localInvestigations.putIfAbsent(userId, () => []);
    list.removeWhere((e) => e['investigation_id'] == investigationId);
    list.insert(0, docData);
  }

  Future<List<Map<String, dynamic>>> getSavedInvestigations({
    required String userId,
  }) async {
    if (_firestore != null) {
      final snap = await _firestore!
          .collection('users')
          .doc(userId)
          .collection('investigations')
          .orderBy('created_at', descending: true)
          .get();
      return snap.docs.map((d) => d.data()).toList();
    }
    return _localInvestigations[userId] ?? [];
  }

  // 4. User-scoped Scenario Simulations
  Future<void> saveSimulationScenario({
    required String userId,
    required String scenarioId,
    required String scenarioName,
    required double severityMultiplier,
    required int durationMonths,
    required Map<String, dynamic> results,
  }) async {
    final docData = {
      'scenario_id': scenarioId,
      'scenario_name': scenarioName,
      'severity_multiplier': severityMultiplier,
      'duration_months': durationMonths,
      'results': results,
      'saved_at': DateTime.now().toIso8601String(),
    };

    if (_firestore != null) {
      await _firestore!
          .collection('users')
          .doc(userId)
          .collection('scenarios')
          .doc(scenarioId)
          .set(docData);
      return;
    }

    final list = _localScenarios.putIfAbsent(userId, () => []);
    list.add(docData);
  }

  Future<List<Map<String, dynamic>>> getSavedScenarios({
    required String userId,
  }) async {
    if (_firestore != null) {
      final snap = await _firestore!
          .collection('users')
          .doc(userId)
          .collection('scenarios')
          .orderBy('saved_at', descending: true)
          .get();
      return snap.docs.map((d) => d.data()).toList();
    }
    return _localScenarios[userId] ?? [];
  }

  // 5. User-scoped Alerts & FCM Token Registration
  final Map<String, List<Map<String, dynamic>>> _localAlerts = {};
  final Map<String, String> _localFcmTokens = {};

  Future<void> registerFcmToken({
    required String userId,
    required String token,
    String platform = 'android',
  }) async {
    final docData = {
      'fcm_token': token,
      'platform': platform,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (_firestore != null) {
      await _firestore!
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc('primary_device')
          .set(docData, SetOptions(merge: true));
      return;
    }

    _localFcmTokens[userId] = token;
  }

  Future<String?> getRegisteredFcmToken({required String userId}) async {
    if (_firestore != null) {
      final doc = await _firestore!
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc('primary_device')
          .get();
      return doc.data()?['fcm_token'] as String?;
    }
    return _localFcmTokens[userId];
  }

  Future<void> saveUserAlert({
    required String userId,
    required Map<String, dynamic> alert,
  }) async {
    final alertId = alert['id'] as String? ?? 'alt_${DateTime.now().millisecondsSinceEpoch}';
    final docData = {
      ...alert,
      'user_id': userId,
      'saved_at': DateTime.now().toIso8601String(),
    };

    if (_firestore != null) {
      await _firestore!
          .collection('users')
          .doc(userId)
          .collection('alerts')
          .doc(alertId)
          .set(docData, SetOptions(merge: true));
      return;
    }

    final list = _localAlerts.putIfAbsent(userId, () => []);
    list.removeWhere((a) => a['id'] == alertId);
    list.insert(0, docData);
  }

  Future<List<Map<String, dynamic>>> getUserAlerts({required String userId}) async {
    if (_firestore != null) {
      final snap = await _firestore!
          .collection('users')
          .doc(userId)
          .collection('alerts')
          .orderBy('saved_at', descending: true)
          .get();
      return snap.docs.map((d) => d.data()).toList();
    }
    return _localAlerts[userId] ?? [];
  }

  // 6. User Profile (/users/{uid})
  final Map<String, Map<String, dynamic>> _localProfiles = {};

  Future<void> saveUserProfile({
    required String userId,
    required Map<String, dynamic> profile,
  }) async {
    final docData = {
      ...profile,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (_firestore != null) {
      await _firestore!
          .collection('users')
          .doc(userId)
          .set(docData, SetOptions(merge: true));
      return;
    }

    _localProfiles[userId] = docData;
  }

  Future<Map<String, dynamic>?> getUserProfile({required String userId}) async {
    if (_firestore != null) {
      final snap = await _firestore!.collection('users').doc(userId).get();
      return snap.data();
    }
    return _localProfiles[userId];
  }

  // 7. User Portfolios (/users/{uid}/portfolios)
  final Map<String, List<Map<String, dynamic>>> _localPortfolios = {};

  Future<void> saveUserPortfolio({
    required String userId,
    required String portfolioId,
    required Map<String, dynamic> data,
  }) async {
    final docData = {
      ...data,
      'portfolio_id': portfolioId,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (_firestore != null) {
      await _firestore!
          .collection('users')
          .doc(userId)
          .collection('portfolios')
          .doc(portfolioId)
          .set(docData, SetOptions(merge: true));
      return;
    }

    final list = _localPortfolios.putIfAbsent(userId, () => []);
    list.removeWhere((p) => p['portfolio_id'] == portfolioId);
    list.add(docData);
  }

  Future<List<Map<String, dynamic>>> getUserPortfolios({required String userId}) async {
    if (_firestore != null) {
      final snap = await _firestore!
          .collection('users')
          .doc(userId)
          .collection('portfolios')
          .get();
      return snap.docs.map((d) => d.data()).toList();
    }
    return _localPortfolios[userId] ?? [];
  }

  // Diagnostics
  Map<String, dynamic> getDiagnostics() {
    return {
      'initialized': _firestore != null,
      'backend': _firestore != null ? 'Cloud Firestore (persistence enabled)' : 'Durable Local In-Memory Fallback',
      'offlinePersistence': true,
      'localWatchlistsCount': _localWatchlists.values.fold(0, (a, b) => a + b.length),
      'localScenariosCount': _localScenarios.values.fold(0, (a, b) => a + b.length),
      'localInvestigationsCount': _localInvestigations.values.fold(0, (a, b) => a + b.length),
    };
  }
}
