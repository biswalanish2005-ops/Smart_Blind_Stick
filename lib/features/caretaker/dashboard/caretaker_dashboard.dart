import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/accessibility_utils.dart';
import '../../../models/user_role.dart';
import '../../../providers/caretaker_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../role_selection/role_selection_screen.dart';
import '../live_map/caretaker_map_view.dart';
import '../pairing/pairing_screen.dart';
import '../sensor_monitor/caretaker_sensor_panel.dart';
import '../sos/caretaker_sos_screen.dart';

class CaretakerDashboard extends StatelessWidget {
  const CaretakerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CaretakerProvider>();
    final settings = context.watch<SettingsProvider>();

    final liveLocation = provider.liveLocation;
    final liveTelemetry = provider.liveTelemetry;
    final isSos = provider.isSosActive;
    final activeSosEvent = provider.activeSosEvents.isNotEmpty
        ? provider.activeSosEvents.first
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SafePath Caretaker Console'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.phonelink_setup),
            tooltip: 'Pair Device',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PairingScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Switch to Blind User Mode',
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
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top Status Bar (Section 7)
                _TopStatusBar(
                  isUserOnline: provider.isBlindUserOnline,
                  isStickConnected: provider.isStickConnected,
                  isSosActive: isSos,
                ),

                // Main Content (Live Map + Telemetry Panel)
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // Section 8: Live Interactive Map
                      SizedBox(
                        height: 340,
                        child: CaretakerMapView(
                          locationData: liveLocation,
                          isSosActive: isSos,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Section 9: Caretaker Sensor Panel
                      CaretakerSensorPanel(
                        telemetry: liveTelemetry,
                        deviceId: provider.pairedDeviceId ?? 'Unknown',
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Section 10: Caretaker SOS Screen (Fullscreen overlay when emergency detected)
            if (isSos && activeSosEvent != null)
              CaretakerSosScreen(
                event: activeSosEvent,
                userPhoneNumber: '',
                onOpenMap: () {
                  // Scroll to map or close overlay
                  if (activeSosEvent.latitude != null &&
                      activeSosEvent.longitude != null) {
                    AccessibilityUtils.sendSms(
                      '',
                      'Emergency location: ${activeSosEvent.mapsUrl}',
                    );
                  }
                },
                onAcknowledge: () async {
                  await provider.acknowledgeSos(activeSosEvent.eventId);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _TopStatusBar extends StatelessWidget {
  final bool isUserOnline;
  final bool isStickConnected;
  final bool isSosActive;

  const _TopStatusBar({
    required this.isUserOnline,
    required this.isStickConnected,
    required this.isSosActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Blind User Status
          _StatusBadge(
            title: 'BLIND USER',
            status: isUserOnline ? 'ONLINE' : 'OFFLINE',
            isPositive: isUserOnline,
          ),
          // Vertical divider
          Container(width: 1, height: 28, color: AppColors.borderLight),
          // Stick Status
          _StatusBadge(
            title: 'STICK',
            status: isStickConnected ? 'CONNECTED' : 'DISCONNECTED',
            isPositive: isStickConnected,
          ),
          // Vertical divider
          Container(width: 1, height: 28, color: AppColors.borderLight),
          // SOS Status
          _StatusBadge(
            title: 'SOS',
            status: isSosActive ? 'ACTIVE' : 'NORMAL',
            isPositive: !isSosActive,
            isEmergency: isSosActive,
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String title;
  final String status;
  final bool isPositive;
  final bool isEmergency;

  const _StatusBadge({
    required this.title,
    required this.status,
    required this.isPositive,
    this.isEmergency = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isEmergency
        ? AppColors.dangerRed
        : (isPositive ? AppColors.safeGreen : AppColors.textMuted);

    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 8, color: color),
            const SizedBox(width: 6),
            Text(
              status,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
