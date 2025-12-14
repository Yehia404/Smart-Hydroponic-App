import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/sensor_calibration_viewmodel.dart';

class SensorCalibrationScreen extends StatelessWidget {
  const SensorCalibrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Calibration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset All',
            onPressed: () {
              _showResetDialog(context);
            },
          ),
        ],
      ),
      body: Consumer<SensorCalibrationViewModel>(
        builder: (context, viewModel, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[300]),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Calibration Offsets',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Adjust these values to compensate for sensor drift or inaccuracies. The offset will be added to all sensor readings.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildCalibrationCard(
                title: 'Temperature',
                icon: Icons.thermostat_outlined,
                unit: '°C',
                currentOffset: viewModel.temperatureOffset,
                min: -10.0,
                max: 10.0,
                divisions: 200,
                onChanged: viewModel.setTemperatureOffset,
              ),

              _buildCalibrationCard(
                title: 'pH Level',
                icon: Icons.science_outlined,
                unit: 'pH',
                currentOffset: viewModel.phOffset,
                min: -3.0,
                max: 3.0,
                divisions: 60,
                onChanged: viewModel.setPhOffset,
              ),

              _buildCalibrationCard(
                title: 'Water Level',
                icon: Icons.water_drop_outlined,
                unit: '%',
                currentOffset: viewModel.waterLevelOffset,
                min: -50.0,
                max: 50.0,
                divisions: 100,
                onChanged: viewModel.setWaterLevelOffset,
              ),

              _buildCalibrationCard(
                title: 'Light Intensity',
                icon: Icons.light_mode_outlined,
                unit: '%',
                currentOffset: viewModel.lightIntensityOffset,
                min: -50.0,
                max: 50.0,
                divisions: 100,
                onChanged: viewModel.setLightIntensityOffset,
              ),

              _buildCalibrationCard(
                title: 'TDS (Total Dissolved Solids)',
                icon: Icons.opacity_outlined,
                unit: 'ppm',
                currentOffset: viewModel.tdsOffset,
                min: -500.0,
                max: 500.0,
                divisions: 100,
                onChanged: viewModel.setTdsOffset,
              ),

              _buildCalibrationCard(
                title: 'Humidity',
                icon: Icons.water_outlined,
                unit: '%',
                currentOffset: viewModel.humidityOffset,
                min: -50.0,
                max: 50.0,
                divisions: 100,
                onChanged: viewModel.setHumidityOffset,
              ),

              if (viewModel.hasActiveCalibrations)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Card(
                    color: Colors.orange[900]?.withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.orange[300]),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Active calibrations detected. All sensor readings are being adjusted.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCalibrationCard({
    required String title,
    required IconData icon,
    required String unit,
    required double currentOffset,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: currentOffset == 0.0
                        ? Colors.green[900]?.withOpacity(0.3)
                        : Colors.orange[900]?.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${currentOffset >= 0 ? '+' : ''}${currentOffset.toStringAsFixed(1)} $unit',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: currentOffset == 0.0
                          ? Colors.green[300]
                          : Colors.orange[300],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${min.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Expanded(
                  child: Slider(
                    value: currentOffset,
                    min: min,
                    max: max,
                    divisions: divisions,
                    label: '${currentOffset >= 0 ? '+' : ''}${currentOffset.toStringAsFixed(1)} $unit',
                    onChanged: onChanged,
                  ),
                ),
                Text(
                  '${max.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            if (currentOffset != 0.0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Example: 25.0$unit → ${(25.0 + currentOffset).toStringAsFixed(1)}$unit',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Calibrations'),
        content: const Text(
          'Are you sure you want to reset all sensor calibrations to zero? This will remove all offset adjustments.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<SensorCalibrationViewModel>(context, listen: false)
                  .resetAllCalibrations();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All calibrations reset to zero')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
