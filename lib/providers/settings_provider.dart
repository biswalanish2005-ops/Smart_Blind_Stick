import 'package:flutter/foundation.dart';
import '../models/user_role.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storageService;
  final TtsService _ttsService;

  late UserRole _userRole;
  late String _esp32BaseUrl;
  late bool _isTtsEnabled;
  late double _speechRate;

  SettingsProvider({
    required StorageService storageService,
    required TtsService ttsService,
  })  : _storageService = storageService,
        _ttsService = ttsService {
    _loadSettings();
  }

  void _loadSettings() {
    _userRole = _storageService.getUserRole();
    _esp32BaseUrl = _storageService.getEsp32BaseUrl();
    _isTtsEnabled = _storageService.isTtsEnabled();
    _speechRate = _storageService.getTtsSpeechRate();
  }

  UserRole get userRole => _userRole;
  String get esp32BaseUrl => _esp32BaseUrl;
  bool get isTtsEnabled => _isTtsEnabled;
  double get speechRate => _speechRate;

  Future<void> setUserRole(UserRole role) async {
    _userRole = role;
    await _storageService.setUserRole(role);
    notifyListeners();
  }

  Future<void> setEsp32BaseUrl(String url) async {
    _esp32BaseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    await _storageService.setEsp32BaseUrl(_esp32BaseUrl);
    notifyListeners();
  }

  Future<void> setTtsEnabled(bool enabled) async {
    _isTtsEnabled = enabled;
    _ttsService.setEnabled(enabled);
    await _storageService.setTtsEnabled(enabled);
    notifyListeners();
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    await _ttsService.setSpeechRate(rate);
    await _storageService.setTtsSpeechRate(rate);
    notifyListeners();
  }
}
