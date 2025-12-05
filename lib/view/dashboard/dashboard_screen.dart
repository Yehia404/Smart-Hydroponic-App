import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'alerts_notifications_screen.dart';
import '../settings/settings_screen.dart';
import 'bottom_navigation_view.dart';
import '../../viewmodels/navigation_viewmodel.dart';
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text('SMART Hydroponic'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AlertsNotificationsScreen(),
                ),
              );
            },

          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<NavigationViewModel>(
        builder: (context, viewModel, child) => viewModel.currentWidget,
      ),
      bottomNavigationBar: const BottomNavigationView(),
            );
          }
}
