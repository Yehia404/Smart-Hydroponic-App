import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool criticalEnabled = true;
  bool warningEnabled = true;
  bool infoEnabled = false;
  bool isLoading = false;

  void toggleSetting(String type, bool value) {
    setState(() {
      switch (type) {
        case 'critical':
          criticalEnabled = value;
          break;
        case 'warning':
          warningEnabled = value;
          break;
        case 'info':
          infoEnabled = value;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSwitchTile(
                  'Critical Alerts',
                  'High priority alerts (e.g., High Temp, Leak)',
                  criticalEnabled,
                  (val) => toggleSetting('critical', val),
                  Icons.error,
                  Colors.red,
                ),
                _buildSwitchTile(
                  'Warnings',
                  'Medium priority alerts (e.g., pH slightly off)',
                  warningEnabled,
                  (val) => toggleSetting('warning', val),
                  Icons.warning,
                  Colors.orange,
                ),
                _buildSwitchTile(
                  'Info Notifications',
                  'Low priority updates (e.g., System online)',
                  infoEnabled,
                  (val) => toggleSetting('info', val),
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
