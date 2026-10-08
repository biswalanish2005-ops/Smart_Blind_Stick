import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/emergency_contact.dart';
import '../models/location_data.dart';
import '../models/sensor_data.dart';
import '../models/sos_event.dart';

/// Real Firebase Backend Service managing Authentication and Firestore data synchronization.
/// Authoritative schema defined in SafePath_Antigravity_Gemini38_Build_Spec.md Section 11.
class FirebaseService {
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  String? get currentUserId => _auth?.currentUser?.uid;

  Future<bool> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _firestore = FirebaseFirestore.instance;
      _auth = FirebaseAuth.instance;
      _isInitialized = true;
      debugPrint('Firebase initialized successfully.');
      return true;
    } catch (e) {
      debugPrint('Firebase initialization notice: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Ensure authenticated session (signs in anonymously if needed)
  Future<User?> ensureAuthenticated() async {
    if (!_isInitialized || _auth == null) return null;
    try {
      if (_auth!.currentUser == null) {
        final credential = await _auth!.signInAnonymously();
        return credential.user;
      }
      return _auth!.currentUser;
    } catch (e) {
      debugPrint('Firebase auth error: $e');
      return null;
    }
  }

  // -------------------------------------------------------------
  // Blind User Upload Pipeline
  // -------------------------------------------------------------

  /// Upload real GPS location to devices/{{deviceId}}/location/current
  Future<void> uploadLocation(String deviceId, LocationData location) async {
    if (!_isInitialized || _firestore == null) return;
    try {
      await _firestore!
          .collection('devices')
          .doc(deviceId)
          .collection('location')
          .doc('current')
          .set(location.toJson(), SetOptions(merge: true));

      // Also update parent device timestamp
      await _firestore!.collection('devices').doc(deviceId).set({
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to upload location to Firebase: $e');
    }
  }

  /// Upload real stick telemetry to devices/{{deviceId}}/telemetry/current
  Future<void> uploadTelemetry(String deviceId, SensorData telemetry) async {
    if (!_isInitialized || _firestore == null) return;
    try {
      await _firestore!
          .collection('devices')
          .doc(deviceId)
          .collection('telemetry')
          .doc('current')
          .set(telemetry.toJson(), SetOptions(merge: true));

      await _firestore!.collection('devices').doc(deviceId).set({
        'deviceStatus': telemetry.deviceStatus,
        'appConnected': telemetry.appConnected,
        'mpu6050Available': telemetry.mpu6050Available,
        'sosActive': telemetry.sosActive,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to upload telemetry to Firebase: $e');
    }
  }

  /// Record a persistent SOS incident in devices/{{deviceId}}/sosEvents/{{eventId}}
  Future<void> createSosEvent(String deviceId, SosEvent event) async {
    if (!_isInitialized || _firestore == null) return;
    try {
      await _firestore!
          .collection('devices')
          .doc(deviceId)
          .collection('sosEvents')
          .doc(event.eventId)
          .set(event.toJson());

      // Elevate active flag on device doc
      await _firestore!.collection('devices').doc(deviceId).set({
        'sosActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to create SOS event in Firebase: $e');
    }
  }

  /// Acknowledge / Resolve SOS incident
  Future<void> resolveSosEvent(String deviceId, String eventId) async {
    if (!_isInitialized || _firestore == null) return;
    try {
      await _firestore!
          .collection('devices')
          .doc(deviceId)
          .collection('sosEvents')
          .doc(eventId)
          .update({
        'acknowledged': true,
        'resolved_at': FieldValue.serverTimestamp(),
      });

      await _firestore!.collection('devices').doc(deviceId).update({
        'sosActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to resolve SOS event in Firebase: $e');
    }
  }

  /// Sync Emergency Contact to devices/{{deviceId}}/emergencyContact/current
  Future<void> uploadEmergencyContact(String deviceId, EmergencyContact contact) async {
    if (!_isInitialized || _firestore == null) return;
    try {
      await _firestore!
          .collection('devices')
          .doc(deviceId)
          .collection('emergencyContact')
          .doc('current')
          .set(contact.toJson());
    } catch (e) {
      debugPrint('Failed to upload emergency contact to Firebase: $e');
    }
  }

  // -------------------------------------------------------------
  // Caretaker Real-Time Subscriptions
  // -------------------------------------------------------------

  /// Stream live location from devices/{{deviceId}}/location/current
  Stream<LocationData?> streamLocation(String deviceId) {
    if (!_isInitialized || _firestore == null) {
      return Stream.value(null);
    }
    return _firestore!
        .collection('devices')
        .doc(deviceId)
        .collection('location')
        .doc('current')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return LocationData.fromJson(snapshot.data()!);
    });
  }

  /// Stream live telemetry from devices/{{deviceId}}/telemetry/current
  Stream<SensorData?> streamTelemetry(String deviceId) {
    if (!_isInitialized || _firestore == null) {
      return Stream.value(null);
    }
    return _firestore!
        .collection('devices')
        .doc(deviceId)
        .collection('telemetry')
        .doc('current')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return SensorData.fromJson(snapshot.data()!);
    });
  }

  /// Stream device root metadata (online/offline, sosActive, etc.)
  Stream<Map<String, dynamic>?> streamDeviceMetadata(String deviceId) {
    if (!_isInitialized || _firestore == null) {
      return Stream.value(null);
    }
    return _firestore!
        .collection('devices')
        .doc(deviceId)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  /// Stream active unresolved SOS events
  Stream<List<SosEvent>> streamActiveSosEvents(String deviceId) {
    if (!_isInitialized || _firestore == null) {
      return Stream.value([]);
    }
    return _firestore!
        .collection('devices')
        .doc(deviceId)
        .collection('sosEvents')
        .where('acknowledged', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SosEvent.fromJson(doc.data()))
          .toList();
    });
  }
}
