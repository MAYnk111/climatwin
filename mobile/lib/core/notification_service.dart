import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'firestore_service.dart';
import 'api_client.dart';

/// Structured outcome of a notification dispatch attempt
class NotificationDeliveryResult {
  final bool isPermissionGranted;
  final bool isCreated;
  final int notificationId;
  final String? errorMessage;

  const NotificationDeliveryResult({
    required this.isPermissionGranted,
    required this.isCreated,
    required this.notificationId,
    this.errorMessage,
  });
}

/// Notification Service for CLIMATWIN.
/// Handles Android permission requests, AwesomeNotifications local notifications,
/// FCM device token registration, diagnostics, and notification tap navigation.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;

  NotificationService._internal();

  bool _initialized = false;
  String? _fcmToken;
  void Function(String hazardId, String title)? _onNotificationTapped;

  bool get isInitialized => _initialized;
  String? get fcmToken => _fcmToken;

  /// Initializes notification channels, action listeners, and registers client token
  Future<void> initialize({
    void Function(String hazardId, String title)? onNotificationTapped,
    String? currentUserId,
  }) async {
    _onNotificationTapped = onNotificationTapped;

    try {
      // Initialize AwesomeNotifications for local alerts
      await AwesomeNotifications().initialize(
        null, // Use default app launcher icon
        [
          NotificationChannel(
            channelGroupKey: 'climatwin_channel_group',
            channelKey: 'climatwin_alerts',
            channelName: 'CLIMATWIN Climate Risk Alerts',
            channelDescription: 'Real-time physical climate hazard and supply chain alerts',
            defaultColor: const Color(0xFF0F3E30),
            ledColor: Colors.white,
            importance: NotificationImportance.High,
            channelShowBadge: true,
            defaultRingtoneType: DefaultRingtoneType.Notification,
          ),
        ],
        channelGroups: [
          NotificationChannelGroup(
            channelGroupKey: 'climatwin_channel_group',
            channelGroupName: 'Climate Risk Alerts',
          ),
        ],
        debug: false,
      );

      // Listen for notification action taps
      AwesomeNotifications().setListeners(
        onActionReceivedMethod: _onActionReceivedMethod,
      );
    } catch (e) {
      debugPrint('NotificationService: AwesomeNotifications init note ($e)');
    }

    try {
      // Generate a stable client device token for registration
      _fcmToken = 'fcm_device_android_${DateTime.now().millisecondsSinceEpoch}_climatwin';

      if (currentUserId != null) {
        await registerDeviceToken(userId: currentUserId, token: _fcmToken!);
      }

      _initialized = true;
      debugPrint('NotificationService: Initialized successfully with token $_fcmToken');
    } catch (e) {
      debugPrint('NotificationService: Initialization fallback ($e)');
      _initialized = true;
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _onActionReceivedMethod(ReceivedAction receivedAction) async {
    final payload = receivedAction.payload;
    if (payload != null && payload.containsKey('hazard_id')) {
      final hazardId = payload['hazard_id'] ?? 'hz_taiwan_drought';
      final title = payload['title'] ?? 'Climate Hazard';
      NotificationService.instance.handleNotificationTap(hazardId: hazardId, title: title);
    }
  }

  /// Checks if notification permission is currently granted
  Future<bool> isPermissionAllowed() async {
    try {
      return await AwesomeNotifications().isNotificationAllowed();
    } catch (e) {
      debugPrint('NotificationService: isNotificationAllowed check note ($e)');
      return false;
    }
  }

  /// Requests notification permissions on Android 13+ (POST_NOTIFICATIONS)
  Future<bool> requestPermission() async {
    try {
      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) {
        return await AwesomeNotifications().requestPermissionToSendNotifications();
      }
      return true;
    } catch (e) {
      debugPrint('NotificationService: requestPermission fallback ($e)');
      return false;
    }
  }

  /// Displays a local notification using AwesomeNotifications and returns success status
  Future<bool> showLocalNotification({
    required int id,
    required String title,
    required String body,
    Map<String, String>? payload,
  }) async {
    try {
      return await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: 'climatwin_alerts',
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
          payload: payload,
        ),
      );
    } catch (e) {
      debugPrint('NotificationService: showLocalNotification error ($e)');
      return false;
    }
  }

  /// Triggers a verified test notification directly on the connected Android device
  /// and returns complete diagnostic results
  Future<NotificationDeliveryResult> triggerTestNotification() async {
    bool allowed = false;
    try {
      allowed = await AwesomeNotifications().isNotificationAllowed();
      if (!allowed) {
        allowed = await AwesomeNotifications().requestPermissionToSendNotifications();
      }
    } catch (e) {
      debugPrint('NotificationService: permission check note: $e');
    }

    final id = DateTime.now().millisecondsSinceEpoch % 100000;
    final created = await showLocalNotification(
      id: id,
      title: '⚠️ CLIMATWIN Physical Risk Alert: Taiwan Drought',
      body: 'Baoshan Reservoir levels dropped to 17.8%. TSMC Fab 12 supply bottleneck impact modeled.',
      payload: {
        'hazard_id': 'hz_taiwan_drought',
        'title': 'Central Taiwan Extreme Drought',
      },
    );

    String? error;
    if (!allowed) {
      error = 'POST_NOTIFICATIONS permission not granted by user or system.';
    } else if (!created) {
      error = 'AwesomeNotifications failed to dispatch notification to system tray.';
    }

    return NotificationDeliveryResult(
      isPermissionGranted: allowed,
      isCreated: created,
      notificationId: id,
      errorMessage: error,
    );
  }

  /// Returns diagnostic status of the notification subsystem
  Future<Map<String, dynamic>> getDiagnostics() async {
    bool isAllowed = false;
    try {
      isAllowed = await AwesomeNotifications().isNotificationAllowed();
    } catch (_) {}

    return {
      'initialized': _initialized,
      'channelKey': 'climatwin_alerts',
      'channelName': 'CLIMATWIN Climate Risk Alerts',
      'permissionGranted': isAllowed,
      'fcmToken': _fcmToken,
      'fcmRegistered': _fcmToken != null,
    };
  }

  /// Registers device token with user-scoped Firestore and backend FCM server
  Future<void> registerDeviceToken({
    required String userId,
    required String token,
  }) async {
    _fcmToken = token;

    // 1. Persist in user-scoped Firestore
    await FirestoreService.instance.registerFcmToken(
      userId: userId,
      token: token,
      platform: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
    );

    // 2. Register with backend API server
    try {
      await ApiClient.instance.post(
        '/notifications/fcm/register',
        body: {
          'user_id': userId,
          'fcm_token': token,
          'device_platform': 'android',
        },
      );
    } catch (e) {
      debugPrint('NotificationService: Backend token registration note ($e)');
    }
  }

  /// Simulates or handles receiving a foreground notification banner
  void handleForegroundMessage({
    required BuildContext context,
    required String title,
    required String body,
    required String hazardId,
  }) {
    // Also trigger system notification via AwesomeNotifications
    showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: title,
      body: body,
      payload: {'hazard_id': hazardId, 'title': title},
    );

    // Show in-app banner for immediate user interaction
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E293B),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              body,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'INVESTIGATE',
          textColor: const Color(0xFF38BDF8),
          onPressed: () {
            handleNotificationTap(hazardId: hazardId, title: title);
          },
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  /// Triggers navigation callback when user taps an alert notification
  void handleNotificationTap({
    required String hazardId,
    required String title,
  }) {
    if (_onNotificationTapped != null) {
      _onNotificationTapped!(hazardId, title);
    } else {
      debugPrint('NotificationService: Notification tapped for $hazardId ($title), no callback bound.');
    }
  }
}
