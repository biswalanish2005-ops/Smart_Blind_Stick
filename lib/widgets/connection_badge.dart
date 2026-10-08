import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/esp32_service.dart';

class ConnectionBadge extends StatelessWidget {
  final Esp32ConnectionState state;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const ConnectionBadge({
    super.key,
    required this.state,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    switch (state) {
      case Esp32ConnectionState.connected:
        bgColor = AppColors.safeGreenBg;
        textColor = AppColors.safeGreen;
        icon = Icons.wifi;
        label = 'Stick: CONNECTED';
        break;
      case Esp32ConnectionState.connecting:
        bgColor = AppColors.warningOrangeBg;
        textColor = AppColors.warningOrange;
        icon = Icons.sync;
        label = 'Stick: CONNECTING...';
        break;
      case Esp32ConnectionState.error:
        bgColor = AppColors.dangerRedBg;
        textColor = AppColors.dangerRed;
        icon = Icons.wifi_off;
        label = 'Stick: ERROR / UNREACHABLE';
        break;
      case Esp32ConnectionState.disconnected:
        bgColor = AppColors.dangerRedBg;
        textColor = AppColors.dangerRed;
        icon = Icons.portable_wifi_off;
        label = 'Stick: DISCONNECTED';
        break;
    }

    return Semantics(
      label: label,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: textColor, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: textColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (onRetry != null && state != Esp32ConnectionState.connected)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 28),
                    color: textColor,
                    tooltip: 'Retry Connection',
                    onPressed: onRetry,
                  ),
              ],
            ),
            if (errorMessage != null && errorMessage!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
