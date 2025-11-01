import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Profile'),
            subtitle: Text('Manage your account details'),
            onTap: null,
          ),
          const ListTile(
            leading: Icon(Icons.notifications_outlined),
            title: Text('Notifications'),
            subtitle: Text('Set alert thresholds'),
            onTap: null,
          ),
          // NEW: System Calibration option
          const ListTile(
            leading: Icon(Icons.tune_outlined),
            title: Text('System Calibration'),
            subtitle: Text('Calibrate sensors and actuators'),
            onTap: null,
          ),
        ],
      ),
    );
  }
}