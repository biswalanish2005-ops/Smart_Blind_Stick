import 'package:flutter_test/flutter_test.dart';
import 'package:safepath/models/sensor_data.dart';

void main() {
  group('SensorData Model Tests (ESP32 Contract)', () {
    test('Parses full valid hardware telemetry JSON correctly', () {
      final json = {
        "device_id": "ESP32-SAFEPATH-01",
        "device_status": "connected",
        "left_distance_cm": 25.4,
        "middle_distance_cm": 18.7,
        "right_distance_cm": 42.8,
        "left_sensor_status": "ok",
        "middle_sensor_status": "ok",
        "right_sensor_status": "ok",
        "mpu6050_available": true,
        "ax": 0.12,
        "ay": -0.32,
        "az": 9.65,
        "gx": 0.03,
        "gy": -0.02,
        "gz": 0.10,
        "temperature": 29.2,
        "acceleration_g": 0.99,
        "tilt_deg": 4.5,
        "fall_detected": false,
        "sos_active": false,
        "sos_pressed": false,
        "wifi_connected": true,
        "app_connected": true,
        "connected_clients": 1,
        "uptime_ms": 123456,
        "free_heap": 200000,
        "wifi_rssi": -45
      };

      final sensorData = SensorData.fromJson(json);

      expect(sensorData.deviceId, 'ESP32-SAFEPATH-01');
      expect(sensorData.leftDistanceCm, 25.4);
      expect(sensorData.middleDistanceCm, 18.7);
      expect(sensorData.rightDistanceCm, 42.8);
      expect(sensorData.mpu6050Available, isTrue);
      expect(sensorData.accelerationG, 0.99);
      expect(sensorData.tiltDeg, 4.5);
      expect(sensorData.fallDetected, isFalse);
      expect(sensorData.sosActive, isFalse);

      // Threshold evaluations: middle is 18.7cm < 20cm danger threshold
      expect(sensorData.isMiddleDanger, isTrue);
      expect(sensorData.isLeftDanger, isFalse);
      expect(sensorData.isRightDanger, isFalse);
      expect(sensorData.hasAnyObstacleDanger, isTrue);
    });

    test('Handles null sensor readings (no echo) gracefully', () {
      final json = {
        "device_id": "ESP32-SAFEPATH-01",
        "device_status": "connected",
        "left_distance_cm": null,
        "middle_distance_cm": null,
        "right_distance_cm": null,
        "left_sensor_status": "no_echo",
        "middle_sensor_status": "no_echo",
        "right_sensor_status": "no_echo",
        "mpu6050_available": false,
        "fall_detected": false,
        "sos_active": false
      };

      final sensorData = SensorData.fromJson(json);

      expect(sensorData.leftDistanceCm, isNull);
      expect(sensorData.middleDistanceCm, isNull);
      expect(sensorData.rightDistanceCm, isNull);
      expect(sensorData.isLeftDanger, isFalse);
      expect(sensorData.isMiddleDanger, isFalse);
      expect(sensorData.isRightDanger, isFalse);
      expect(sensorData.hasAnyObstacleDanger, isFalse);
      expect(sensorData.mpu6050Available, isFalse);
    });

    test('Detects fall and SOS states accurately', () {
      final json = {
        "device_id": "ESP32-SAFEPATH-01",
        "fall_detected": true,
        "sos_active": true,
        "sos_pressed": false,
        "mpu6050_available": true,
        "acceleration_g": 3.4,
        "tilt_deg": 68.2,
      };

      final sensorData = SensorData.fromJson(json);

      expect(sensorData.fallDetected, isTrue);
      expect(sensorData.sosActive, isTrue);
      expect(sensorData.accelerationG, 3.4);
      expect(sensorData.tiltDeg, 68.2);
    });
  });
}
