import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../models/emergency_contact.dart';
import '../models/user_role.dart';

/// Local persistence service for SafePath configuration, role, and contacts.
class StorageService {
  static const String _keyUserRole = 'safepath_user_role';
  static const String _keyEsp32BaseUrl = 'safepath_esp32_base_url';
  static const String _keyEmergencyContacts = 'safepath_emergency_contacts';
  static const String _keyTtsEnabled = 'safepath_tts_enabled';
  static const String _keyTtsSpeechRate = 'safepath_tts_speech_rate';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // User Role
  UserRole getUserRole() {
    final roleStr = _prefs.getString(_keyUserRole);
    return UserRole.fromString(roleStr);
  }

  Future<void> setUserRole(UserRole role) async {
    await _prefs.setString(_keyUserRole, role.toStorageString());
  }

  // ESP32 Connection URL
  String getEsp32BaseUrl() {
    return _prefs.getString(_keyEsp32BaseUrl) ?? ApiConstants.defaultBaseUrl;
  }

  Future<void> setEsp32BaseUrl(String url) async {
    final cleanUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    await _prefs.setString(_keyEsp32BaseUrl, cleanUrl);
  }

  // Emergency Contacts
  List<EmergencyContact> getEmergencyContacts() {
    final raw = _prefs.getString(_keyEmergencyContacts);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded
          .map((item) => EmergencyContact.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveEmergencyContacts(List<EmergencyContact> contacts) async {
    final encoded = jsonEncode(contacts.map((c) => c.toJson()).toList());
    await _prefs.setString(_keyEmergencyContacts, encoded);
  }

  // Accessibility TTS Settings
  bool isTtsEnabled() => _prefs.getBool(_keyTtsEnabled) ?? true;
  Future<void> setTtsEnabled(bool enabled) => _prefs.setBool(_keyTtsEnabled, enabled);

  double getTtsSpeechRate() => _prefs.getDouble(_keyTtsSpeechRate) ?? 0.5;
  Future<void> setTtsSpeechRate(double rate) => _prefs.setDouble(_keyTtsSpeechRate, rate);
}
