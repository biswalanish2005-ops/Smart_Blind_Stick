import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/sensor_data.dart';

class MpuTelemetryCard extends StatefulWidget {
  final SensorData? sensorData;

  const MpuTelemetryCard({
    super.key,
    required this.sensorData,
  });

  @override
  State<MpuTelemetryCard> createState() => _MpuTelemetryCardState();
}

class _MpuTelemetryCardState extends State<MpuTelemetryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.sensorData;
    final bool available = data?.mpu6050Available ?? false;
    final bool isFall = data?.fallDetected ?? false;

    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isFall ? AppColors.dangerRed : AppColors.borderLight,
          width: isFall ? 2.5 : 1.5,
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
                  color: isFall ? AppColors.dangerRed : AppColors.highVisYellow,
                  size: 26,
                ),
                const SizedBox(width: 10),
                const Text(
                  'MPU6050 Motion & Fall Monitor',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!available)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'MPU6050 sensor unavailable or stick disconnected.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: 'Acceleration',
                      value: '${data!.accelerationG.toStringAsFixed(2)} G',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricTile(
                      label: 'Tilt Angle',
                      value: '${data.tiltDeg.toStringAsFixed(1)}°',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Fall indicator row
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isFall ? AppColors.dangerRedBg : AppColors.safeGreenBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFall ? AppColors.dangerRed : AppColors.safeGreen,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isFall ? Icons.warning : Icons.check_circle,
                      color: isFall ? AppColors.dangerRed : AppColors.safeGreen,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Fall State: ${isFall ? "FALL DETECTED" : "NORMAL"}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isFall ? AppColors.dangerRed : AppColors.safeGreen,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Expandable Raw 6-Axis Data
              InkWell(
                onTap: () {
                  setState(() {
                    _expanded = !_expanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Advanced 6-Axis Telemetry',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.highVisYellow,
                        ),
                      ),
                      Icon(
                        _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: AppColors.highVisYellow,
                      ),
                    ],
                  ),
                ),
              ),
              if (_expanded) ...[
                const Divider(color: AppColors.borderLight),
                _RawDataRow('Linear Accel (m/s²)', 'AX: ${data.ax.toStringAsFixed(2)}  AY: ${data.ay.toStringAsFixed(2)}  AZ: ${data.az.toStringAsFixed(2)}'),
                const SizedBox(height: 4),
                _RawDataRow('Gyroscope (rad/s)', 'GX: ${data.gx.toStringAsFixed(2)}  GY: ${data.gy.toStringAsFixed(2)}  GZ: ${data.gz.toStringAsFixed(2)}'),
                const SizedBox(height: 4),
                _RawDataRow('Temperature', '${data.temperature.toStringAsFixed(1)} °C'),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _MetricTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RawDataRow extends StatelessWidget {
  final String label;
  final String value;

  const _RawDataRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
