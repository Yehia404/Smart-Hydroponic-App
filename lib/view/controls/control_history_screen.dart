import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/control_history_viewmodel.dart';
import '../../data/models/control_log.dart';

/// Screen displaying the history of actuator control actions
class ControlHistoryScreen extends StatelessWidget {
  const ControlHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ControlHistoryViewModel(),
      child: Consumer<ControlHistoryViewModel>(
        builder: (context, viewModel, _) {
          return _buildContent(context, viewModel);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ControlHistoryViewModel viewModel,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control History Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => viewModel.reloadLogs(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          _buildFilterChips(viewModel),
          const Divider(height: 1),

          // Logs list
          Expanded(
            child: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : viewModel.logs.isEmpty
                ? _buildEmptyState(context)
                : RefreshIndicator(
                    onRefresh: () => viewModel.reloadLogs(),
                    child: ListView.builder(
                      itemCount: viewModel.logs.length,
                      padding: const EdgeInsets.all(12),
                      itemBuilder: (context, index) {
                        final log = viewModel.logs[index];
                        return _buildLogCard(context, viewModel, log);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ControlHistoryViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: 'All',
              value: 'all',
              icon: Icons.filter_list,
              viewModel: viewModel,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Water Pump',
              value: 'pump',
              icon: Icons.water_damage_outlined,
              viewModel: viewModel,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Grow Lights',
              value: 'lights',
              icon: Icons.lightbulb_outline_rounded,
              viewModel: viewModel,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Cooling Fans',
              value: 'fans',
              icon: Icons.air_rounded,
              viewModel: viewModel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required IconData icon,
    required ControlHistoryViewModel viewModel,
  }) {
    final isSelected = viewModel.selectedFilter == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 18), const SizedBox(width: 4), Text(label)],
      ),
      selected: isSelected,
      onSelected: (_) => viewModel.setFilter(value),
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Control History',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Control actions will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(
    BuildContext context,
    ControlHistoryViewModel viewModel,
    ControlLog log,
  ) {
    final actuatorColor = viewModel.getActuatorColor(log.actuatorId);
    final actuatorIcon = viewModel.getActuatorIcon(log.actuatorId);
    final actionColor = viewModel.getActionColor(log.action);
    final actionIcon = viewModel.getActionIcon(log.action);
    final sourceColor = viewModel.getSourceColor(log.source);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: actuatorColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(actuatorIcon, color: actuatorColor, size: 28),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                log.actuatorDisplayName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            // Source badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: sourceColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: sourceColor, width: 1),
              ),
              child: Text(
                log.source.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  color: sourceColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(actionIcon, size: 16, color: actionColor),
                const SizedBox(width: 4),
                Text(
                  'Turned ${log.actionText}',
                  style: TextStyle(
                    color: actionColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  _formatTimestamp(log.timestamp),
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      // Format as date and time
      return DateFormat('MMM d, h:mm a').format(timestamp);
    }
  }
}
