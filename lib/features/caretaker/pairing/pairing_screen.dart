import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/caretaker_provider.dart';
import '../../../widgets/accessible_button.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  late TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<CaretakerProvider>();
    _codeController = TextEditingController(
      text: provider.pairedDeviceId ?? ApiConstants.defaultDeviceId,
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CaretakerProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pair Smart Stick Device'),
        backgroundColor: AppColors.surface,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Icon(
                Icons.phonelink_setup,
                size: 64,
                color: AppColors.caretakerPrimary,
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter Stick Pairing Code',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Obtain the unique Device ID displayed on the Blind User app or stick label.',
                style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: 'Device ID',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.qr_code, color: AppColors.caretakerPrimary),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.caretakerPrimary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AccessibleButton(
                label: 'PAIR & CONNECT',
                icon: Icons.link,
                backgroundColor: AppColors.caretakerPrimary,
                textColor: Colors.white,
                onPressed: () async {
                  final code = _codeController.text.trim();
                  if (code.isNotEmpty) {
                    await provider.pairDevice(code);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                },
              ),
              const Spacer(),
              if (provider.isPaired)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.dangerRed,
                    side: const BorderSide(color: AppColors.dangerRed),
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  icon: const Icon(Icons.link_off),
                  label: Text('Unpair Currently Connected (${provider.pairedDeviceId})'),
                  onPressed: () async {
                    await provider.unpairDevice();
                    _codeController.clear();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
