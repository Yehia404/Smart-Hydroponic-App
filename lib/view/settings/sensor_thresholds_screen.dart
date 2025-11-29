import 'package:flutter/material.dart';

class SensorThresholdsScreen extends StatefulWidget {
  const SensorThresholdsScreen({super.key});

  @override
  State<SensorThresholdsScreen> createState() => _SensorThresholdsScreenState();
}

class _SensorThresholdsScreenState extends State<SensorThresholdsScreen> {
  bool isLoading = false;
  double minTemp = 18.0;
  double maxTemp = 30.0;
  double minWaterLevel = 20.0;
  double minPh = 5.5;
  double maxPh = 7.5;
  double minTds = 500.0;
  double maxTds = 1500.0;
  double minLight = 30.0;
  double minHumidity = 40.0;
  double maxHumidity = 80.0;

  void saveThreshold(String sensor, String type, double value) {
    setState(() {
      switch ('${sensor}_$type') {
        case 'temperature_min':
          minTemp = value;
          break;
        case 'temperature_max':
          maxTemp = value;
          break;
        case 'water_level_min':
          minWaterLevel = value;
          break;
        case 'ph_min':
          minPh = value;
          break;
        case 'ph_max':
          maxPh = value;
          break;
        case 'tds_min':
          minTds = value;
          break;
        case 'tds_max':
          maxTds = value;
          break;
        case 'light_intensity_min':
          minLight = value;
          break;
        case 'humidity_min':
          minHumidity = value;
          break;
        case 'humidity_max':
          maxHumidity = value;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sensor Thresholds')),
      body: isLoading
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
                      'Min Temp',
                      'temperature',
                      'min',
                      minTemp,
                      0,
                      50,
                    ),
                    _buildSlider(
                      context,
                      'Max Temp',
                      'temperature',
                      'max',
                      maxTemp,
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
                      'Min Level',
                      'water_level',
                      'min',
                      minWaterLevel,
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
                    _buildSlider(context, 'Min pH', 'ph', 'min', minPh, 0, 14),
                    _buildSlider(context, 'Max pH', 'ph', 'max', maxPh, 0, 14),
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
                      'Min TDS',
                      'tds',
                      'min',
                      minTds,
                      0,
                      2000,
                    ),
                    _buildSlider(
                      context,
                      'Max TDS',
                      'tds',
                      'max',
                      maxTds,
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
                      'Min Light',
                      'light_intensity',
                      'min',
                      minLight,
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
                      'Min Humidity',
                      'humidity',
                      'min',
                      minHumidity,
                      0,
                      100,
                    ),
                    _buildSlider(
                      context,
                      'Max Humidity',
                      'humidity',
                      'max',
                      maxHumidity,
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
          onChanged: (newValue) => saveThreshold(sensor, type, newValue),
        ),
      ],
    );
  }
}
