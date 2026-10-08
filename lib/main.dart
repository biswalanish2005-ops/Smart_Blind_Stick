import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'features/blind_user/dashboard/blind_user_dashboard.dart';
import 'features/caretaker/dashboard/caretaker_dashboard.dart';
import 'features/role_selection/role_selection_screen.dart';
import 'models/user_role.dart';
import 'providers/blind_user_provider.dart';
import 'providers/caretaker_provider.dart';
import 'providers/settings_provider.dart';
import 'services/emergency_dispatch_service.dart';
import 'services/esp32_service.dart';
import 'services/firebase_service.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'services/tts_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fix orientation to portrait for handheld accessible use
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Core Services
  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);

  final ttsService = TtsService();
  await ttsService.init(
    enabled: storageService.isTtsEnabled(),
    speechRate: storageService.getTtsSpeechRate(),
  );

  final esp32Service = Esp32Service(
    initialBaseUrl: storageService.getEsp32BaseUrl(),
  );

  final locationService = LocationService();
  final firebaseService = FirebaseService();
  await firebaseService.initialize();

  final notificationService = NotificationService();
  await notificationService.init();

  final dispatchService = EmergencyDispatchService(
    notificationService: notificationService,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(
            storageService: storageService,
            ttsService: ttsService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => BlindUserProvider(
            esp32Service: esp32Service,
            storageService: storageService,
            ttsService: ttsService,
            locationService: locationService,
            firebaseService: firebaseService,
            dispatchService: dispatchService,
            notificationService: notificationService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CaretakerProvider(
            firebaseService: firebaseService,
            prefs: prefs,
          ),
        ),
      ],
      child: const SafePathApp(),
    ),
  );
}

class SafePathApp extends StatelessWidget {
  const SafePathApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final initialRole = settings.userRole;

    Widget homeScreen;
    switch (initialRole) {
      case UserRole.blindUser:
        homeScreen = const BlindUserDashboard();
        break;
      case UserRole.caretaker:
        homeScreen = const CaretakerDashboard();
        break;
      case UserRole.unselected:
        homeScreen = const RoleSelectionScreen();
        break;
    }

    return MaterialApp(
      title: 'SafePath',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.highContrastTheme,
      home: homeScreen,
    );
  }
}
