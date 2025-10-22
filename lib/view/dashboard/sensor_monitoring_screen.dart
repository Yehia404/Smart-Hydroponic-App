import 'package:flutter/material.dart';

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
              // TODO: Implement data refresh logic later
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'No sensor data available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}
