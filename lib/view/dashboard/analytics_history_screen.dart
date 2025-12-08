import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

//Dummy Models 
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
  final double trend;
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
                _buildTimeRangeSelector(),
                const SizedBox(height: 20),
                _buildSensorSelector(),
                const SizedBox(height: 20),
                
                // Chart Visualization ---
                _buildMainChart(),
                
                const SizedBox(height: 30),
                
              ],
            ),
    );
  }


  Widget _buildMainChart() {
    final data = _getDummyData();
    final sensorInfo = _getSensorInfo(_selectedSensor);
    
    if (data.isEmpty) {
      return Card(
        child: Container(
          height: 300,
          alignment: Alignment.center,
          child: const Text('No data available'),
        ),
      );
    }

    final spots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(sensorInfo['icon'] as IconData, color: sensorInfo['color'] as Color),
                const SizedBox(width: 8),
                Text(
                  sensorInfo['name'] as String,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 1,
                    verticalInterval: 1,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: (spots.length / 5).ceilToDouble(),
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= data.length) return const Text('');
                          final timestamp = data[value.toInt()].timestamp;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('HH:mm').format(timestamp),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: sensorInfo['color'] as Color,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: spots.length < 50),
                      belowBarData: BarAreaData(
                        show: true,
                        color: (sensorInfo['color'] as Color).withOpacity(0.2),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final timestamp = data[spot.x.toInt()].timestamp;
                          return LineTooltipItem(
                            '${DateFormat('MMM d, HH:mm').format(timestamp)}\n${spot.y.toStringAsFixed(2)} ${sensorInfo['unit']}',
                            const TextStyle(color: Colors.white),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildTimeRangeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTimeRangeChip('1H', TimeRange.hour),
            _buildTimeRangeChip('24H', TimeRange.day),
            _buildTimeRangeChip('7D', TimeRange.week),
            _buildTimeRangeChip('30D', TimeRange.month),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeChip(String label, TimeRange range) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedRange == range,
      onSelected: (selected) {
        if (selected) setState(() => _selectedRange = range);
      },
    );
  }

  Widget _buildSensorSelector() {
    final sensors = [
      {'id': 'temperature', 'name': 'Temperature', 'icon': Icons.thermostat, 'color': Colors.orange},
      {'id': 'ph', 'name': 'pH Level', 'icon': Icons.science_outlined, 'color': Colors.blue},
      {'id': 'water_level', 'name': 'Water Level', 'icon': Icons.water_drop, 'color': Colors.lightBlue},
      {'id': 'light_intensity', 'name': 'Light', 'icon': Icons.lightbulb_outline, 'color': Colors.yellow.shade700},
      {'id': 'tds', 'name': 'TDS', 'icon': Icons.opacity, 'color': Colors.purple},
      {'id': 'humidity', 'name': 'Humidity', 'icon': Icons.grain, 'color': Colors.cyan},
    ];

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: sensors.length,
        itemBuilder: (context, index) {
          final sensor = sensors[index];
          final isSelected = _selectedSensor == sensor['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              avatar: Icon(sensor['icon'] as IconData, size: 18),
              label: Text(sensor['name'] as String),
              selected: isSelected,
              selectedColor: (sensor['color'] as Color).withOpacity(0.3),
              onSelected: (selected) {
                if (selected) setState(() => _selectedSensor = sensor['id'] as String);
              },
            ),
          );
        },
      ),
    );
  }

  
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