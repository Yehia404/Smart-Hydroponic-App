import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/splash_screen_viewmodel.dart';
import '../auth/login_screen.dart';
import '../dashboard/dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Start the logic when the screen loads
    _startApp();
  }

  void _startApp() async {
    // 1. Get the ViewModel
    final viewModel = Provider.of<SplashScreenViewModel>(
      context,
      listen: false,
    );

    // 2. Call the logic and WAIT for the result
    SplashDestination destination = await viewModel.initializeApp();

    if (!mounted) return;

    // 3. Navigate based on the result
    if (destination == SplashDestination.dashboard) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco_rounded, size: 100, color: Colors.green),
            SizedBox(height: 24),
            Text(
              'SMART Hydroponic',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 20),
            Text(
              "Initializing system...",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
