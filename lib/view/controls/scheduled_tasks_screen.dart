import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/scheduled_tasks_viewmodel.dart';
import '../../data/models/scheduled_task.dart';
import '../../data/services/task_scheduler_service.dart';

class ScheduledTasksScreen extends StatelessWidget {
  const ScheduledTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScheduledTasksViewModel(),
      child: Consumer<ScheduledTasksViewModel>(
        builder: (context, viewModel, _) {
          return _buildContent(context, viewModel);
        },
      ),
    );
  }



  Widget _buildContent(BuildContext context, ScheduledTasksViewModel viewModel) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheduled Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => viewModel.loadTasks(),
          ),
        ],
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : viewModel.tasks.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: () => viewModel.loadTasks(),
                  child: ListView.builder(
                    itemCount: viewModel.tasks.length,
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (context, index) {
                      final task = viewModel.tasks[index];
                      return _buildTaskCard(context, viewModel, task);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(context, viewModel),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Scheduled Tasks',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create your first task',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    ScheduledTasksViewModel viewModel,
    ScheduledTask task,
  ) {
    final color = viewModel.getActuatorColor(task.actuatorId);
    final icon = viewModel.getActuatorIcon(task.actuatorId);
    final displayName = viewModel.getActuatorDisplayName(task.actuatorId);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          displayName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  task.action ? Icons.power_settings_new : Icons.power_off,
                  size: 16,
                  color: task.action ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  'Turn ${task.action ? "ON" : "OFF"}',
                  style: TextStyle(
                    color: task.action ? Colors.green : Colors.red,
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
                  _formatTime(task.time),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 8),
                if (_isTaskUpcoming(task.time))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange, width: 1),
                    ),
                    child: const Text(
                      'UPCOMING',
                      style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.green),
              tooltip: 'Test Now',
              onPressed: () => _testTask(context, task),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete Task',
              onPressed: () => _showDeleteConfirmation(context, viewModel, task),
            ),
          ],
        ),
        onTap: () => _showTaskDetails(context, viewModel, task),
      ),
    );
  }