import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/accessibility_utils.dart';
import '../models/emergency_contact.dart';
import 'accessible_button.dart';

class SosAlertDialog extends StatelessWidget {
  final String triggerReason;
  final EmergencyContact? primaryContact;
  final VoidCallback onClearSos;

  const SosAlertDialog({
    super.key,
    required this.triggerReason,
    this.primaryContact,
    required this.onClearSos,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: AppColors.dangerRedBg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 96,
                color: AppColors.dangerRed,
              ),
              const SizedBox(height: 16),
              const Text(
                '🚨 SOS ACTIVE 🚨',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.dangerRed,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'TRIGGER: $triggerReason',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'The Smart Stick alarm buzzer is active and an emergency signal is broadcasting.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (primaryContact != null) ...[
                AccessibleButton(
                  label: 'CALL ${primaryContact!.name.toUpperCase()}',
                  icon: Icons.phone_in_talk,
                  backgroundColor: AppColors.safeGreen,
                  textColor: Colors.black,
                  onPressed: () {
                    AccessibilityUtils.dialPhoneNumber(primaryContact!.phone);
                  },
                ),
                const SizedBox(height: 16),
              ],
              AccessibleButton(
                label: 'CLEAR & RESET STICK ALARM',
                icon: Icons.check_circle_outline,
                backgroundColor: Colors.white,
                textColor: Colors.black,
                onPressed: onClearSos,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
