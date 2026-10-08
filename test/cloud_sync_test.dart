import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:safepath/models/location_data.dart';
import 'package:safepath/models/sensor_data.dart';
import 'package:safepath/models/sos_event.dart';
import 'package:safepath/services/firebase_service.dart';

void main() {
  group('Realtime Cloud Backend Sync Tests (Blind User <-> Cloud <-> Caretaker)', () {
    late FirebaseService cloudService;
    const testDeviceId = 'TEST-STICK-99';

    setUp(() async {
      cloudService = FirebaseService();
      await cloudService.initialize();
    });

    tearDown(() {
      cloudService.cancelSubscriptions();
    });

    test('TEST 3 — CLOUD SYNC: Blind User data uploads without errors', () async {
      final loc = LocationData(
        latitude: 20.2961,
        longitude: 85.8245,
        accuracy: 5.0,
        speed: 1.2,
        heading: 90.0,
        timestamp: DateTime.now(),
      );

      // Verify upload does not throw
      expect(cloudService.uploadLocation(testDeviceId, loc), completes);
    });

    test('TEST 4 & 5 — CARETAKER SYNC & LIVE GPS: Caretaker receives paired Blind User location', () async {
      final loc = LocationData(
        latitude: 19.0760,
        longitude: 72.8777,
        accuracy: 4.2,
        speed: 0.8,
        heading: 180.0,
        timestamp: DateTime.now(),
      );

      final completer = Completer<LocationData>();
      final sub = cloudService.streamLocation(testDeviceId).listen((received) {
        if (received != null && !completer.isCompleted) {
          completer.complete(received);
        }
      });

      // Blind User uploads location
      await cloudService.uploadLocation(testDeviceId, loc);

      final result = await completer.future.timeout(const Duration(seconds: 3));
      expect(result.latitude, equals(19.0760));
      expect(result.longitude, equals(72.8777));
      expect(result.accuracy, equals(4.2));
      await sub.cancel();
    });

    test('TEST 6 — SOS: Trigger SOS and verify Caretaker receives SOS event', () async {
      final event = SosEvent(
        eventId: 'sos-test-101',
        type: 'BUTTON',
        timestamp: DateTime.now(),
        latitude: 28.6139,
        longitude: 77.2090,
        mapsUrl: 'https://maps.google.com/?q=28.6139,77.2090',
        acknowledged: false,
      );

      final completer = Completer<List<SosEvent>>();
      final sub = cloudService.streamActiveSosEvents(testDeviceId).listen((events) {
        if (events.isNotEmpty && !completer.isCompleted) {
          completer.complete(events);
        }
      });

      // Blind User triggers SOS
      await cloudService.createSosEvent(testDeviceId, event);

      final events = await completer.future.timeout(const Duration(seconds: 3));
      expect(events.first.eventId, equals('sos-test-101'));
      expect(events.first.type, equals('BUTTON'));
      expect(events.first.latitude, equals(28.6139));
      await sub.cancel();
    });

    test('TEST 7 & 8 — FALL & SENSOR DATA: Telemetry, obstacle, and fall detection sync to Caretaker', () async {
      final telemetry = SensorData(
        deviceId: testDeviceId,
        deviceStatus: 'connected',
        leftDistanceCm: 15.0, // Danger (<20cm)
        middleDistanceCm: 85.0,
        rightDistanceCm: null,
        leftSensorStatus: 'valid',
        middleSensorStatus: 'valid',
        rightSensorStatus: 'no_echo',
        mpu6050Available: true,
        ax: 0.2,
        ay: 0.1,
        az: 0.9,
        gx: 0.0,
        gy: 0.0,
        gz: 0.0,
        temperature: 28.5,
        accelerationG: 2.85,
        tiltDeg: 55.0,
        fallDetected: true, // FALL DETECTED
        sosActive: true,
        sosPressed: false,
        wifiConnected: true,
        appConnected: true,
        connectedClients: 1,
        uptimeMs: 120000,
        freeHeap: 200000,
        wifiRssi: -55,
      );

      final completer = Completer<SensorData>();
      final sub = cloudService.streamTelemetry(testDeviceId).listen((received) {
        if (received != null && !completer.isCompleted) {
          completer.complete(received);
        }
      });

      // Blind User uploads telemetry
      await cloudService.uploadTelemetry(testDeviceId, telemetry);

      final result = await completer.future.timeout(const Duration(seconds: 3));
      expect(result.leftDistanceCm, equals(15.0));
      expect(result.middleDistanceCm, equals(85.0));
      expect(result.fallDetected, isTrue);
      expect(result.sosActive, isTrue);
      expect(result.accelerationG, equals(2.85));
      expect(result.tiltDeg, equals(55.0));
      await sub.cancel();
    });
  });
}
