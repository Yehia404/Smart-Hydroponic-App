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

  
  void _showTaskDetails(
    BuildContext context,
    ScheduledTasksViewModel viewModel,
    ScheduledTask task,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              viewModel.getActuatorIcon(task.actuatorId),
              color: viewModel.getActuatorColor(task.actuatorId),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(viewModel.getActuatorDisplayName(task.actuatorId)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Icon(
                task.action ? Icons.power_settings_new : Icons.power_off,
                color: task.action ? Colors.green : Colors.red,
              ),
              title: Text(
                'Action: Turn ${task.action ? "ON" : "OFF"}',
                style: TextStyle(
                  color: task.action ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.access_time, color: Colors.blue),
              title: Text('Time: ${_formatTime(task.time)}'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              if (task.id != null) {
                _showDeleteConfirmation(context, viewModel, task);
              }
            },
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, ScheduledTasksViewModel viewModel) {
    String selectedActuator = 'pump';
    bool selectedAction = true;
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Scheduled Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Actuator Selection
                DropdownButtonFormField<String>(
                  value: selectedActuator,
                  decoration: const InputDecoration(
                    labelText: 'Actuator',
                    prefixIcon: Icon(Icons.devices),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'pump', child: Text('Water Pump')),
                    DropdownMenuItem(value: 'lights', child: Text('Grow Lights')),
                    DropdownMenuItem(value: 'fans', child: Text('Ventilation Fans')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedActuator = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Action Selection
                DropdownButtonFormField<bool>(
                  value: selectedAction,
                  decoration: const InputDecoration(
                    labelText: 'Action',
                    prefixIcon: Icon(Icons.power_settings_new),
                  ),
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Turn ON')),
                    DropdownMenuItem(value: false, child: Text('Turn OFF')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedAction = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Time Selection
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Time'),
                  subtitle: Text(_formatTime(selectedTime)),
                  trailing: const Icon(Icons.edit),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setState(() => selectedTime = time);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final task = ScheduledTask(
                  actuatorId: selectedActuator,
                  action: selectedAction,
                  time: selectedTime,
                );

                try {
                  await viewModel.addTask(task);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Task created successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error creating task: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Add Task'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    ScheduledTasksViewModel viewModel,
    ScheduledTask task,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task?'),
        content: Text(
          'Are you sure you want to delete this scheduled task for ${viewModel.getActuatorDisplayName(task.actuatorId)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (task.id != null) {
                try {
                  await viewModel.deleteTask(task.id!);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Task deleted'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting task: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }


 String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  bool _isTaskUpcoming(TimeOfDay taskTime) {
    final now = TimeOfDay.now();
    final nowInMinutes = now.hour * 60 + now.minute;
    final taskInMinutes = taskTime.hour * 60 + taskTime.minute;
    
    // Check if task is within the next 30 minutes
    final diff = taskInMinutes - nowInMinutes;
    return diff > 0 && diff <= 30;
  }

  void _testTask(BuildContext context, ScheduledTask task) async {
    try {
      await TaskSchedulerService.instance.executeTaskNow(task);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Task executed: ${task.actuatorId.toUpperCase()} turned ${task.action ? "ON" : "OFF"}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error executing task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

