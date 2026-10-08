import 'package:flutter/services.dart';

/// Haptic tactile feedback service for accessibility cues
class HapticService {
  HapticService._();

  static Future<void> lightClick() async {
    await HapticFeedback.lightImpact();
  }

  static Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }

  static Future<void> obstacleDangerAlert() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }

  static Future<void> emergencySosAlert() async {
    for (int i = 0; i < 4; i++) {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }
}
