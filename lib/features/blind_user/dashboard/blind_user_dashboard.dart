import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/accessibility_utils.dart';
import '../../../providers/blind_user_provider.dart';
import '../../../widgets/accessible_button.dart';
import '../../../widgets/connection_badge.dart';
import '../../../widgets/mpu_telemetry_card.dart';
import '../../../widgets/sos_alert_dialog.dart';
import '../../../widgets/ultrasonic_gauge.dart';
import '../emergency_contact/emergency_contact_screen.dart';
import '../settings/blind_user_settings_screen.dart';

class BlindUserDashboard extends StatefulWidget {
  const BlindUserDashboard({super.key});

  @override
  State<BlindUserDashboard> createState() => _BlindUserDashboardState();
}

class _BlindUserDashboardState extends State<BlindUserDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BlindUserProvider>().startHardwareConnection();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BlindUserProvider>();
    final sensorData = provider.sensorData;
    final isSos = provider.isSosActive;
    final primaryContact = provider.primaryContact;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SafePath Blind Stick'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, size: 28),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const BlindUserSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                await provider.refreshSensors();
                await provider.fetchHealthDiagnostics();
              },
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // A. ESP32 Connection Status Banner
                  ConnectionBadge(
                    state: provider.connectionState,
                    errorMessage: provider.lastError,
                    onRetry: () {
                      provider.startHardwareConnection();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Prominent SOS Active Banner (if active)
                  if (isSos) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.dangerRedBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.dangerRed, width: 2.5),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.warning, color: AppColors.dangerRed, size: 30),
                              SizedBox(width: 10),
                              Text(
                                'ACTIVE EMERGENCY SOS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Reason: ${provider.sosTriggerReason}',
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                          ),
                          const SizedBox(height: 14),
                          AccessibleButton(
                            label: 'CLEAR STICK SOS ALARM',
                            icon: Icons.check_circle,
                            backgroundColor: Colors.white,
                            textColor: Colors.black,
                            height: 52,
                            onPressed: () async {
                              await provider.clearSos();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // B. Live Ultrasonic Distance Gauges
                  UltrasonicGauge(sensorData: sensorData),
                  const SizedBox(height: 16),

                  // C. Live MPU6050 Acceleration & Fall Indicators
                  MpuTelemetryCard(sensorData: sensorData),
                  const SizedBox(height: 16),

                  // D. Overall Subsystem Health Status
                  _OverallStatusCard(provider: provider),
                  const SizedBox(height: 20),

                  // E. Emergency Quick Actions
                  if (primaryContact != null) ...[
                    AccessibleButton(
                      label: 'CALL ${primaryContact.name.toUpperCase()}',
                      icon: Icons.phone,
                      backgroundColor: AppColors.safeGreen,
                      textColor: Colors.black,
                      onPressed: () {
                        AccessibilityUtils.dialPhoneNumber(primaryContact.phone);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  AccessibleButton(
                    label: primaryContact == null
                        ? 'SET EMERGENCY CONTACT'
                        : 'MANAGE CONTACTS (${provider.emergencyContacts.length})',
                    icon: Icons.contact_phone,
                    backgroundColor: AppColors.surfaceElevated,
                    textColor: AppColors.highVisYellow,
                    borderColor: AppColors.highVisYellow,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EmergencyContactScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Big Manual Emergency SOS Button
                  AccessibleButton(
                    label: 'TRIGGER EMERGENCY SOS',
                    icon: Icons.sos,
                    backgroundColor: AppColors.dangerRed,
                    textColor: Colors.white,
                    height: 72,
                    isDestructive: true,
                    onPressed: () {
                      provider.triggerManualSos();
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Fullscreen SOS Overlay if active
            if (isSos)
              SosAlertDialog(
                triggerReason: provider.sosTriggerReason,
                primaryContact: primaryContact,
                onClearSos: () async {
                  await provider.clearSos();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _OverallStatusCard extends StatelessWidget {
  final BlindUserProvider provider;

  const _OverallStatusCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final data = provider.sensorData;
    final isConnected = provider.isConnected;

    return Card(
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
              'Stick Diagnostics Snapshot',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _statusLine('Stick Status', isConnected ? 'ONLINE' : 'OFFLINE', isConnected),
            _statusLine(
              'MPU6050',
              data?.mpu6050Available == true ? 'OK' : 'UNAVAILABLE',
              data?.mpu6050Available == true,
            ),
            _statusLine(
              'Left Ultrasonic',
              data?.leftDistanceCm != null ? 'OK' : 'NO ECHO',
              data?.leftDistanceCm != null,
            ),
            _statusLine(
              'Middle Ultrasonic',
              data?.middleDistanceCm != null ? 'OK' : 'NO ECHO',
              data?.middleDistanceCm != null,
            ),
            _statusLine(
              'Right Ultrasonic',
              data?.rightDistanceCm != null ? 'OK' : 'NO ECHO',
              data?.rightDistanceCm != null,
            ),
            _statusLine(
              'SOS State',
              provider.isSosActive ? 'ACTIVE' : 'NORMAL',
              !provider.isSosActive,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusLine(String label, String value, bool isOk) {
    final color = isOk ? AppColors.safeGreen : (label == 'SOS State' ? AppColors.dangerRed : AppColors.textMuted);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
