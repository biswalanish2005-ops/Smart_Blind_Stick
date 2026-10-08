import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/haptic_service.dart';

class AccessibleButton extends StatelessWidget {
  final String label;
  final String? semanticLabel;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final double height;
  final bool isDestructive;

  const AccessibleButton({
    super.key,
    required this.label,
    this.semanticLabel,
    required this.onPressed,
    this.icon,
    this.backgroundColor = AppColors.highVisYellow,
    this.textColor = Colors.black,
    this.borderColor,
    this.height = 64.0,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = isDestructive ? AppColors.dangerRed : backgroundColor;
    final effectiveText = isDestructive ? Colors.white : textColor;

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel ?? label,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: effectiveBg,
            foregroundColor: effectiveText,
            disabledBackgroundColor: AppColors.surfaceElevated,
            disabledForegroundColor: AppColors.textMuted,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: borderColor != null
                  ? BorderSide(color: borderColor!, width: 2)
                  : BorderSide.none,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: onPressed == null
              ? null
              : () {
                  HapticService.lightClick();
                  onPressed!();
                },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 28, color: effectiveText),
                const SizedBox(width: 12),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: effectiveText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
