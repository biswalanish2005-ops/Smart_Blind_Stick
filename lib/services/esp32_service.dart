import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/device_status.dart';
import '../models/sensor_data.dart';

enum Esp32ConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

/// Real, production HTTP communication service with the ESP32 Smart Stick.
/// NO SIMULATION, NO FAKE DATA.
class Esp32Service {
  String baseUrl;
  final http.Client _client;

  Esp32ConnectionState _connectionState = Esp32ConnectionState.disconnected;
  String? _lastErrorMessage;
  DateTime? _lastHeartbeatSuccess;
  DateTime? _lastSensorSuccess;

  Timer? _heartbeatTimer;
  Timer? _sensorPollTimer;
  bool _isPolling = false;

  final StreamController<SensorData> _sensorStreamController =
      StreamController<SensorData>.broadcast();
  final StreamController<Esp32ConnectionState> _connectionStateController =
      StreamController<Esp32ConnectionState>.broadcast();
  final StreamController<bool> _sosTriggerController =
      StreamController<bool>.broadcast();

  Esp32Service({
    String? initialBaseUrl,
    http.Client? httpClient,
  })  : baseUrl = initialBaseUrl ?? ApiConstants.defaultBaseUrl,
        _client = httpClient ?? http.Client();

  // Public Getters & Streams
  Esp32ConnectionState get connectionState => _connectionState;
  bool get isConnected => _connectionState == Esp32ConnectionState.connected;
  String? get lastErrorMessage => _lastErrorMessage;
  DateTime? get lastHeartbeatSuccess => _lastHeartbeatSuccess;
  DateTime? get lastSensorSuccess => _lastSensorSuccess;

  Stream<SensorData> get sensorStream => _sensorStreamController.stream;
  Stream<Esp32ConnectionState> get connectionStream =>
      _connectionStateController.stream;
  Stream<bool> get sosTriggerStream => _sosTriggerController.stream;

