import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/settings_viewmodel.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<SettingsViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _buildSectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            subtitle: const Text('Manage your account details'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => viewModel.openProfile(context),
          ),
          const Divider(),
          _buildSectionHeader('System'),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            subtitle: const Text('Configure alerts and severity'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => viewModel.openNotifications(context),
          ),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Sensor Thresholds'),
            subtitle: const Text('Set min/max values for alerts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => viewModel.openSensorThresholds(context),
          ),
          ListTile(
            leading: const Icon(Icons.auto_mode),
            title: const Text('Automation Rules'),
            subtitle: const Text('Configure auto-control logic'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => viewModel.openAutomationRules(context),
          ),
          ListTile(
            leading: const Icon(Icons.developer_board),
            title: const Text('Virtual Device Settings'),
            subtitle: const Text('Configure simulation ranges'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => viewModel.openVirtualDeviceSettings(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => viewModel.logout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}
