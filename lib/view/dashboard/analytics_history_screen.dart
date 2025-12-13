import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

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
  bool _isLoading = false;
  String _selectedSensor = 'temperature';
  TimeRange _selectedRange = TimeRange.day;

  List<SensorData> _getDummyData() {
    final now = DateTime.now();
    return List.generate(20, (index) {
      return SensorData(
        now.subtract(Duration(hours: 20 - index)),
        20 + (index * 0.5) + (index % 3),
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
    await Future.delayed(const Duration(seconds: 1));
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
                _buildMainChart(),
                const SizedBox(height: 30),
                _buildStatisticsCards(),
                const SizedBox(height: 30),
                _buildTrendAnalysis(),
                const SizedBox(height: 30),
                _buildHistoricalDataTable(), // Added the new table here
              ],
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

  Widget _buildStatisticsCards() {
    final stats = _getDummyStats();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistics',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildStatCard('Current', stats.current, stats.unit, Colors.blue)),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard('Average', stats.avg, stats.unit, Colors.green)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildStatCard('Min', stats.min, stats.unit, Colors.cyan)),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard('Max', stats.max, stats.unit, Colors.orange)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, double value, String unit, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${value.toStringAsFixed(2)} $unit',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendAnalysis() {
    final stats = _getDummyStats();

    final trendDirection = stats.trend > 0 ? 'increasing' : stats.trend < 0 ? 'decreasing' : 'stable';
    final trendIcon = stats.trend > 0 ? Icons.trending_up : stats.trend < 0 ? Icons.trending_down : Icons.trending_flat;
    final trendColor = stats.trend > 0 ? Colors.red : stats.trend < 0 ? Colors.blue : Colors.grey;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trend Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(trendIcon, color: trendColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trend is $trendDirection',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: trendColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${stats.trend > 0 ? '+' : ''}${stats.trend.toStringAsFixed(2)} ${stats.unit} from average',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildTrendInsight(_selectedSensor, stats),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendInsight(String sensor, SensorStats stats) {
    String insight = '';
    IconData icon = Icons.info_outline;
    Color color = Colors.blue;

    switch (sensor) {
      case 'temperature':
        if (stats.current > 30) {
          insight = 'Temperature is high. Consider increasing ventilation.';
          icon = Icons.warning;
          color = Colors.orange;
        } else if (stats.current < 18) {
          insight = 'Temperature is low. Check heating system.';
          icon = Icons.warning;
          color = Colors.blue;
        } else {
          insight = 'Temperature is within optimal range (18-30°C).';
          icon = Icons.check_circle;
          color = Colors.green;
        }
        break;
      case 'ph':
        if (stats.current < 5.5 || stats.current > 6.5) {
          insight = 'pH is outside optimal range (5.5-6.5). Adjust nutrient solution.';
          icon = Icons.warning;
          color = Colors.orange;
        } else {
          insight = 'pH level is optimal for hydroponic growth.';
          icon = Icons.check_circle;
          color = Colors.green;
        }
        break;
      case 'water_level':
        if (stats.current < 30) {
          insight = 'Water level is low. Refill reservoir soon.';
          icon = Icons.warning;
          color = Colors.red;
        } else {
          insight = 'Water level is adequate.';
          icon = Icons.check_circle;
          color = Colors.green;
        }
        break;
      case 'light_intensity':
        if (stats.current < 50) {
          insight = 'Light intensity is low. Plants may need more light.';
          icon = Icons.info;
          color = Colors.orange;
        } else {
          insight = 'Light intensity is sufficient for plant growth.';
          icon = Icons.check_circle;
          color = Colors.green;
        }
        break;
      case 'tds':
        if (stats.current < 800 || stats.current > 1500) {
          insight = 'TDS is outside optimal range (800-1500 ppm).';
          icon = Icons.warning;
          color = Colors.orange;
        } else {
          insight = 'Nutrient concentration is optimal.';
          icon = Icons.check_circle;
          color = Colors.green;
        }
        break;
      case 'humidity':
        if (stats.current > 70) {
          insight = 'High humidity. Risk of mold. Increase ventilation.';
          icon = Icons.warning;
          color = Colors.orange;
        } else if (stats.current < 40) {
          insight = 'Low humidity. Plants may need more moisture.';
          icon = Icons.info;
          color = Colors.blue;
        } else {
          insight = 'Humidity level is optimal (40-70%).';
          icon = Icons.check_circle;
          color = Colors.green;
        }
        break;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            insight,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  // --- NEW CODE ADDED FOR COMMIT 1 ---

  Widget _buildHistoricalDataTable() {
    // USING LOCAL VARIABLES FOR NOW (INCREMENTAL COMMIT)
    final data = _getDummyData(); 
    final sensorInfo = _getSensorInfo(_selectedSensor);
    
    if (data.isEmpty) return const SizedBox.shrink();

    // Show last 10 data points
    final recentData = data.reversed.take(10).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Historical Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(color: Colors.grey[300]!),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[200]),
                  children: [
                    _buildTableCell('Timestamp', isHeader: true),
                    _buildTableCell('Value', isHeader: true),
                  ],
                ),
                ...recentData.map((point) {
                  return TableRow(
                    children: [
                      _buildTableCell(DateFormat('MMM d, HH:mm:ss').format(point.timestamp)),
                      _buildTableCell('${point.value.toStringAsFixed(2)} ${sensorInfo['unit']}'),
                    ],
                  );
                }),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Showing last 10 of ${data.length} data points',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 14 : 13,
        ),
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