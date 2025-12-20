import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // 1. Import Firebase Core
import 'package:provider/provider.dart';          // 2. Import Provider
import 'view/screens/splash_screen.dart';
import 'firebase_options.dart';                   // 3. Import Generated Options
import 'data/services/notification_service.dart'; // 4. Import Notification Service
import 'data/services/task_scheduler_service.dart'; // 5. Import Task Scheduler Service
import 'data/services/local_cache_service.dart';  // 6. Import Local Cache Service
import 'viewmodels/splash_screen_viewmodel.dart';
import 'utils/virtual_device.dart';
import 'data/services/auth_service.dart';         // Import your Services
import 'data/services/firestore_service.dart';    // Import FirestoreService
import 'viewmodels/login_viewmodel.dart';         // Import your ViewModels
import 'viewmodels/registration_viewmodel.dart';
import 'viewmodels/password_recovery_viewmodel.dart';
import 'viewmodels/navigation_viewmodel.dart';
import 'viewmodels/dashboard_viewmodel.dart';
import 'viewmodels/home_overview_viewmodel.dart';
import 'viewmodels/sensor_monitoring_viewmodel.dart';
import 'viewmodels/actuator_control_viewmodel.dart';
import 'viewmodels/control_panel_viewmodel.dart';
import 'viewmodels/alerts_notifications_viewmodel.dart';
import 'viewmodels/analytics_history_viewmodel.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'viewmodels/tts_viewmodel.dart';
import 'viewmodels/speech_recognition_viewmodel.dart';
import 'viewmodels/sensor_thresholds_viewmodel.dart';
import 'viewmodels/notification_settings_viewmodel.dart';
import 'viewmodels/automation_rules_viewmodel.dart';
import 'viewmodels/user_profile_viewmodel.dart';
import 'data/models/threshold_config.dart';
import 'viewmodels/virtual_device_settings_viewmodel.dart';
import 'viewmodels/sensor_calibration_viewmodel.dart';
import 'viewmodels/actuator_health_viewmodel.dart';
final VirtualDevice virtualHardware = VirtualDevice();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. INITIALIZE FIREBASE
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. START VIRTUAL HARDWARE
  virtualHardware.start();
  
  // 3. INITIALIZE NOTIFICATIONS
  await NotificationService.instance.init();
  
  // 4. START TASK SCHEDULER
  TaskSchedulerService.instance.start();

  // 5. INITIALIZE THRESHOLDS FROM DATABASE
  await ThresholdConfig.instance.init();

  // 6. INITIALIZE LOCAL CACHE (for offline data)
  await LocalCacheService.instance.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 3. WRAP APP IN MULTIPROVIDER
    return MultiProvider(
      providers: [
        // A. Provide the Services (Singletons)
        Provider<AuthService>(create: (_) => AuthService.instance),
        Provider<FirestoreService>(create: (_) => FirestoreService.instance),

        // B. Provide the ViewModels
        // Note: LoginViewModel needs AuthService, so we read it from context
        ChangeNotifierProvider(
          // Pass the AuthService to the ViewModel
          create: (context) => SplashScreenViewModel(context.read<AuthService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => LoginViewModel(context.read<AuthService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => RegistrationViewModel(context.read<AuthService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => PasswordRecoveryViewModel(context.read<AuthService>()),
        ),

        // Navigation ViewModel
        ChangeNotifierProvider(
          create: (_) => NavigationViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => DashboardViewModel(),
        ),

        // Dashboard ViewModels
        ChangeNotifierProvider(
          create: (context) => ActuatorControlViewModel(context.read<FirestoreService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => HomeOverviewViewModel(context.read<FirestoreService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => SensorMonitoringViewModel(context.read<FirestoreService>()),
        ),
        ChangeNotifierProvider(
          create: (_) => ControlPanelViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => AlertsNotificationsViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => AnalyticsHistoryViewModel(),
        ),

        ChangeNotifierProvider(
          create: (_) => SettingsViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => TtsViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => SpeechRecognitionViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => SensorThresholdsViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationSettingsViewModel(),
        ),
        ChangeNotifierProvider(
          create: (context) => AutomationRulesViewModel(context.read<HomeOverviewViewModel>()),
        ),
        ChangeNotifierProvider(
          create: (_) => UserProfileViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => VirtualDeviceSettingsViewModel(virtualHardware),
        ),
        ChangeNotifierProvider(create: (_) => SensorCalibrationViewModel()),
        ChangeNotifierProvider(create: (_) => ActuatorHealthViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          primaryColor: Colors.green,
          scaffoldBackgroundColor: const Color(0xFF1a1a1a),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}