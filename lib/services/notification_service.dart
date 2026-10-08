import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Production notification service providing high-priority Android notification channels
/// for instant SOS and fall alerts.
class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String sosChannelId = 'safepath_sos_channel';
  static const String sosChannelName = 'SafePath Emergency Alerts';
  static const String sosChannelDesc =
      'High priority alerts for stick falls and SOS button presses';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      // Create Android High-Priority Emergency Channel
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            sosChannelId,
            sosChannelName,
            description: sosChannelDesc,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );

        await androidImplementation.requestNotificationsPermission();
      }

      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService init notice: $e');
    }
  }

  /// Show high-priority heads-up emergency notification
  Future<void> showEmergencyNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      sosChannelId,
      sosChannelName,
      channelDescription: sosChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(''),
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(
        911,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }

  /// Clear active emergency notification
  Future<void> cancelEmergencyNotification() async {
    try {
      await _notificationsPlugin.cancel(911);
    } catch (e) {
      debugPrint('Failed to cancel notification: $e');
    }
  }
}
