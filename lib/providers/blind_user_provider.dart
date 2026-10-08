import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../models/device_status.dart';
import '../models/emergency_contact.dart';
import '../models/location_data.dart';
import '../models/sensor_data.dart';
import '../models/sos_event.dart';
import '../services/emergency_dispatch_service.dart';
import '../services/esp32_service.dart';
import '../services/firebase_service.dart';
import '../services/haptic_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';

class BlindUserProvider extends ChangeNotifier {
  final Esp32Service _esp32Service;
  final StorageService _storageService;
  final TtsService _ttsService;
  final LocationService _locationService;
  final FirebaseService _firebaseService;
  final EmergencyDispatchService _dispatchService;
  final NotificationService _notificationService;

  StreamSubscription<SensorData>? _sensorSub;
  StreamSubscription<Esp32ConnectionState>? _connSub;
  StreamSubscription<bool>? _sosSub;
  StreamSubscription<LocationData>? _locSub;

  SensorData? _sensorData;
  DeviceStatus? _healthStatus;
  LocationData? _currentLocation;
  Esp32ConnectionState _connectionState = Esp32ConnectionState.disconnected;
  String? _lastError;

  bool _isSosActive = false;
  String _sosTriggerReason = 'BUTTON';
  SosEvent? _currentSosEvent;

  List<EmergencyContact> _emergencyContacts = [];

  // Throttling cloud upload of 350ms sensor ticks
  DateTime? _lastTelemetryCloudSync;
  DateTime? _lastObstacleAnnounceTime;

  BlindUserProvider({
    required Esp32Service esp32Service,
    required StorageService storageService,
    required TtsService ttsService,
    required LocationService locationService,
    required FirebaseService firebaseService,
    required EmergencyDispatchService dispatchService,
    required NotificationService notificationService,
  })  : _esp32Service = esp32Service,
        _storageService = storageService,
        _ttsService = ttsService,
        _locationService = locationService,
        _firebaseService = firebaseService,
        _dispatchService = dispatchService,
        _notificationService = notificationService {
    _loadEmergencyContacts();
    _subscribeToHardware();
    _initGpsAndCloud();
  }

  // Getters
  SensorData? get sensorData => _sensorData;
  DeviceStatus? get healthStatus => _healthStatus;
  LocationData? get currentLocation => _currentLocation;
  Esp32ConnectionState get connectionState => _connectionState;
  bool get isConnected => _connectionState == Esp32ConnectionState.connected;
  String? get lastError => _lastError ?? _esp32Service.lastErrorMessage;

  bool get isSosActive => _isSosActive;
  String get sosTriggerReason => _sosTriggerReason;
  SosEvent? get currentSosEvent => _currentSosEvent;

  List<EmergencyContact> get emergencyContacts => _emergencyContacts;
  EmergencyContact? get primaryContact {
    if (_emergencyContacts.isEmpty) return null;
    return _emergencyContacts.firstWhere(
      (c) => c.isPrimary,
      orElse: () => _emergencyContacts.first,
    );
  }

  void _loadEmergencyContacts() {
    _emergencyContacts = _storageService.getEmergencyContacts();
  }

  void _initGpsAndCloud() {
    _locationService.startTracking();
    _locSub = _locationService.locationStream.listen((loc) {
      _currentLocation = loc;
      _firebaseService.uploadLocation(ApiConstants.defaultDeviceId, loc);
      notifyListeners();
    });
  }

  void _subscribeToHardware() {
    _connSub = _esp32Service.connectionStream.listen((state) {
      final previous = _connectionState;
      _connectionState = state;
      _lastError = _esp32Service.lastErrorMessage;

      if (previous != state) {
        if (state == Esp32ConnectionState.connected) {
          _ttsService.speak('Smart Stick connected');
          HapticService.lightClick();
          fetchHealthDiagnostics();
        } else if (state == Esp32ConnectionState.disconnected ||
            state == Esp32ConnectionState.error) {
          _ttsService.speak('Smart Stick disconnected. Checking connection.');
        }
      }
      notifyListeners();
    });

    _sensorSub = _esp32Service.sensorStream.listen((data) {
      _sensorData = data;
      _lastError = null;

      // Cloud upload throttle: once every 1000ms
      final now = DateTime.now();
      if (_lastTelemetryCloudSync == null ||
          now.difference(_lastTelemetryCloudSync!) > const Duration(milliseconds: 1000)) {
        _lastTelemetryCloudSync = now;
        _firebaseService.uploadTelemetry(ApiConstants.defaultDeviceId, data);
      }

      // Handle SOS from /sensors
      if (data.sosActive && !_isSosActive) {
        final reason = data.fallDetected ? 'FALL' : 'BUTTON';
        _handleSosTriggered(reason);
      } else if (!data.sosActive && _isSosActive) {
        _isSosActive = false;
      }

      // Voice obstacle alert for blind user
      _evaluateObstacleVoiceAlert(data);

      notifyListeners();
    });

    _sosSub = _esp32Service.sosTriggerStream.listen((active) {
      if (active && !_isSosActive) {
        _handleSosTriggered('STICK HARDWARE');
      } else if (!active && _isSosActive) {
        _isSosActive = false;
        notifyListeners();
      }
    });
  }

  void startHardwareConnection() {
    _esp32Service.startMonitoring();
    _locationService.startTracking();
  }

