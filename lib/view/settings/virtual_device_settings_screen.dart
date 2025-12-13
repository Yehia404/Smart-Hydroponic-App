import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/virtual_device_settings_viewmodel.dart';

class VirtualDeviceSettingsScreen extends StatelessWidget {
  const VirtualDeviceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Virtual Device Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset to Defaults',
            onPressed: () {
              Provider.of<VirtualDeviceSettingsViewModel>(context, listen: false)
                  .resetToDefaults();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reset to default values')),
              );
            },
          ),
        ],
      ),
      body: Consumer<VirtualDeviceSettingsViewModel>(
        builder: (context, viewModel, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Configure the simulation ranges for the virtual device sensor data',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              
              _buildRangeSection(
                title: 'Temperature (°C)',
                icon: Icons.thermostat_outlined,
                min: 15.0,
                max: 35.0,
                currentMin: viewModel.tempMin,
                currentMax: viewModel.tempMax,
                onMinChanged: viewModel.setTempMin,
                onMaxChanged: viewModel.setTempMax,
                divisions: 40,
              ),
              
              const Divider(height: 32),
              
              _buildRangeSection(
                title: 'pH Level',
                icon: Icons.science_outlined,
                min: 4.0,
                max: 10.0,
                currentMin: viewModel.phMin,
                currentMax: viewModel.phMax,
                onMinChanged: viewModel.setPhMin,
                onMaxChanged: viewModel.setPhMax,
                divisions: 60,
              ),
              
              const Divider(height: 32),
              
              _buildRangeSection(
                title: 'Water Level (%)',
                icon: Icons.water_drop_outlined,
                min: 0.0,
                max: 100.0,
                currentMin: viewModel.waterLevelMin,
                currentMax: viewModel.waterLevelMax,
                onMinChanged: viewModel.setWaterLevelMin,
                onMaxChanged: viewModel.setWaterLevelMax,
                divisions: 20,
              ),
              
              const Divider(height: 32),
              
              _buildRangeSection(
                title: 'Light Intensity (%)',
                icon: Icons.light_mode_outlined,
                min: 0.0,
                max: 100.0,
                currentMin: viewModel.lightMin,
                currentMax: viewModel.lightMax,
                onMinChanged: viewModel.setLightMin,
                onMaxChanged: viewModel.setLightMax,
                divisions: 20,
              ),
              
              const Divider(height: 32),
              
              _buildRangeSection(
                title: 'TDS (ppm)',
                icon: Icons.opacity_outlined,
                min: 200.0,
                max: 2000.0,
                currentMin: viewModel.tdsMin,
                currentMax: viewModel.tdsMax,
                onMinChanged: viewModel.setTdsMin,
                onMaxChanged: viewModel.setTdsMax,
                divisions: 36,
              ),
              
              const Divider(height: 32),
              
              _buildRangeSection(
                title: 'Humidity (%)',
                icon: Icons.water_outlined,
                min: 0.0,
                max: 100.0,
                currentMin: viewModel.humidityMin,
                currentMax: viewModel.humidityMax,
                onMinChanged: viewModel.setHumidityMin,
                onMaxChanged: viewModel.setHumidityMax,
                divisions: 20,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRangeSection({
    required String title,
    required IconData icon,
    required double min,
    required double max,
    required double currentMin,
    required double currentMax,
    required ValueChanged<double> onMinChanged,
    required ValueChanged<double> onMaxChanged,
    required int divisions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Minimum value slider
        Row(
          children: [
            const SizedBox(
              width: 80,
              child: Text('Min:', style: TextStyle(color: Colors.grey)),
            ),
            Expanded(
              child: Slider(
                value: currentMin,
                min: min,
                max: max,
                divisions: divisions,
                label: currentMin.toStringAsFixed(1),
                onChanged: onMinChanged,
              ),
            ),
            SizedBox(
              width: 60,
              child: Text(
                currentMin.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        
        // Maximum value slider
        Row(
          children: [
            const SizedBox(
              width: 80,
              child: Text('Max:', style: TextStyle(color: Colors.grey)),
            ),
            Expanded(
              child: Slider(
                value: currentMax,
                min: min,
                max: max,
                divisions: divisions,
                label: currentMax.toStringAsFixed(1),
                onChanged: onMaxChanged,
              ),
            ),
            SizedBox(
              width: 60,
              child: Text(
                currentMax.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        
        // Range display
        Padding(
          padding: const EdgeInsets.only(left: 80, top: 4),
          child: Text(
            'Range: ${currentMin.toStringAsFixed(1)} - ${currentMax.toStringAsFixed(1)}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
