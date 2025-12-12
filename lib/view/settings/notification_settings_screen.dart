import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/notification_settings_viewmodel.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<NotificationSettingsViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSwitchTile(
                  'Critical Alerts',
                  'High priority alerts (e.g., High Temp, Leak)',
                  viewModel.criticalEnabled,
                  (val) => viewModel.toggleSetting('critical', val),
                  Icons.error,
                  Colors.red,
                ),
                _buildSwitchTile(
                  'Warnings',
                  'Medium priority alerts (e.g., pH slightly off)',
                  viewModel.warningEnabled,
                  (val) => viewModel.toggleSetting('warning', val),
                  Icons.warning,
                  Colors.orange,
                ),
                _buildSwitchTile(
                  'Info Notifications',
                  'Low priority updates (e.g., System online)',
                  viewModel.infoEnabled,
                  (val) => viewModel.toggleSetting('info', val),
                  Icons.info,
                  Colors.blue,
                ),
              ],
            ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
