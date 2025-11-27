import 'package:flutter/material.dart';
import '../../data/models/sensor_data.dart';

class SensorMonitoringScreen extends StatelessWidget {
  const SensorMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Monitoring'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: () {
              // TODO: Implement refresh logic
            },
          ),
        ],
      ),
      body: const SensorMonitoringBody(),
    );
  }
}

// ✅ This is the reusable part
class SensorMonitoringBody extends StatelessWidget {
  const SensorMonitoringBody({super.key});

  @override
  Widget build(BuildContext context) {
    final List<SensorData> mockSensors = [
      SensorData(name: 'Temperature', value: '24.5', unit: '°C', icon: Icons.thermostat, color: Colors.orange),
      SensorData(name: 'Water pH', value: '6.8', unit: '', icon: Icons.science_outlined, color: Colors.blue),
      SensorData(name: 'Water Level', value: '85', unit: '%', icon: Icons.water_drop, color: Colors.lightBlue),
      SensorData(name: 'Light Intensity', value: '75', unit: '%', icon: Icons.lightbulb_outline, color: Colors.yellow),
      SensorData(name: 'Nutrient TDS', value: '1100', unit: 'ppm', icon: Icons.opacity, color: Colors.purple),
      SensorData(name: 'Humidity', value: '60', unit: '%', icon: Icons.grain, color: Colors.cyan),
    ];

    return ListView.builder(
      itemCount: mockSensors.length,
      itemBuilder: (context, index) {
        final sensor = mockSensors[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(sensor.icon, color: sensor.color, size: 40),
            title: Text(sensor.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Row(
              children: [
                const Expanded(child: Text('Status: Normal')),
                TextButton(onPressed: () {}, child: const Text('Calibrate')),
              ],
            ),
            trailing: Text(
              '${sensor.value} ${sensor.unit}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}
