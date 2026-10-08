import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Text-to-Speech audio service designed for visually impaired assistance.
/// Includes smart throttling and prioritization to prevent audio overlap.
class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isEnabled = true;
  double _speechRate = 0.5;

  String? _lastSpokenMessage;
  DateTime? _lastSpokenTime;
  static const Duration _duplicateThrottle = Duration(milliseconds: 2500);

  bool get isEnabled => _isEnabled;
  double get speechRate => _speechRate;

  Future<void> init({bool enabled = true, double speechRate = 0.5}) async {
    _isEnabled = enabled;
    _speechRate = speechRate;

    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.awaitSpeakCompletion(true);
      _isInitialized = true;
    } catch (e) {
      debugPrint('TTS Initialization warning: $e');
    }
  }

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      stop();
    }
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.2, 1.0);
    if (_isInitialized) {
      try {
        await _flutterTts.setSpeechRate(_speechRate);
      } catch (e) {
        debugPrint('Failed to set speech rate: $e');
      }
    }
  }

  /// Speak a message with debounce protection for periodic telemetry
  Future<void> speak(
    String message, {
    bool isUrgent = false,
  }) async {
    if (!_isEnabled || message.trim().isEmpty) return;

    final now = DateTime.now();
    if (!isUrgent &&
        _lastSpokenMessage == message &&
        _lastSpokenTime != null &&
        now.difference(_lastSpokenTime!) < _duplicateThrottle) {
      // Suppress redundant repeated telemetry announcement
      return;
    }

    _lastSpokenMessage = message;
    _lastSpokenTime = now;

    try {
      if (isUrgent) {
        await _flutterTts.stop();
      }
      await _flutterTts.speak(message);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }
}
