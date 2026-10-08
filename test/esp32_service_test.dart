import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safepath/services/esp32_service.dart';

void main() {
  group('Esp32Service Unit Tests (Mock HTTP Transport)', () {
    test('Heartbeat parses device status and updates connection state', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/app/heartbeat') {
          return http.Response(
            jsonEncode({
              'status': 'app_connected',
              'device_id': 'ESP32-SAFEPATH-01',
              'sos_active': false,
              'ip': '192.168.4.1',
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = Esp32Service(
        initialBaseUrl: 'http://192.168.4.1',
        httpClient: mockClient,
      );

      final status = await service.sendHeartbeat();
      expect(status, isNotNull);
      expect(status!.deviceId, 'ESP32-SAFEPATH-01');
      expect(status.status, 'app_connected');
      expect(service.isConnected, isTrue);

      service.dispose();
    });

    test('Sensors endpoint delivers telemetry to stream', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/sensors') {
          return http.Response(
            jsonEncode({
              'device_id': 'ESP32-SAFEPATH-01',
              'device_status': 'connected',
              'left_distance_cm': 28.5,
              'middle_distance_cm': 14.2,
              'right_distance_cm': 35.0,
              'left_sensor_status': 'ok',
              'middle_sensor_status': 'ok',
              'right_sensor_status': 'ok',
              'mpu6050_available': true,
              'ax': 0.1,
              'ay': 0.2,
              'az': 9.8,
              'gx': 0.0,
              'gy': 0.0,
              'gz': 0.0,
              'temperature': 28.0,
              'acceleration_g': 1.0,
              'tilt_deg': 5.0,
              'fall_detected': false,
              'sos_active': true,
              'sos_pressed': true,
              'wifi_connected': true,
              'app_connected': true,
              'connected_clients': 1,
              'uptime_ms': 50000,
              'free_heap': 180000,
              'wifi_rssi': -50,
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = Esp32Service(
        initialBaseUrl: 'http://192.168.4.1',
        httpClient: mockClient,
      );

      final telemetry = await service.fetchSensors();
      expect(telemetry, isNotNull);
      expect(telemetry!.middleDistanceCm, 14.2);
      expect(telemetry.isMiddleDanger, isTrue);
      expect(telemetry.sosActive, isTrue);

      service.dispose();
    });

    test('Clear SOS calls /clear-sos and returns success', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/clear-sos') {
          return http.Response(
            jsonEncode({'status': 'cleared', 'sos_active': false}),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = Esp32Service(
        initialBaseUrl: 'http://192.168.4.1',
        httpClient: mockClient,
      );

      final cleared = await service.clearSos();
      expect(cleared, isTrue);

      service.dispose();
    });
  });
}
