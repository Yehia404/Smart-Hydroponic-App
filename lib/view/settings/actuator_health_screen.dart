import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/actuator_health_viewmodel.dart';
import '../../data/services/actuator_health_monitor.dart';

class ActuatorHealthScreen extends StatelessWidget {
  const ActuatorHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actuator Health Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear History',
            onPressed: () {
              _showClearHistoryDialog(context);
            },
          ),
        ],
      ),
      body: Consumer<ActuatorHealthViewModel>(
        builder: (context, viewModel, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary Card
              Card(
                color: viewModel.currentFailureCount > 0
                    ? Colors.red[900]?.withValues(alpha: 0.3)
                    : Colors.green[900]?.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            viewModel.currentFailureCount > 0
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_outline,
                            color: viewModel.currentFailureCount > 0
                                ? Colors.red[300]
                                : Colors.green[300],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'System Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: viewModel.currentFailureCount > 0
                                  ? Colors.red[300]
                                  : Colors.green[300],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        viewModel.currentFailureCount > 0
                            ? '${viewModel.currentFailureCount} actuator(s) have failed'
                            : 'All actuators operating normally',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Individual Actuator Status
              const Text(
                'Actuator Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              _buildActuatorCard(context, viewModel, 'pump', 'Water Pump', Icons.water_drop),
              _buildActuatorCard(context, viewModel, 'fans', 'Cooling Fans', Icons.air),
              _buildActuatorCard(context, viewModel, 'lights', 'Grow Lights', Icons.lightbulb),

              const SizedBox(height: 24),

              // Failure History
              if (viewModel.failureHistory.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Failure History',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${viewModel.failureHistory.length} events',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...viewModel.failureHistory.reversed.take(10).map(
                  (failure) => Card(
                    child: ListTile(
                      leading: Icon(Icons.error, color: Colors.red[300]),
                      title: Text(failure.actuatorName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(failure.reason),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy - HH:mm:ss').format(failure.detectedAt),
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  ),
                ),
              ] else
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No failure history',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActuatorCard(
    BuildContext context,
    ActuatorHealthViewModel viewModel,
    String actuatorKey,
    String actuatorName,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(actuatorName),
        subtitle: Text(viewModel.getHealthText(actuatorKey)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              viewModel.getHealthIcon(actuatorKey),
              color: viewModel.getHealthColor(actuatorKey),
            ),
            if (viewModel.actuatorHealth[actuatorKey] == ActuatorHealth.failed)
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Reset Health Status',
                onPressed: () {
                  viewModel.resetActuatorHealth(actuatorKey);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$actuatorName health status reset')),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Failure History'),
        content: const Text('Are you sure you want to clear all failure history records?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<ActuatorHealthViewModel>(context, listen: false)
                  .clearFailureHistory();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failure history cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
