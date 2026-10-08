import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/app_colors.dart';
import '../models/sensor_data.dart';

class UltrasonicGauge extends StatelessWidget {
  final SensorData? sensorData;

  const UltrasonicGauge({
    super.key,
    required this.sensorData,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderLight, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.radar, color: AppColors.highVisYellow, size: 26),
                SizedBox(width: 10),
                Text(
                  'Ultrasonic Obstacle Proximity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SensorColumn(
                    direction: 'LEFT',
                    distanceCm: sensorData?.leftDistanceCm,
                    status: sensorData?.leftSensorStatus ?? 'no_echo',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SensorColumn(
                    direction: 'MIDDLE',
                    distanceCm: sensorData?.middleDistanceCm,
                    status: sensorData?.middleSensorStatus ?? 'no_echo',
                    isPriority: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SensorColumn(
                    direction: 'RIGHT',
                    distanceCm: sensorData?.rightDistanceCm,
                    status: sensorData?.rightSensorStatus ?? 'no_echo',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SensorColumn extends StatelessWidget {
  final String direction;
  final double? distanceCm;
  final String status;
  final bool isPriority;

  const _SensorColumn({
    required this.direction,
    required this.distanceCm,
    required this.status,
    this.isPriority = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasReading = distanceCm != null && distanceCm! > 0;
    final bool isDanger = hasReading && distanceCm! < ApiConstants.dangerThresholdCm;

    Color badgeColor;
    Color textColor;
    String stateText;

    if (!hasReading) {
      badgeColor = AppColors.surfaceElevated;
      textColor = AppColors.textMuted;
      stateText = 'No Echo';
    } else if (isDanger) {
      badgeColor = AppColors.dangerRedBg;
      textColor = AppColors.dangerRed;
      stateText = 'Danger';
    } else {
      badgeColor = AppColors.safeGreenBg;
      textColor = AppColors.safeGreen;
      stateText = 'Safe';
    }

    final semanticText = hasReading
        ? '$direction sensor: ${distanceCm!.toStringAsFixed(1)} centimeters. State is $stateText.'
        : '$direction sensor is unavailable or no echo received.';

    return Semantics(
      label: semanticText,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDanger ? AppColors.dangerRed : (isPriority ? AppColors.highVisYellow : AppColors.borderLight),
            width: isDanger || isPriority ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Text(
              direction,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isPriority ? AppColors.highVisYellow : AppColors.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasReading ? '${distanceCm!.toStringAsFixed(1)} cm' : '-- cm',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: textColor.withAlpha(38),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                stateText.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
