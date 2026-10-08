import 'package:flutter_test/flutter_test.dart';
import 'package:safepath/models/location_data.dart';
import 'package:safepath/services/emergency_dispatch_service.dart';

void main() {
  group('EmergencyDispatchService Contract Tests (Section 6)', () {
    test('Formats emergency alert matching authoritative Section 6 specification', () {
      final timestamp = DateTime(2026, 10, 8, 10, 32, 18);
      final location = LocationData(
        latitude: 12.9716,
        longitude: 77.5946,
        accuracy: 5.0,
        speed: 0.0,
        heading: 0.0,
        timestamp: timestamp,
      );

      final message = EmergencyDispatchService.formatEmergencyMessage(
        triggerReason: 'FALL',
        userName: 'Ramesh Kumar',
        timestamp: timestamp,
        location: location,
      );

      expect(message, contains('🚨 SAFEPATH SOS ALERT 🚨'));
      expect(message, contains('An emergency has been detected by the SafePath Blind Stick.'));
      expect(message, contains('Trigger:\nFALL'));
      expect(message, contains('User:\nRamesh Kumar'));
      expect(message, contains('Time:\n10:32:18'));
      expect(message, contains('https://www.google.com/maps/search/?api=1&query=12.9716,77.5946'));
      expect(message, contains('The SafePath stick is reporting an active emergency.'));
    });

    test('Formats emergency alert with BUTTON trigger and missing GPS gracefully', () {
      final timestamp = DateTime(2026, 10, 8, 14, 5, 0);

      final message = EmergencyDispatchService.formatEmergencyMessage(
        triggerReason: 'SOS BUTTON',
        userName: 'Anish',
        timestamp: timestamp,
        location: null,
      );

      expect(message, contains('Trigger:\nSOS BUTTON'));
      expect(message, contains('GPS coordinates unavailable at trigger instant'));
    });
  });
}
