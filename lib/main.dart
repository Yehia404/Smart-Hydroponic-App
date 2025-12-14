import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:smart_hydroponic_app/view/auth/login_screen.dart';
import 'firebase_options.dart';
import 'data/services/auth_service.dart';
import 'data/services/firestore_service.dart';
import 'data/services/local_cache_service.dart';
import 'viewmodels/login_viewmodel.dart';
import 'viewmodels/registration_viewmodel.dart';
import 'viewmodels/navigation_viewmodel.dart';
import 'viewmodels/home_overview_viewmodel.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'viewmodels/user_profile_viewmodel.dart';
import 'data/models/threshold_config.dart';
import 'viewmodels/notification_settings_viewmodel.dart';
import 'viewmodels/sensor_thresholds_viewmodel.dart';
import 'viewmodels/control_panel_viewmodel.dart';
import 'viewmodels/actuator_control_viewmodel.dart';
import 'viewmodels/alerts_notifications_viewmodel.dart';
import 'viewmodels/automation_rules_viewmodel.dart';
import 'viewmodels/password_recovery_viewmodel.dart';
import 'utils/virtual_device.dart';
import 'viewmodels/virtual_device_settings_viewmodel.dart';
import 'view/screens/splash_screen.dart';
import 'viewmodels/splash_screen_viewmodel.dart';
import 'viewmodels/sensor_calibration_viewmodel.dart';
import 'viewmodels/actuator_health_viewmodel.dart';
final VirtualDevice virtualHardware = VirtualDevice();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await LocalCacheService.instance.init(); // Initialize local cache
  virtualHardware.start();
  await ThresholdConfig.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService.instance),
        Provider<FirestoreService>(create: (_) => FirestoreService.instance),
        ChangeNotifierProvider(
          // Pass the AuthService to the ViewModel
          create: (context) => SplashScreenViewModel(context.read<AuthService>()),
        ),

        ChangeNotifierProvider(
          create: (context) => LoginViewModel(context.read<AuthService>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              RegistrationViewModel(context.read<AuthService>()),
        ),
        ChangeNotifierProvider(create: (_) => NavigationViewModel()),
        ChangeNotifierProvider(
          create: (context) =>
              HomeOverviewViewModel(context.read<FirestoreService>()),
        ),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => UserProfileViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationSettingsViewModel()),
        ChangeNotifierProvider(create: (_) => SensorThresholdsViewModel()),
        ChangeNotifierProvider(create: (_) => ControlPanelViewModel()),
        ChangeNotifierProvider(
          create: (context) =>
              ActuatorControlViewModel(context.read<FirestoreService>()),
        ),
        ChangeNotifierProvider(create: (_) => AlertsNotificationsViewModel()),
        ChangeNotifierProvider(
          create: (context) =>
              AutomationRulesViewModel(context.read<HomeOverviewViewModel>()),
        ),
        ChangeNotifierProvider(
          create: (context) => LoginViewModel(context.read<AuthService>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              PasswordRecoveryViewModel(context.read<AuthService>()),
        ),
        ChangeNotifierProvider(
          create: (_) => VirtualDeviceSettingsViewModel(virtualHardware),
        ),
        ChangeNotifierProvider(create: (_) => SensorCalibrationViewModel()),
        ChangeNotifierProvider(create: (_) => ActuatorHealthViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SMART Hydroponic',
        theme: ThemeData.dark().copyWith(
          primaryColor: Colors.green,
          scaffoldBackgroundColor: const Color(0xFF1a1a1a),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
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