  void stopHardwareConnection() {
    _esp32Service.stopMonitoring();
    _locationService.stopTracking();
  }

  Future<void> fetchHealthDiagnostics() async {
    final health = await _esp32Service.fetchHealth();
    if (health != null) {
      _healthStatus = health;
      notifyListeners();
    }
  }

  Future<void> refreshSensors() async {
    await _esp32Service.fetchSensors();
  }

  void _evaluateObstacleVoiceAlert(SensorData data) {
    if (_isSosActive) return;

    final now = DateTime.now();
    if (_lastObstacleAnnounceTime != null &&
        now.difference(_lastObstacleAnnounceTime!) < const Duration(milliseconds: 2000)) {
      return;
    }

    if (data.isMiddleDanger && data.middleDistanceCm != null) {
      _lastObstacleAnnounceTime = now;
      HapticService.obstacleDangerAlert();
      _ttsService.speak(
        'Danger ahead, ${data.middleDistanceCm!.toStringAsFixed(0)} centimeters.',
      );
    } else if (data.isLeftDanger && data.leftDistanceCm != null) {
      _lastObstacleAnnounceTime = now;
      HapticService.obstacleDangerAlert();
      _ttsService.speak(
        'Danger on your left, ${data.leftDistanceCm!.toStringAsFixed(0)} centimeters.',
      );
    } else if (data.isRightDanger && data.rightDistanceCm != null) {
      _lastObstacleAnnounceTime = now;
      HapticService.obstacleDangerAlert();
      _ttsService.speak(
        'Danger on your right, ${data.rightDistanceCm!.toStringAsFixed(0)} centimeters.',
      );
    }
  }

  Future<void> _handleSosTriggered(String reason) async {
    _isSosActive = true;
    _sosTriggerReason = reason;

    // 1. GPS capture at SOS time
    final loc = await _locationService.getCurrentLocation() ?? _currentLocation;

    // 2. SOS event record
    final event = SosEvent(
      eventId: DateTime.now().millisecondsSinceEpoch.toString(),
      type: reason,
      timestamp: DateTime.now(),
      latitude: loc?.latitude,
      longitude: loc?.longitude,
      mapsUrl: loc?.googleMapsUrl,
    );

    _currentSosEvent = event;

    // 3. Firebase SOS event upload for caretaker
    await _firebaseService.createSosEvent(ApiConstants.defaultDeviceId, event);

    // 4. Dispatch emergency notification and SMS
    await _dispatchService.dispatchEmergencyAlert(
      event: event,
      contact: primaryContact,
      location: loc,
    );

    HapticService.emergencySosAlert();
    _ttsService.speak(
      'Emergency SOS active! Trigger reason: $reason. Alerting caretaker.',
      isUrgent: true,
    );
    notifyListeners();
  }

  void triggerManualSos() {
    _handleSosTriggered('MANUAL MOBILE');
  }

  Future<bool> clearSos() async {
    final success = await _esp32Service.clearSos();
    if (success) {
      _isSosActive = false;
      if (_currentSosEvent != null) {
        await _firebaseService.resolveSosEvent(
          ApiConstants.defaultDeviceId,
          _currentSosEvent!.eventId,
        );
        _currentSosEvent = _currentSosEvent!.copyWith(
          acknowledged: true,
          resolvedAt: DateTime.now(),
        );
      }
      await _notificationService.cancelEmergencyNotification();
      _ttsService.speak('Emergency SOS cleared and reset.');
      HapticService.selectionClick();
      notifyListeners();
    }
    return success;
  }

  Future<void> addEmergencyContact(EmergencyContact contact) async {
    if (contact.isPrimary) {
      _emergencyContacts = _emergencyContacts.map((c) => c.copyWith(isPrimary: false)).toList();
    }
    _emergencyContacts.add(contact);
    await _storageService.saveEmergencyContacts(_emergencyContacts);
    await _firebaseService.uploadEmergencyContact(ApiConstants.defaultDeviceId, contact);
    _ttsService.speak('Emergency contact ${contact.name} saved.');
    notifyListeners();
  }

  Future<void> updateEmergencyContact(EmergencyContact contact) async {
    final index = _emergencyContacts.indexWhere((c) => c.id == contact.id);
    if (index != -1) {
      if (contact.isPrimary) {
        _emergencyContacts = _emergencyContacts.map((c) => c.copyWith(isPrimary: false)).toList();
      }
      _emergencyContacts[index] = contact;
      await _storageService.saveEmergencyContacts(_emergencyContacts);
      await _firebaseService.uploadEmergencyContact(ApiConstants.defaultDeviceId, contact);
      _ttsService.speak('Emergency contact ${contact.name} updated.');
      notifyListeners();
    }
  }

  Future<void> deleteEmergencyContact(String id) async {
    _emergencyContacts.removeWhere((c) => c.id == id);
    if (_emergencyContacts.isNotEmpty && !_emergencyContacts.any((c) => c.isPrimary)) {
      _emergencyContacts[0] = _emergencyContacts[0].copyWith(isPrimary: true);
    }
    await _storageService.saveEmergencyContacts(_emergencyContacts);
    _ttsService.speak('Emergency contact removed.');
    notifyListeners();
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _sensorSub?.cancel();
    _sosSub?.cancel();
    _locSub?.cancel();
    super.dispose();
  }
}
