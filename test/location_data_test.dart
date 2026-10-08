import 'package:flutter_test/flutter_test.dart';
import 'package:safepath/models/location_data.dart';

void main() {
  group('LocationData Model Tests', () {
    test('Parses GPS coordinates and generates Google Maps URL', () {
      final json = {
        'latitude': 12.971598,
        'longitude': 77.594562,
        'accuracy': 8.5,
        'speed': 1.2,
        'heading': 90.0,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final loc = LocationData.fromJson(json);

      expect(loc.latitude, 12.971598);
      expect(loc.longitude, 77.594562);
      expect(loc.accuracy, 8.5);
      expect(loc.isStale, isFalse);
      expect(
        loc.googleMapsUrl,
        'https://www.google.com/maps/search/?api=1&query=12.971598,77.594562',
      );
    });

    test('Correctly identifies stale location data', () {
      final oldTime = DateTime.now().subtract(const Duration(seconds: 60));
      final json = {
        'latitude': 12.0,
        'longitude': 80.0,
        'accuracy': 15.0,
        'speed': 0.0,
        'heading': 0.0,
        'timestamp': oldTime.toIso8601String(),
      };

      final loc = LocationData.fromJson(json);
      expect(loc.isStale, isTrue);
      expect(loc.secondsAgo, greaterThanOrEqualTo(59));
    });
  });
}
