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

  bool get isBlindUserOnline {
    if (_liveLocation == null) return false;
    return !_liveLocation!.isStale;
  }

  bool get isStickConnected {
    if (_liveTelemetry == null) return false;
    return _liveTelemetry!.appConnected &&
        DateTime.now().difference(_liveTelemetry!.receivedAt).inSeconds < 15;
  }

  void _loadPairedDevice() {
    _pairedDeviceId = _prefs.getString(_keyPairedDevice);
    if (_pairedDeviceId == null || _pairedDeviceId!.isEmpty) {
      // Default to standard hardware IDESP32-SAFEPATH-01
      _pairedDeviceId = ApiConstants.defaultDeviceId;
    }
    _subscribeToDevice();
  }

  Future<void> pairDevice(String deviceId) async {
    final cleanId = deviceId.trim();
    if (cleanId.isEmpty) return;

    _pairedDeviceId = cleanId;
    await _prefs.setString(_keyPairedDevice, cleanId);
    _subscribeToDevice();
    notifyListeners();
  }

  Future<void> unpairDevice() async {
    _cancelSubscriptions();
    _pairedDeviceId = null;
    _liveLocation = null;
    _liveTelemetry = null;
    _deviceMetadata = null;
    _activeSosEvents = [];
    await _prefs.remove(_keyPairedDevice);
    notifyListeners();
  }

  void _subscribeToDevice() {
    if (!isPaired) return;
    _cancelSubscriptions();

    final deviceId = _pairedDeviceId!;

    // 1. Live Location Stream
    _locSub = _firebaseService.streamLocation(deviceId).listen((loc) {
      _liveLocation = loc;
      notifyListeners();
    });

    // 2. Live Telemetry Stream
    _telemetrySub = _firebaseService.streamTelemetry(deviceId).listen((data) {
      _liveTelemetry = data;
      notifyListeners();
    });

    // 3. Device Metadata Stream
    _metaSub = _firebaseService.streamDeviceMetadata(deviceId).listen((meta) {
      _deviceMetadata = meta;
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
    super.dispose();
  }
}
