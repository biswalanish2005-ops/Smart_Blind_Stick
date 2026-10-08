import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
            // SafePath Stick Connection (Phone Hotspot Mode)
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
                        Icon(Icons.wifi_tethering, color: AppColors.highVisYellow, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'SafePath Stick Connection',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.highVisYellow,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Required Phone State:',
                            style: TextStyle(
                              color: AppColors.highVisYellow,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text('• Mobile Data → ON (Internet & Cloud SOS)',
                              style: TextStyle(color: Colors.white, fontSize: 13)),
                          Text('• Wi-Fi Hotspot → ON (2.4 GHz band)',
                              style: TextStyle(color: Colors.white, fontSize: 13)),
                          Text('• GPS Location → ON (Emergency Coordinates)',
                              style: TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ESP32 IP Address or Hostname',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _urlController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'monospace',
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. 192.168.43.127 or safepath-stick.local',
                        hintStyle: const TextStyle(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        prefixIcon: const Icon(Icons.router, color: AppColors.highVisYellow),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.borderLight),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              backgroundColor: AppColors.highVisYellow,
                              foregroundColor: Colors.black,
                            ),
                            icon: const Icon(Icons.link),
                            label: const Text('Connect'),
                            onPressed: () async {
                              final input = _urlController.text.trim();
                              if (input.isEmpty) return;
                              await settings.setEsp32BaseUrl(input);
                              await blindProvider.updateEsp32Url(input);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Connected to ESP32 at $input')),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              foregroundColor: AppColors.highVisYellow,
                              side: const BorderSide(color: AppColors.highVisYellow),
                            ),
                            icon: const Icon(Icons.search),
                            label: const Text('Auto-Discover'),
                            onPressed: () async {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Probing hotspot for ESP32...')),
                              );
                              final discovered = await blindProvider.discoverEsp32();
                              if (discovered != null) {
                                _urlController.text = discovered;
                                await settings.setEsp32BaseUrl(discovered);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Found SafePath stick at $discovered!')),
                                  );
                                }
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Not found automatically. Check hotspot IP manually.'),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Caretaker Pairing Code Card (For Caretaker Linking)
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
                        Icon(Icons.qr_code, color: AppColors.highVisYellow, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Caretaker Pairing Code',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.highVisYellow,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Provide this code to your caretaker to pair their phone:',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.highVisYellow, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            blindProvider.deviceId,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                              color: AppColors.highVisYellow,
                              fontFamily: 'monospace',
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.volume_up, color: AppColors.highVisYellow),
                            tooltip: 'Speak Pairing Code',
                            onPressed: () {
                              final chars = blindProvider.deviceId.split('').join(' ');
                              blindProvider.speak('Your pairing code is $chars');
                            },
                          ),
                        ],
                      ),
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
