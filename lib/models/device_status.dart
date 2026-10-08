/// Status response from ESP32 /health and /app/heartbeat
class DeviceStatus {
  final String status;
  final String deviceId;
  final int uptimeMs;
  final bool mpu6050Ok;
  final bool leftUltrasonicOk;
  final bool middleUltrasonicOk;
  final bool rightUltrasonicOk;
  final bool mobileWifiConnected;
  final bool mobileAppConnected;
  final bool sosActive;
  final String ip;

  DeviceStatus({
    required this.status,
    required this.deviceId,
    required this.uptimeMs,
    required this.mpu6050Ok,
    required this.leftUltrasonicOk,
    required this.middleUltrasonicOk,
    required this.rightUltrasonicOk,
    required this.mobileWifiConnected,
    required this.mobileAppConnected,
    required this.sosActive,
    required this.ip,
  });

  factory DeviceStatus.fromHealthJson(Map<String, dynamic> json) {
    return DeviceStatus(
      status: json['status']?.toString() ?? 'unknown',
      deviceId: json['device_id']?.toString() ?? 'ESP32-SAFEPATH-01',
      uptimeMs: json['uptime_ms'] is num ? (json['uptime_ms'] as num).toInt() : 0,
      mpu6050Ok: json['mpu6050'] == 'ok',
      leftUltrasonicOk: json['left_ultrasonic'] == 'ok',
      middleUltrasonicOk: json['middle_ultrasonic'] == 'ok',
      rightUltrasonicOk: json['right_ultrasonic'] == 'ok',
      mobileWifiConnected: json['mobile_wifi_connected'] == true,
      mobileAppConnected: json['mobile_app_connected'] == true,
      sosActive: json['sos_active'] == true,
      ip: '',
    );
  }

  factory DeviceStatus.fromHeartbeatJson(Map<String, dynamic> json) {
    return DeviceStatus(
      status: json['status']?.toString() ?? 'app_connected',
      deviceId: json['device_id']?.toString() ?? 'ESP32-SAFEPATH-01',
      uptimeMs: 0,
      mpu6050Ok: true,
      leftUltrasonicOk: true,
      middleUltrasonicOk: true,
      rightUltrasonicOk: true,
      mobileWifiConnected: true,
      mobileAppConnected: true,
      sosActive: json['sos_active'] == true,
      ip: json['ip']?.toString() ?? '',
    );
  }
}
