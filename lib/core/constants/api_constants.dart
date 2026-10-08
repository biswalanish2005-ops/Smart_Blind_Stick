/// Production API and Hardware Network Constants for SafePath
/// Authoritative firmware contract specified in SafePath_Antigravity_Gemini38_Build_Spec.md
class ApiConstants {
  ApiConstants._();

  // ESP32 Phone Hotspot (WIFI_STA) Configuration
  static const String defaultHotspotSsid = 'SafePath_Hotspot';
  static const String defaultMdnsHost = 'http://safepath-stick.local';
  static const String defaultBaseUrl = 'http://192.168.43.127';
  static const String defaultDeviceId = 'ESP32-SAFEPATH-01';

  // HTTP Endpoints (firmware contract)
  static const String rootEndpoint = '/';
  static const String sensorsEndpoint = '/sensors';
  static const String sosStatusEndpoint = '/sos-status';
  static const String heartbeatEndpoint = '/app/heartbeat';
  static const String healthEndpoint = '/health';
  static const String clearSosEndpoint = '/clear-sos';

  // Network & Polling Timing
  static const Duration connectTimeout = Duration(milliseconds: 3000);
  static const Duration requestTimeout = Duration(milliseconds: 2500);
  static const Duration heartbeatInterval = Duration(milliseconds: 2000);
  static const Duration sensorPollInterval = Duration(milliseconds: 350);
  static const Duration fastSosPollInterval = Duration(milliseconds: 250);

  // Safety Thresholds (from ESP32 firmware)
  static const double dangerThresholdCm = 20.0;
  static const double maxUltrasonicValidCm = 450.0;
  static const double minUltrasonicValidCm = 2.0;

  // IMU Reference Constants
  static const double gravityMps2 = 9.80665;
  static const double postFallTiltThresholdDeg = 45.0;
}
