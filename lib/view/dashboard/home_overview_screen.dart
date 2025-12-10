import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/home_overview_viewmodel.dart';

class HomeOverviewScreen extends StatelessWidget {
  const HomeOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<HomeOverviewViewModel>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // System Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'System Status',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: viewModel.isSystemOnline ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          viewModel.isSystemOnline ? 'ONLINE' : 'OFFLINE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Current Mode:', style: TextStyle(fontSize: 16)),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'manual', label: Text('Manual')),
                          ButtonSegment(value: 'automatic', label: Text('Auto')),
                        ],
                        selected: {viewModel.currentMode},
                        onSelectionChanged: (Set<String> newSelection) {
                          viewModel.setMode(newSelection.first);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Real-time Sensor Data Summary
          const Text(
            'Real-Time Sensor Data',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.3,
            children: viewModel.sensorSummary.map((sensor) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(sensor['icon'] as IconData, size: 32, color: sensor['color'] as Color),
                      const SizedBox(height: 8),
                      Text(
                        sensor['name'] as String,
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${sensor['value']} ${sensor['unit']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Critical Control Buttons
          const Text(
            'Critical Controls',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 10),

            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (){},
              icon: const Icon(Icons.warning),
              label: const Text('EMERGENCY STOP'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
