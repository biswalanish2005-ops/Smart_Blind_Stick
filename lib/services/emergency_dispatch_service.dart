import '../models/emergency_contact.dart';
import '../models/location_data.dart';
import '../models/sos_event.dart';
import '../core/utils/accessibility_utils.dart';
import 'notification_service.dart';

/// Production Emergency Dispatch Service
/// Implements Section 6 formatted alerts, SMS pre-fill, and high-priority heads-up notifications.
class EmergencyDispatchService {
  final NotificationService _notificationService;

  EmergencyDispatchService({
    required NotificationService notificationService,
  }) : _notificationService = notificationService;

  /// Formats exact alert message specified in Section 6
  static String formatEmergencyMessage({
    required String triggerReason,
    String userName = 'SafePath User',
    required DateTime timestamp,
    LocationData? location,
  }) {
    final timeStr =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
    final locationStr = location != null
        ? location.googleMapsUrl
        : 'GPS coordinates unavailable at trigger instant';

    return '''🚨 SAFEPATH SOS ALERT 🚨

An emergency has been detected by the SafePath Blind Stick.

Trigger:
$triggerReason

User:
$userName

Time:
$timeStr

Location:
$locationStr

The SafePath stick is reporting an active emergency.''';
  }

  /// Execute end-to-end emergency notification
  Future<void> dispatchEmergencyAlert({
    required SosEvent event,
    required EmergencyContact? contact,
    LocationData? location,
    String userName = 'SafePath User',
  }) async {
    final message = formatEmergencyMessage(
      triggerReason: event.type,
      userName: userName,
      timestamp: event.timestamp,
      location: location,
    );

    // 1. Android High-Priority Emergency Notification
    await _notificationService.showEmergencyNotification(
      title: '🚨 SAFEPATH SOS ACTIVE (${event.type})',
      body: 'Emergency detected. Alert dispatched to ${contact?.name ?? "caregivers"}.',
      payload: event.eventId,
    );

    // 2. Pre-fill SMS to emergency contact if configured
    if (contact != null && contact.phone.isNotEmpty) {
      await AccessibilityUtils.sendSms(contact.phone, message);
    }
  }

  /// Direct emergency dial
  Future<bool> dialEmergencyContact(EmergencyContact contact) async {
    return await AccessibilityUtils.dialPhoneNumber(contact.phone);
  }
}
