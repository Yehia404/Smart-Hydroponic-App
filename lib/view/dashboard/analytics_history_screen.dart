import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// --- Dummy Models ---
enum TimeRange { hour, day, week, month }

class SensorData {
  final DateTime timestamp;
  final double value;
  SensorData(this.timestamp, this.value);
}

class SensorStats {
  final double current;
  final double avg;
  final double min;
  final double max;
  final double trend; // +ve for up, -ve for down
  final String unit;

  SensorStats({
    required this.current,
    required this.avg,
    required this.min,
    required this.max,
    required this.trend,
    required this.unit,
  });
}
// ---------------------------------------------------------

class AnalyticsHistoryScreen extends StatefulWidget {
  const AnalyticsHistoryScreen({super.key});

  @override
  State<AnalyticsHistoryScreen> createState() => _AnalyticsHistoryScreenState();
}

class _AnalyticsHistoryScreenState extends State<AnalyticsHistoryScreen> {
  // Local State
  bool _isLoading = false;
  String _selectedSensor = 'temperature';
  TimeRange _selectedRange = TimeRange.day;

  // Dummy Data Generators
  List<SensorData> _getDummyData() {
    final now = DateTime.now();
    return List.generate(20, (index) {
      return SensorData(
        now.subtract(Duration(hours: 20 - index)),
        20 + (index * 0.5) + (index % 3), // Random curve
      );
    });
  }

  SensorStats _getDummyStats() {
    return SensorStats(
      current: 24.5,
      avg: 22.0,
      min: 18.0,
      max: 28.0,
      trend: 1.5,
      unit: '°C',
    );
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate network
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () {},
            tooltip: 'Export Data',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                
              ],
            ),
    );
  }

  // Helper method needed by UI components
  Map<String, dynamic> _getSensorInfo(String sensor) {
    switch (sensor) {
      case 'temperature':
        return {'name': 'Temperature', 'icon': Icons.thermostat, 'color': Colors.orange, 'unit': '°C'};
      case 'ph':
        return {'name': 'pH Level', 'icon': Icons.science_outlined, 'color': Colors.blue, 'unit': ''};
      case 'water_level':
        return {'name': 'Water Level', 'icon': Icons.water_drop, 'color': Colors.lightBlue, 'unit': '%'};
      case 'light_intensity':
        return {'name': 'Light Intensity', 'icon': Icons.lightbulb_outline, 'color': Colors.yellow.shade700, 'unit': '%'};
      case 'tds':
        return {'name': 'TDS', 'icon': Icons.opacity, 'color': Colors.purple, 'unit': 'ppm'};
      case 'humidity':
        return {'name': 'Humidity', 'icon': Icons.grain, 'color': Colors.cyan, 'unit': '%'};
      default:
        return {'name': 'Unknown', 'icon': Icons.help_outline, 'color': Colors.grey, 'unit': ''};
    }
  }
}