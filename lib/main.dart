import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:smart_hydroponic_app/view/auth/login_screen.dart';
import 'firebase_options.dart';
import 'data/services/auth_service.dart';
import 'data/services/firestore_service.dart';
import 'viewmodels/login_viewmodel.dart';
import 'viewmodels/registration_viewmodel.dart';
import 'viewmodels/navigation_viewmodel.dart';
import 'viewmodels/home_overview_viewmodel.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'data/models/threshold_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
          create: (context) => LoginViewModel(context.read<AuthService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => RegistrationViewModel(context.read<AuthService>()),
        ),
        ChangeNotifierProvider(create: (_) => NavigationViewModel()),
        ChangeNotifierProvider(
          create: (context) => HomeOverviewViewModel(context.read<FirestoreService>()),
        ),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SMART Hydroponic',
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
        home: const LoginScreen(),
      ),
    );
  }
}
