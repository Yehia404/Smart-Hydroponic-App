import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/alerts_notifications_viewmodel.dart';

class AlertsNotificationsScreen extends StatelessWidget {
  const AlertsNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to the ViewModel
    final viewModel = Provider.of<AlertsNotificationsViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(viewModel.showHistory ? 'Notification History' : 'Alerts & Notifications'),
        actions: [
          // History Toggle Button
          IconButton(
            icon: Icon(viewModel.showHistory ? Icons.notifications_active : Icons.history),
            tooltip: viewModel.showHistory ? 'Active Alerts' : 'View History',
            onPressed: () => viewModel.toggleHistory(),
          ),
          // Acknowledge All Button (only for active alerts)
          if (!viewModel.showHistory && viewModel.totalActiveCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Acknowledge All',
              onPressed: () => _showAcknowledgeAllDialog(context, viewModel),
            ),
        ],
      ),

      body: Column(
        children: [
          // Stats Summary Card
          _buildStatsCard(viewModel),
          
          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'All (${viewModel.totalActiveCount})',
                    selected: viewModel.selectedFilterIndex == 0,
                    onSelected: () => viewModel.setFilter(0),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Critical (${viewModel.criticalCount})',
                    selected: viewModel.selectedFilterIndex == 1,
                    onSelected: () => viewModel.setFilter(1),
                    color: Colors.red,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Warning (${viewModel.warningCount})',
                    selected: viewModel.selectedFilterIndex == 2,
                    onSelected: () => viewModel.setFilter(2),
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Info (${viewModel.infoCount})',
                    selected: viewModel.selectedFilterIndex == 3,
                    onSelected: () => viewModel.setFilter(3),
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ),
          const Divider(),

          // MAIN CONTENT
          Expanded(
            child: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : viewModel.alerts.isEmpty
                ? _buildEmptyState(viewModel.showHistory)
                : RefreshIndicator(
                    onRefresh: () async {
                      if (viewModel.showHistory) {
                        await viewModel.loadHistory();
                      } else {
                        await viewModel.loadAlerts();
                      }
                    },
                    child: ListView.builder(
                      itemCount: viewModel.alerts.length,
                      itemBuilder: (context, index) {
                        final alert = viewModel.alerts[index];
                        return _buildAlertCard(context, viewModel, alert, index);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Stats Summary Card
  Widget _buildStatsCard(AlertsNotificationsViewModel viewModel) {
    if (viewModel.showHistory) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.error, 'Critical', viewModel.criticalCount, Colors.red),
          _buildStatItem(Icons.warning_amber_rounded, 'Warning', viewModel.warningCount, Colors.orange),
          _buildStatItem(Icons.info_outline, 'Info', viewModel.infoCount, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, int count, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  // Filter Chip
  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
    Color? color,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: (color ?? Colors.green).withOpacity(0.3),
      checkmarkColor: color ?? Colors.green,
      side: BorderSide(
        color: selected ? (color ?? Colors.green) : Colors.grey[700]!,
        width: 1.5,
      ),
    );
  }

  // Alert Card
  Widget _buildAlertCard(
    BuildContext context,
    AlertsNotificationsViewModel viewModel,
    AlertUI alert,
    int index,
  ) {
    return Dismissible(
      key: Key(alert.id?.toString() ?? index.toString()),
      direction: viewModel.showHistory ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.green,
        child: const Icon(Icons.check, color: Colors.white),
      ),
      onDismissed: (_) => viewModel.acknowledgeAlert(index),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        elevation: 2,
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: alert.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(alert.icon, color: alert.color, size: 24),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  alert.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: alert.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: alert.color, width: 1),
                ),
                child: Text(
                  alert.severity.toUpperCase(),
                  style: TextStyle(
                    color: alert.color,
                    fontSize: 10,
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
              Text(
                alert.subtitle,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 12, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    viewModel.formatTimestamp(alert.timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                  if (alert.isDismissed) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'ACKNOWLEDGED',
                        style: TextStyle(fontSize: 10, color: Colors.white70),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          trailing: viewModel.showHistory
              ? null
              : IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  color: Colors.green,
                  tooltip: 'Acknowledge',
                  onPressed: () => viewModel.acknowledgeAlert(index),
                ),
          onTap: () => _showAlertDetails(context, alert, viewModel),
        ),
      ),
    );
  }

  // Empty State
  Widget _buildEmptyState(bool isHistory) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isHistory ? Icons.history : Icons.notifications_off_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isHistory ? "No notification history" : "No active alerts",
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            isHistory
                ? "Past notifications will appear here"
                : "You're all caught up! 🎉",
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // Alert Details Dialog
  void _showAlertDetails(BuildContext context, AlertUI alert, AlertsNotificationsViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(alert.icon, color: alert.color),
            const SizedBox(width: 8),
            Expanded(child: Text(alert.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Severity: ${alert.severity.toUpperCase()}',
                style: TextStyle(color: alert.color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(alert.subtitle),
            const SizedBox(height: 12),
            Text(
              'Time: ${viewModel.formatTimestamp(alert.timestamp)}',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (!viewModel.showHistory && !alert.isDismissed)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                final index = viewModel.alerts.indexOf(alert);
                if (index >= 0) viewModel.acknowledgeAlert(index);
              },
              icon: const Icon(Icons.check),
              label: const Text('Acknowledge'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
        ],
      ),
    );
  }

  // Acknowledge All Dialog
  void _showAcknowledgeAllDialog(BuildContext context, AlertsNotificationsViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Acknowledge All Alerts?'),
        content: Text(
          'This will acknowledge ${viewModel.alerts.length} alert(s). This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.acknowledgeAllAlerts();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All alerts acknowledged'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Acknowledge All'),
          ),
        ],
      ),
    );
  }
}