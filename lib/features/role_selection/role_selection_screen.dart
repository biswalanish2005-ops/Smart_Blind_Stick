import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/user_role.dart';
import '../../providers/settings_provider.dart';
import '../blind_user/dashboard/blind_user_dashboard.dart';
import '../caretaker/dashboard/caretaker_dashboard.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Header
              const Text(
                AppStrings.appName,
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: AppColors.highVisYellow,
                  letterSpacing: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                AppStrings.appTagline,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              const Text(
                AppStrings.chooseRoleTitle,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                AppStrings.chooseRoleSubtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),

              // Role Option 1: Blind Stick User
              _RoleCard(
                title: AppStrings.roleBlindUser,
                description: AppStrings.roleBlindUserDesc,
                icon: Icons.blind,
                primaryColor: AppColors.highVisYellow,
                textColor: Colors.black,
                onTap: () async {
                  final settings = context.read<SettingsProvider>();
                  await settings.setUserRole(UserRole.blindUser);
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const BlindUserDashboard(),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),

              // Role Option 2: Caretaker
              _RoleCard(
                title: AppStrings.roleCaretaker,
                description: AppStrings.roleCaretakerDesc,
                icon: Icons.health_and_safety,
                primaryColor: AppColors.caretakerPrimary,
                textColor: Colors.white,
                onTap: () async {
                  final settings = context.read<SettingsProvider>();
                  await settings.setUserRole(UserRole.caretaker);
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const CaretakerDashboard(),
                      ),
                    );
                  }
                },
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color primaryColor;
  final Color textColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.primaryColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $description',
      child: Material(
        color: primaryColor,
        borderRadius: BorderRadius.circular(18),
        elevation: 4,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 22.0),
            child: Row(
              children: [
                Icon(icon, size: 42, color: textColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withAlpha(216),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: textColor, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
