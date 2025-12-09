import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/control_panel_viewmodel.dart';
import '../../viewmodels/actuator_control_viewmodel.dart';

class ControlPanelScreen extends StatelessWidget {
  const ControlPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ControlPanelViewModel>(context);
    final actuatorViewModel = Provider.of<ActuatorControlViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Control Panel')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildControlSwitch(
            title: 'Water Pump',
            value: actuatorViewModel.isPumpOn,
            onChanged: actuatorViewModel.togglePump,
            icon: Icons.water_damage_outlined,
          ),
          const Divider(),
          _buildControlSwitch(
            title: 'Grow Lights',
            value: actuatorViewModel.areLightsOn,
            onChanged: actuatorViewModel.toggleLights,
            icon: Icons.lightbulb_outline_rounded,
          ),
          const Divider(),
          _buildControlSwitch(
            title: 'Cooling Fans',
            value: actuatorViewModel.areFansOn,
            onChanged: actuatorViewModel.toggleFans,
            icon: Icons.air_rounded,
          ),
          const Divider(height: 40),
          ListTile(
            leading: const Icon(Icons.schedule_outlined),
            title: const Text('Schedule Tasks'),
            subtitle: const Text('Automate pump and light cycles'),
            onTap: () => viewModel.openScheduleTasks(context),
          ),
          ListTile(
            leading: const Icon(Icons.history_outlined),
            title: const Text('Control History Logs'),
            subtitle: const Text('View past manual actions'),
            onTap: () => viewModel.openControlHistory(context),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: actuatorViewModel.emergencyStop,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Emergency Stop'),
          ),
        ],
      ),
    );
  }

  Widget _buildControlSwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 18)),
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon, size: 30),
    );
  }
}
