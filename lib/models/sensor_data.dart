import '../core/constants/api_constants.dart';

/// Complete hardware telemetry payload matching ESP32 firmware contract.
class SensorData {
  final String deviceId;
  final String deviceStatus;

  // Ultrasonic Distances (null when no echo)
  final double? leftDistanceCm;
  final double? middleDistanceCm;
  final double? rightDistanceCm;

  final String leftSensorStatus;
  final String middleSensorStatus;
  final String rightSensorStatus;

  // MPU6050 6-Axis & Fall Diagnostics
  final bool mpu6050Available;
  final double ax;
  final double ay;
  final double az;
  final double gx;
  final double gy;
  final double gz;
  final double temperature;
  final double accelerationG;
  final double tiltDeg;

  // Persistent Emergency Flags
  final bool fallDetected;
  final bool sosActive;
  final bool sosPressed;

  // ESP32 Health & Networking
  final bool wifiConnected;
  final bool appConnected;
  final int connectedClients;
  final int uptimeMs;
  final int freeHeap;
  final int wifiRssi;

  final DateTime receivedAt;

  SensorData({
    required this.deviceId,
    required this.deviceStatus,
    this.leftDistanceCm,
    this.middleDistanceCm,
    this.rightDistanceCm,
    required this.leftSensorStatus,
    required this.middleSensorStatus,
    required this.rightSensorStatus,
    required this.mpu6050Available,
    required this.ax,
    required this.ay,
    required this.az,
    required this.gx,
    required this.gy,
    required this.gz,
    required this.temperature,
    required this.accelerationG,
    required this.tiltDeg,
    required this.fallDetected,
    required this.sosActive,
    required this.sosPressed,
    required this.wifiConnected,
    required this.appConnected,
    required this.connectedClients,
    required this.uptimeMs,
    required this.freeHeap,
    required this.wifiRssi,
    DateTime? receivedAt,
  }) : receivedAt = receivedAt ?? DateTime.now();

  factory SensorData.fromJson(Map<String, dynamic> json) {
    double? parseNullableDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString());
    }

    double parseDouble(dynamic val, [double fallback = 0.0]) {
      if (val == null) return fallback;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? fallback;
    }

    int parseInt(dynamic val, [int fallback = 0]) {
      if (val == null) return fallback;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? fallback;
    }

    bool parseBool(dynamic val, [bool fallback = false]) {
      if (val == null) return fallback;
      if (val is bool) return val;
      if (val is num) return val != 0;
      return val.toString().toLowerCase() == 'true';
    }

    return SensorData(
      deviceId: json['device_id']?.toString() ?? ApiConstants.defaultDeviceId,
      deviceStatus: json['device_status']?.toString() ?? 'unknown',
      leftDistanceCm: parseNullableDouble(json['left_distance_cm']),
      middleDistanceCm: parseNullableDouble(json['middle_distance_cm']),
      rightDistanceCm: parseNullableDouble(json['right_distance_cm']),
      leftSensorStatus: json['left_sensor_status']?.toString() ?? 'no_echo',
      middleSensorStatus: json['middle_sensor_status']?.toString() ?? 'no_echo',
      rightSensorStatus: json['right_sensor_status']?.toString() ?? 'no_echo',
      mpu6050Available: parseBool(json['mpu6050_available']),
      ax: parseDouble(json['ax']),
      ay: parseDouble(json['ay']),
      az: parseDouble(json['az']),
      gx: parseDouble(json['gx']),
      gy: parseDouble(json['gy']),
      gz: parseDouble(json['gz']),
      temperature: parseDouble(json['temperature']),
      accelerationG: parseDouble(json['acceleration_g'], 1.0),
      tiltDeg: parseDouble(json['tilt_deg']),
      fallDetected: parseBool(json['fall_detected']),
      sosActive: parseBool(json['sos_active']),
      sosPressed: parseBool(json['sos_pressed']),
      wifiConnected: parseBool(json['wifi_connected']),
      appConnected: parseBool(json['app_connected']),
      connectedClients: parseInt(json['connected_clients']),
      uptimeMs: parseInt(json['uptime_ms']),
      freeHeap: parseInt(json['free_heap']),
      wifiRssi: parseInt(json['wifi_rssi']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'device_status': deviceStatus,
      'left_distance_cm': leftDistanceCm,
      'middle_distance_cm': middleDistanceCm,
      'right_distance_cm': rightDistanceCm,
      'left_sensor_status': leftSensorStatus,
      'middle_sensor_status': middleSensorStatus,
      'right_sensor_status': rightSensorStatus,
      'mpu6050_available': mpu6050Available,
      'ax': ax,
      'ay': ay,
      'az': az,
      'gx': gx,
      'gy': gy,
      'gz': gz,
      'temperature': temperature,
      'acceleration_g': accelerationG,
      'tilt_deg': tiltDeg,
      'fall_detected': fallDetected,
      'sos_active': sosActive,
      'sos_pressed': sosPressed,
      'wifi_connected': wifiConnected,
      'app_connected': appConnected,
      'connected_clients': connectedClients,
      'uptime_ms': uptimeMs,
      'free_heap': freeHeap,
      'wifi_rssi': wifiRssi,
      'received_at': receivedAt.toIso8601String(),
    };
  }

  // Safety Evaluator Helpers
  bool get isLeftDanger =>
      leftDistanceCm != null &&
      leftDistanceCm! > 0 &&
      leftDistanceCm! < ApiConstants.dangerThresholdCm;

  bool get isMiddleDanger =>
      middleDistanceCm != null &&
      middleDistanceCm! > 0 &&
      middleDistanceCm! < ApiConstants.dangerThresholdCm;

  bool get isRightDanger =>
      rightDistanceCm != null &&
      rightDistanceCm! > 0 &&
      rightDistanceCm! < ApiConstants.dangerThresholdCm;

  bool get hasAnyObstacleDanger =>
      isLeftDanger || isMiddleDanger || isRightDanger;
}
