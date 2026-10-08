import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../models/location_data.dart';
import '../models/sensor_data.dart';
import '../models/sos_event.dart';
import '../services/firebase_service.dart';

class CaretakerProvider extends ChangeNotifier {
  static const String _keyPairedDevice = 'safepath_paired_device_id';

  final FirebaseService _firebaseService;
  final SharedPreferences _prefs;

  String? _pairedDeviceId;
  LocationData? _liveLocation;
  SensorData? _liveTelemetry;
  Map<String, dynamic>? _deviceMetadata;
  List<SosEvent> _activeSosEvents = [];
  DateTime? _lastCloudUpdate;

  StreamSubscription<LocationData?>? _locSub;
  StreamSubscription<SensorData?>? _telemetrySub;
  StreamSubscription<Map<String, dynamic>?>? _metaSub;
  StreamSubscription<List<SosEvent>>? _sosSub;

  CaretakerProvider({
    required FirebaseService firebaseService,
    required SharedPreferences prefs,
  })  : _firebaseService = firebaseService,
        _prefs = prefs {
    _loadPairedDevice();
  }

  // Getters
  bool get isPaired => _pairedDeviceId != null && _pairedDeviceId!.isNotEmpty;
  String? get pairedDeviceId => _pairedDeviceId;
  LocationData? get liveLocation => _liveLocation;
  SensorData? get liveTelemetry => _liveTelemetry;
  Map<String, dynamic>? get deviceMetadata => _deviceMetadata;
  List<SosEvent> get activeSosEvents => _activeSosEvents;

  bool get isSosActive =>
      _activeSosEvents.isNotEmpty ||
      _liveTelemetry?.sosActive == true ||
      _deviceMetadata?['sosActive'] == true;

  bool get isFallDetected =>
      _liveTelemetry?.fallDetected == true ||
      _deviceMetadata?['fallDetected'] == true;

  /// Distinction 1: Caretaker phone has internet connectivity to cloud
  bool get isCaretakerOnline => _firebaseService.isCloudReachable;

  /// Distinction 2: Blind User phone has updated cloud within the last 25 seconds
  bool get isBlindUserOnline {
    if (_lastCloudUpdate != null) {
      return DateTime.now().difference(_lastCloudUpdate!).inSeconds < 25;
    }
    if (_liveTelemetry != null) {
      return DateTime.now().difference(_liveTelemetry!.receivedAt).inSeconds < 25;
    }
    if (_liveLocation != null) {
      return !_liveLocation!.isStale;
    }
    return false;
  }

  /// Distinction 3: ESP32 hardware is connected to Blind User phone
  bool get isStickConnected {
    if (!isBlindUserOnline) return false;
    if (_liveTelemetry != null) {
      return _liveTelemetry!.appConnected;
    }
    return _deviceMetadata?['stickConnected'] == true;
  }

  void _loadPairedDevice() {
    _pairedDeviceId = _prefs.getString(_keyPairedDevice);
    if (_pairedDeviceId == null || _pairedDeviceId!.isEmpty) {
      // Check if a deviceId was generated on this device or default
      _pairedDeviceId = _prefs.getString('safepath_device_id') ?? ApiConstants.defaultDeviceId;
    }
    _subscribeToDevice();
  }

  Future<void> pairDevice(String deviceId) async {
    final cleanId = deviceId.trim().toUpperCase();
    if (cleanId.isEmpty) return;

    _pairedDeviceId = cleanId;
    await _prefs.setString(_keyPairedDevice, cleanId);
    _subscribeToDevice();
    notifyListeners();
  }

  Future<void> unpairDevice() async {
    _cancelSubscriptions();
    _firebaseService.cancelSubscriptions();
    _pairedDeviceId = null;
    _liveLocation = null;
    _liveTelemetry = null;
    _deviceMetadata = null;
    _activeSosEvents = [];
    _lastCloudUpdate = null;
    await _prefs.remove(_keyPairedDevice);
    notifyListeners();
  }

  void _subscribeToDevice() {
    if (!isPaired) return;
    _cancelSubscriptions();

    final deviceId = _pairedDeviceId!;

    // 1. Live Location Stream (keeps last valid location if a temporary GPS reading is null)
    _locSub = _firebaseService.streamLocation(deviceId).listen((loc) {
      if (loc != null) {
        _liveLocation = loc;
        _lastCloudUpdate = DateTime.now();
      }
      notifyListeners();
    });

    // 2. Live Telemetry Stream
    _telemetrySub = _firebaseService.streamTelemetry(deviceId).listen((data) {
      if (data != null) {
        _liveTelemetry = data;
        _lastCloudUpdate = DateTime.now();
      }
      notifyListeners();
    });

    // 3. Device Metadata Stream
    _metaSub = _firebaseService.streamDeviceMetadata(deviceId).listen((meta) {
      if (meta != null) {
        _deviceMetadata = meta;
        if (meta['lastUpdated'] != null) {
          _lastCloudUpdate = DateTime.fromMillisecondsSinceEpoch(meta['lastUpdated'] as int);
        } else {
          _lastCloudUpdate = DateTime.now();
        }
      }
      notifyListeners();
    });

    // 4. Live SOS Incident Stream
    _sosSub = _firebaseService.streamActiveSosEvents(deviceId).listen((events) {
      _activeSosEvents = events;
      notifyListeners();
    });
  }

  Future<void> acknowledgeSos(String eventId) async {
    if (!isPaired) return;
    await _firebaseService.resolveSosEvent(_pairedDeviceId!, eventId);
    _activeSosEvents.removeWhere((e) => e.eventId == eventId);
    notifyListeners();
  }

  void _cancelSubscriptions() {
    _locSub?.cancel();
    _telemetrySub?.cancel();
    _metaSub?.cancel();
    _sosSub?.cancel();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    _firebaseService.cancelSubscriptions();
    super.dispose();
  }
}
