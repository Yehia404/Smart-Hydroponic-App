import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/sensor_thresholds_viewmodel.dart';

class SensorThresholdsScreen extends StatelessWidget {
  const SensorThresholdsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<SensorThresholdsViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Sensor Thresholds')),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildThresholdCard(
                  context,
                  'Temperature (°C)',
                  Icons.thermostat,
                  Colors.orange,
                  [
                    _buildSlider(
                      context,
                      viewModel,
                      'Min Temp',
                      'temperature',
                      'min',
                      viewModel.minTemp,
                      0,
                      50,
                    ),
                    _buildSlider(
                      context,
                      viewModel,
                      'Max Temp',
                      'temperature',
                      'max',
                      viewModel.maxTemp,
                      0,
                      50,
                    ),
                  ],
                ),
                _buildThresholdCard(
                  context,
                  'Water Level (%)',
                  Icons.water_drop,
                  Colors.blue,
                  [
                    _buildSlider(
                      context,
                      viewModel,
                      'Min Level',
                      'water_level',
                      'min',
                      viewModel.minWaterLevel,
                      0,
                      100,
                    ),
                  ],
                ),
                _buildThresholdCard(
                  context,
                  'pH Level',
                  Icons.science,
                  Colors.purple,
                  [
                    _buildSlider(
                      context,
                      viewModel,
                      'Min pH',
                      'ph',
                      'min',
                      viewModel.minPh,
                      0,
                      14,
                    ),
                    _buildSlider(
                      context,
                      viewModel,
                      'Max pH',
                      'ph',
                      'max',
                      viewModel.maxPh,
                      0,
                      14,
                    ),
                  ],
                ),
                _buildThresholdCard(
                  context,
                  'TDS (ppm)',
                  Icons.opacity,
                  Colors.brown,
                  [
                    _buildSlider(
                      context,
                      viewModel,
                      'Min TDS',
                      'tds',
                      'min',
                      viewModel.minTds,
                      0,
                      2000,
                    ),
                    _buildSlider(
                      context,
                      viewModel,
                      'Max TDS',
                      'tds',
                      'max',
                      viewModel.maxTds,
                      0,
                      2000,
                    ),
                  ],
                ),
                _buildThresholdCard(
                  context,
                  'Light Intensity (%)',
                  Icons.lightbulb,
                  Colors.yellow[700]!,
                  [
                    _buildSlider(
                      context,
                      viewModel,
                      'Min Light',
                      'light_intensity',
                      'min',
                      viewModel.minLight,
                      0,
                      100,
                    ),
                  ],
                ),
                _buildThresholdCard(
                  context,
                  'Humidity (%)',
                  Icons.cloud,
                  Colors.cyan,
                  [
                    _buildSlider(
                      context,
                      viewModel,
                      'Min Humidity',
                      'humidity',
                      'min',
                      viewModel.minHumidity,
                      0,
                      100,
                    ),
                    _buildSlider(
                      context,
                      viewModel,
                      'Max Humidity',
                      'humidity',
                      'max',
                      viewModel.maxHumidity,
                      0,
                      100,
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildThresholdCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
    BuildContext context,
    SensorThresholdsViewModel viewModel,
    String label,
    String sensor,
    String type,
    double value,
    double min,
    double max,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              value.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          label: value.toStringAsFixed(1),
          onChanged: (newValue) =>
              viewModel.saveThreshold(sensor, type, newValue),
        ),
      ],
    );
  }
}
