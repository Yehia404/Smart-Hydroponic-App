import 'package:flutter/material.dart';

// NEW: Converted to StatefulWidget to manage filter state
class AlertsNotificationsScreen extends StatefulWidget {
  const AlertsNotificationsScreen({super.key});

  @override
  State<AlertsNotificationsScreen> createState() =>
      _AlertsNotificationsScreenState();
}


class _AlertsNotificationsScreenState extends State<AlertsNotificationsScreen> {
  // NEW: State to track selected filter
  int _selectedFilterIndex = 0;

  @override
  Widget build(BuildContext context) { 
    return Scaffold(
      appBar: AppBar(title: const Text('Alerts & Notifications')),
      body: Column(
        children: [
          // NEW: Severity filtering controls
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _selectedFilterIndex == 0,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedFilterIndex = 0);
                  },
                ), 
                ChoiceChip(
                  label: const Text('Critical'),
                  selected: _selectedFilterIndex == 1,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedFilterIndex = 1);
                  },
                ),
                ChoiceChip(
                  label: const Text('Info'),
                  selected: _selectedFilterIndex == 2,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedFilterIndex = 2);
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                  ),
                  title: const Text('High Temperature Alert'),
                  subtitle: const Text('Temperature reached 30.2°C'),
                  // NEW: Acknowledgment feature
                  trailing: TextButton(
                    onPressed: () {},
                    child: const Text('Dismiss'),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.blue,
                  ),
                  title: const Text('Nutrient Solution Low'),
                  subtitle: const Text('Reservoir level at 15%'),
                  // NEW: Acknowledgment feature
                  trailing: TextButton(
                    onPressed: () {},
                    child: const Text('Dismiss'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
