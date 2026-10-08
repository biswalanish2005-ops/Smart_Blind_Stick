import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/location_data.dart';

enum LocationServiceStatus {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  trackingActive,
  idle,
}

/// Real Phone GPS service.
/// MANDATORY RULE: No simulated coordinates, no mock GPS.
class LocationService {
  StreamSubscription<Position>? _positionSub;
  final StreamController<LocationData> _locationStreamController =
      StreamController<LocationData>.broadcast();
  final StreamController<LocationServiceStatus> _statusController =
      StreamController<LocationServiceStatus>.broadcast();

  LocationData? _lastKnownLocation;
  LocationServiceStatus _status = LocationServiceStatus.idle;

  LocationData? get lastKnownLocation => _lastKnownLocation;
  LocationServiceStatus get status => _status;
  Stream<LocationData> get locationStream => _locationStreamController.stream;
  Stream<LocationServiceStatus> get statusStream => _statusController.stream;

  /// Ensure permissions and acquire current position
  Future<LocationData?> getCurrentLocation() async {
    final hasPermission = await _ensurePermissions();
    if (!hasPermission) return null;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final loc = LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
        heading: position.heading,
        timestamp: position.timestamp,
      );

      _lastKnownLocation = loc;
      _locationStreamController.add(loc);
      return loc;
    } catch (e) {
      debugPrint('Error getting GPS location: $e');
      return null;
    }
  }

  /// Start continuous GPS streaming for live caretaker map updates
  Future<bool> startTracking() async {
    final hasPermission = await _ensurePermissions();
    if (!hasPermission) return false;

    _positionSub?.cancel();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3, // Update every 3 meters
    );

    _positionSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        final loc = LocationData(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          speed: position.speed,
          heading: position.heading,
          timestamp: position.timestamp,
        );

        _lastKnownLocation = loc;
        _locationStreamController.add(loc);
      },
      onError: (e) {
        debugPrint('Location stream error: $e');
      },
    );

    _setStatus(LocationServiceStatus.trackingActive);
    return true;
  }

  void stopTracking() {
    _positionSub?.cancel();
    _positionSub = null;
    _setStatus(LocationServiceStatus.idle);
  }

  Future<bool> _ensurePermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _setStatus(LocationServiceStatus.serviceDisabled);
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _setStatus(LocationServiceStatus.permissionDenied);
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _setStatus(LocationServiceStatus.permissionDeniedForever);
      return false;
    }

    return true;
  }

  void _setStatus(LocationServiceStatus status) {
    _status = status;
    _statusController.add(status);
  }

  void dispose() {
    _positionSub?.cancel();
    _locationStreamController.close();
    _statusController.close();
  }
}
