import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_role.dart';
import '../../../providers/blind_user_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/accessible_button.dart';
import '../../role_selection/role_selection_screen.dart';

class BlindUserSettingsScreen extends StatefulWidget {
  const BlindUserSettingsScreen({super.key});

  @override
  State<BlindUserSettingsScreen> createState() => _BlindUserSettingsScreenState();
}

class _BlindUserSettingsScreenState extends State<BlindUserSettingsScreen> {
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _urlController = TextEditingController(text: settings.esp32BaseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final blindProvider = context.watch<BlindUserProvider>();
    final health = blindProvider.healthStatus;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Stick & App Settings'),
        backgroundColor: AppColors.surface,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // Stick Hardware Info
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
                      'Hardware Configuration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.highVisYellow,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _infoRow('Device ID', ApiConstants.defaultDeviceId),
                    _infoRow('Wi-Fi SSID', ApiConstants.defaultSsid),
                    _infoRow('Wi-Fi Password', ApiConstants.defaultPassword),
                    const Divider(color: AppColors.borderLight, height: 24),
                    const Text(
                      'ESP32 HTTP Gateway URL',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _urlController,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.borderLight),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: AppColors.surfaceBright,
                        foregroundColor: AppColors.highVisYellow,
                      ),
                      onPressed: () async {
                        await settings.setEsp32BaseUrl(_urlController.text);
                        blindProvider.startHardwareConnection();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Stick URL updated.')),
                          );
                        }
                      },
                      child: const Text('Save & Reconnect'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Voice Accessibility Settings
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
                      'Voice Accessibility',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.highVisYellow,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Voice Guidance (TTS)',
                          style: TextStyle(color: Colors.white)),
                      subtitle: const Text(
                        'Speak obstacle distances, connection state, and alerts',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                      value: settings.isTtsEnabled,
                      activeThumbColor: AppColors.highVisYellow,
                      onChanged: (val) {
                        settings.setTtsEnabled(val);
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text('Speech Rate',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    Slider(
                      value: settings.speechRate,
                      min: 0.2,
                      max: 1.0,
                      divisions: 8,
                      activeColor: AppColors.highVisYellow,
                      inactiveColor: AppColors.surfaceBright,
                      label: '${(settings.speechRate * 100).toInt()}%',
                      onChanged: (val) {
                        settings.setSpeechRate(val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Hardware Subsystems Diagnostics
            if (health != null) ...[
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
                        'Subsystem Health Check (/health)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.safeGreen,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _healthRow('MPU6050 Accelerometer', health.mpu6050Ok),
                      _healthRow('Left Ultrasonic Sensor', health.leftUltrasonicOk),
                      _healthRow('Middle Ultrasonic Sensor', health.middleUltrasonicOk),
                      _healthRow('Right Ultrasonic Sensor', health.rightUltrasonicOk),
                      _healthRow('Mobile Wi-Fi Associated', health.mobileWifiConnected),
                      _healthRow('App Heartbeat Active', health.mobileAppConnected),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Role Switcher
            AccessibleButton(
              label: 'SWITCH ROLE (CARETAKER)',
              icon: Icons.swap_horiz,
              backgroundColor: AppColors.surfaceBright,
              textColor: AppColors.textPrimary,
              borderColor: AppColors.borderLight,
              onPressed: () async {
                await settings.setUserRole(UserRole.unselected);
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _healthRow(String label, bool isOk) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Row(
            children: [
              Icon(
                isOk ? Icons.check_circle : Icons.cancel,
                color: isOk ? AppColors.safeGreen : AppColors.dangerRed,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                isOk ? 'OK' : 'OFFLINE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isOk ? AppColors.safeGreen : AppColors.dangerRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
