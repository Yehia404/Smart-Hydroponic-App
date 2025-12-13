import 'package:flutter/material.dart';
import '../data/services/sqlite_service.dart';
import '../data/models/scheduled_task.dart';

class ScheduledTasksViewModel extends ChangeNotifier {
  List<ScheduledTask> _tasks = [];
  bool _isLoading = true;

  List<ScheduledTask> get tasks => _tasks;
  bool get isLoading => _isLoading;

  ScheduledTasksViewModel() {
    loadTasks();
  }

  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      _tasks = await SqliteService.instance.getTasks();
      print('✅ Loaded ${_tasks.length} scheduled tasks');
    } catch (e) {
      print('❌ Error loading tasks: $e');
      _tasks = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTask(ScheduledTask task) async {
    try {
      final id = await SqliteService.instance.logTask(task);
      print('✅ Task created with ID: $id');
      await loadTasks(); // Reload to get the new task with ID
    } catch (e) {
      print('❌ Error adding task: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await SqliteService.instance.deleteTask(id);
      print('✅ Task deleted: $id');
      _tasks.removeWhere((task) => task.id == id);
      notifyListeners();
    } catch (e) {
      print('❌ Error deleting task: $e');
      rethrow;
    }
  }

  String getActuatorDisplayName(String actuatorId) {
    switch (actuatorId) {
      case 'pump':
        return 'Water Pump';
      case 'lights':
        return 'Grow Lights';
      case 'fans':
        return 'Ventilation Fans';
      default:
        return actuatorId;
    }
  }

  IconData getActuatorIcon(String actuatorId) {
    switch (actuatorId) {
      case 'pump':
        return Icons.water_drop;
      case 'lights':
        return Icons.lightbulb;
      case 'fans':
        return Icons.air;
      default:
        return Icons.settings;
    }
  }

  Color getActuatorColor(String actuatorId) {
    switch (actuatorId) {
      case 'pump':
        return Colors.blue;
      case 'lights':
        return Colors.yellow;
      case 'fans':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }
}