  void updateBaseUrl(String newUrl) {
    var trimmed = newUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'http://$trimmed';
    }
    baseUrl = trimmed;
  }

  /// Test connectivity to a specific URL or IP address
  Future<bool> testConnection(String targetUrl) async {
    try {
      var url = targetUrl.trim().replaceAll(RegExp(r'/+$'), '');
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'http://$url';
      }
      final uri = Uri.parse('$url${ApiConstants.healthEndpoint}');
      final response =
          await _client.get(uri).timeout(const Duration(milliseconds: 2500));
      return response.statusCode == 200 &&
          response.body.contains('ESP32-SAFEPATH-01');
    } catch (_) {
      return false;
    }
  }

  /// Automatically discover the ESP32 on the phone hotspot or local network.
  /// Probes mDNS (safepath-stick.local), current configured baseUrl, and common hotspot IPs.
  Future<String?> discoverEsp32({
    Duration timeout = const Duration(milliseconds: 1500),
  }) async {
    final candidates = <String>[
      ApiConstants.defaultMdnsHost,
      baseUrl,
      'http://192.168.43.127',
      'http://192.168.43.100',
      'http://192.168.43.2',
      'http://192.168.4.1',
    ];

    for (final candidate in candidates) {
      try {
        final uri = Uri.parse('$candidate${ApiConstants.healthEndpoint}');
        final res = await _client.get(uri).timeout(timeout);
        if (res.statusCode == 200 && res.body.contains('ESP32-SAFEPATH-01')) {
          updateBaseUrl(candidate);
          return candidate;
        }
      } catch (_) {
        // Probe next candidate
      }
    }
    return null;
  }

  /// Start automatic heartbeat and continuous sensor polling
  void startMonitoring() {
    if (_isPolling) return;
    _isPolling = true;

    // Immediate first ping
    sendHeartbeat();
    fetchSensors();

    // Periodic Heartbeat every 2 seconds (ESP32 timeout is 6s)
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(ApiConstants.heartbeatInterval, (_) {
      sendHeartbeat();
    });

    // Periodic Sensor Polling every 350ms
    _sensorPollTimer?.cancel();
    _sensorPollTimer = Timer.periodic(ApiConstants.sensorPollInterval, (_) {
      fetchSensors();
    });
  }

  /// Stop polling (when app is paused or disconnected)
  void stopMonitoring() {
    _isPolling = false;
    _heartbeatTimer?.cancel();
    _sensorPollTimer?.cancel();
    _setConnectionState(Esp32ConnectionState.disconnected);
  }

  /// Send /app/heartbeat to register the mobile client with the ESP32 firmware
  Future<DeviceStatus?> sendHeartbeat() async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.heartbeatEndpoint}');
      final response = await _client.get(uri).timeout(ApiConstants.requestTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final status = DeviceStatus.fromHeartbeatJson(decoded);

        _lastHeartbeatSuccess = DateTime.now();
        _lastErrorMessage = null;
        if (_connectionState != Esp32ConnectionState.connected) {
          _setConnectionState(Esp32ConnectionState.connected);
        }

        if (status.sosActive) {
          _sosTriggerController.add(true);
        }

        return status;
      } else {
        _handleCommunicationError(
            'Heartbeat returned HTTP ${response.statusCode}');
        return null;
      }
    } on SocketException catch (e) {
      _handleCommunicationError(
          'Cannot reach stick at $baseUrl: ${e.message}. Ensure phone hotspot is ON and ESP32 is connected.');
      return null;
    } on TimeoutException {
      _handleCommunicationError('Heartbeat timed out. ESP32 unresponsive.');
      return null;
    } catch (e) {
      _handleCommunicationError('Heartbeat error: $e');
      return null;
    }
  }

  /// Fetch full real telemetry from /sensors
  Future<SensorData?> fetchSensors() async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.sensorsEndpoint}');
      final response = await _client.get(uri).timeout(ApiConstants.requestTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final data = SensorData.fromJson(decoded);

        _lastSensorSuccess = DateTime.now();
        _lastErrorMessage = null;
        if (_connectionState != Esp32ConnectionState.connected) {
          _setConnectionState(Esp32ConnectionState.connected);
        }

        _sensorStreamController.add(data);

        // Check persistent SOS state
        if (data.sosActive) {
          _sosTriggerController.add(true);
        }

        return data;
      } else {
        _handleCommunicationError(
            'Sensors query returned HTTP ${response.statusCode}');
        return null;
      }
    } on SocketException catch (e) {
      _handleCommunicationError(
          'Hotspot Wi-Fi unreachable at $baseUrl: ${e.message}. Ensure phone hotspot is ON (2.4 GHz) and ESP32 is connected.');
      return null;
    } on TimeoutException {
      _handleCommunicationError('Sensor request timed out.');
      return null;
    } on FormatException catch (e) {
      _handleCommunicationError('Invalid JSON from sensor endpoint: ${e.message}');
      return null;
    } catch (e) {
      _handleCommunicationError('Sensor error: $e');
      return null;
    }
  }

  /// Fetch hardware subsystem health from /health
  Future<DeviceStatus?> fetchHealth() async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.healthEndpoint}');
      final response = await _client.get(uri).timeout(ApiConstants.requestTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return DeviceStatus.fromHealthJson(decoded);
      }
      return null;
    } catch (e) {
      debugPrint('Health query failed: $e');
      return null;
    }
  }

  /// Fast check for active SOS status from /sos-status
  Future<bool> checkSosStatus() async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.sosStatusEndpoint}');
      final response = await _client.get(uri).timeout(ApiConstants.requestTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final active = decoded['sos_active'] == true;
        if (active) {
          _sosTriggerController.add(true);
        }
        return active;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Acknowledge and clear active SOS on the ESP32 hardware via /clear-sos
  /// Must only be called AFTER the app has recorded/handled the SOS.
  Future<bool> clearSos() async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.clearSosEndpoint}');
      final response = await _client.get(uri).timeout(ApiConstants.requestTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final cleared = decoded['status'] == 'cleared';
        if (cleared) {
          _sosTriggerController.add(false);
        }
        return cleared;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to clear SOS on hardware: $e');
      return false;
    }
  }

  void _setConnectionState(Esp32ConnectionState state) {
    if (_connectionState != state) {
      _connectionState = state;
      _connectionStateController.add(state);
    }
  }

  void _handleCommunicationError(String message) {
    _lastErrorMessage = message;
    if (_connectionState != Esp32ConnectionState.disconnected &&
        _connectionState != Esp32ConnectionState.error) {
      _setConnectionState(Esp32ConnectionState.error);
    }
  }

  void dispose() {
    stopMonitoring();
    _sensorStreamController.close();
    _connectionStateController.close();
    _sosTriggerController.close();
    _client.close();
  }
}
