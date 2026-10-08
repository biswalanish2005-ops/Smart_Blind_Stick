import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/sensor_data.dart';

class CaretakerSensorPanel extends StatelessWidget {
  final SensorData? telemetry;
  final String deviceId;

  const CaretakerSensorPanel({
    super.key,
    required this.telemetry,
    required this.deviceId,
  });

  @override
  Widget build(BuildContext context) {
    final t = telemetry;
    final bool isFall = t?.fallDetected ?? false;
    final bool hasData = t != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Obstacle Ultrasonics Card
        Card(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.borderLight),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.radar, color: AppColors.caretakerSecondary, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Stick Obstacle Radar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _DistanceTile(
                        label: 'LEFT',
                        distanceCm: t?.leftDistanceCm,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DistanceTile(
                        label: 'MIDDLE',
                        distanceCm: t?.middleDistanceCm,
                        isCenter: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DistanceTile(
                        label: 'RIGHT',
                        distanceCm: t?.rightDistanceCm,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 2. MPU6050 Motion & Fall Card
        Card(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isFall ? AppColors.dangerRed : AppColors.borderLight,
              width: isFall ? 2.0 : 1.0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.screen_rotation,
                      color: isFall ? AppColors.dangerRed : AppColors.caretakerSecondary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Motion & IMU Diagnostics',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _MetricItem(
                        label: 'Acceleration',
                        value: hasData ? '${t.accelerationG.toStringAsFixed(2)} G' : '--',
                      ),
                    ),
                    Expanded(
                      child: _MetricItem(
                        label: 'Tilt Angle',
                        value: hasData ? '${t.tiltDeg.toStringAsFixed(1)}°' : '--',
                      ),
                    ),
                    Expanded(
                      child: _MetricItem(
                        label: 'Fall State',
                        value: isFall ? 'DETECTED' : 'NORMAL',
                        valueColor: isFall ? AppColors.dangerRed : AppColors.safeGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 3. Stick Hardware Metadata Card
        Card(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.borderLight),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hardware Identity & Network',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                _InfoLine('Device ID', deviceId),
                _InfoLine('Stick Wi-Fi', t?.wifiConnected == true ? 'CONNECTED' : 'DISCONNECTED'),
                _InfoLine('Phone App Gateway', t?.appConnected == true ? 'ACTIVE' : 'OFFLINE'),
                _InfoLine(
                  'Last Cloud Update',
                  hasData
                      ? '${DateTime.now().difference(t.receivedAt).inSeconds}s ago'
                      : 'Never',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DistanceTile extends StatelessWidget {
  final String label;
  final double? distanceCm;
  final bool isCenter;

  const _DistanceTile({
    required this.label,
    required this.distanceCm,
    this.isCenter = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasReading = distanceCm != null && distanceCm! > 0;
    final bool isDanger = hasReading && distanceCm! < ApiConstants.dangerThresholdCm;

    Color color;
    String statusText;

    if (!hasReading) {
      color = AppColors.textMuted;
      statusText = 'No Echo';
    } else if (isDanger) {
      color = AppColors.dangerRed;
      statusText = 'DANGER';
    } else {
      color = AppColors.safeGreen;
      statusText = 'SAFE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDanger ? AppColors.dangerRed : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isCenter ? AppColors.caretakerAccent : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasReading ? '${distanceCm!.toStringAsFixed(1)} cm' : '--',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MetricItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
