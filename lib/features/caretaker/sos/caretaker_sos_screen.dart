import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/accessibility_utils.dart';
import '../../../models/sos_event.dart';
import '../../../widgets/accessible_button.dart';

class CaretakerSosScreen extends StatelessWidget {
  final SosEvent event;
  final String userPhoneNumber;
  final VoidCallback onOpenMap;
  final VoidCallback onAcknowledge;

  const CaretakerSosScreen({
    super.key,
    required this.event,
    this.userPhoneNumber = '',
    required this.onOpenMap,
    required this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    final String timeStr =
        '${event.timestamp.hour.toString().padLeft(2, '0')}:${event.timestamp.minute.toString().padLeft(2, '0')}:${event.timestamp.second.toString().padLeft(2, '0')}';

    return Dialog.fullscreen(
      backgroundColor: AppColors.dangerRedBg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 90,
                color: AppColors.dangerRed,
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(120),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.dangerRed, width: 2),
                ),
                child: Column(
                  children: [
                    _detailRow('Trigger Source', event.type),
                    const SizedBox(height: 8),
                    _detailRow('Incident Time', timeStr),
                    const SizedBox(height: 8),
                    _detailRow(
                      'GPS Coordinates',
                      event.latitude != null && event.longitude != null
                          ? '${event.latitude!.toStringAsFixed(5)}, ${event.longitude!.toStringAsFixed(5)}'
                          : 'Location Unavailable',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              AccessibleButton(
                label: 'OPEN LIVE MAP',
                icon: Icons.map,
                backgroundColor: AppColors.caretakerPrimary,
                textColor: Colors.white,
                onPressed: onOpenMap,
              ),
              const SizedBox(height: 14),
              if (userPhoneNumber.isNotEmpty) ...[
                AccessibleButton(
                  label: 'CALL BLIND USER',
                  icon: Icons.phone,
                  backgroundColor: AppColors.safeGreen,
                  textColor: Colors.black,
                  onPressed: () {
                    AccessibilityUtils.dialPhoneNumber(userPhoneNumber);
                  },
                ),
                const SizedBox(height: 14),
              ],
              AccessibleButton(
                label: 'ACKNOWLEDGE & RESOLVE',
                icon: Icons.check,
                backgroundColor: Colors.white,
                textColor: Colors.black,
                onPressed: onAcknowledge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
