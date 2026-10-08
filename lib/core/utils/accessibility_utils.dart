import 'package:flutter/rendering.dart';
import 'package:url_launcher/url_launcher.dart';

class AccessibilityUtils {
  AccessibilityUtils._();

  /// Announce message to TalkBack / VoiceOver screen readers
  static void announce(String message, {TextDirection textDirection = TextDirection.ltr}) {
    // ignore: deprecated_member_use
    SemanticsService.announce(message, textDirection);
  }

  /// Launch external phone dialer for emergency contact
  static Future<bool> dialPhoneNumber(String phoneNumber) async {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-]'), '');
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    }
    return false;
  }

  /// Launch SMS composer with pre-filled SOS coordinates
  static Future<bool> sendSms(String phoneNumber, String body) async {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-]'), '');
    final uri = Uri(
      scheme: 'sms',
      path: cleaned,
      queryParameters: {'body': body},
    );
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    }
    return false;
  }
}
