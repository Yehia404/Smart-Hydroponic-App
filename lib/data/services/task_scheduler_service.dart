import 'dart:async';
import 'package:flutter/material.dart';
import 'sqlite_service.dart';
import 'firestore_service.dart';
import '../models/scheduled_task.dart';

class TaskSchedulerService {
  static final TaskSchedulerService instance = TaskSchedulerService._internal();
  TaskSchedulerService._internal();

  Timer? _checkTimer;
  final Set<String> _executedToday = {};

  void start() {
    // Check every minute for tasks that need to run
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkAndExecuteTasks(),
    );

    // Also check immediately on start
    _checkAndExecuteTasks();

    print('📅 Task Scheduler Service started');
  }

  void stop() {
    _checkTimer?.cancel();
    print('📅 Task Scheduler Service stopped');
  }

  Future<void> _checkAndExecuteTasks() async {
    final now = TimeOfDay.now();

    // Reset executed tasks at midnight
    if (now.hour == 0 && now.minute == 0) {
      _executedToday.clear();
      print('🔄 Daily task execution reset');
    }

    try {
      // Get all scheduled tasks from database
      final tasks = await SqliteService.instance.getTasks();

      for (var task in tasks) {
        final taskTimeKey =
            '${task.time.hour}:${task.time.minute}-${task.actuatorId}-${task.action}';

        // Check if task should run now and hasn't been executed yet today
        if (task.time.hour == now.hour &&
            task.time.minute == now.minute &&
            !_executedToday.contains(taskTimeKey)) {
          await _executeTask(task);
          _executedToday.add(taskTimeKey);
        }
      }
    } catch (e) {
      print('❌ Error checking scheduled tasks: $e');
    }
  }

  Future<void> _executeTask(ScheduledTask task) async {
    try {
      print(
        '⏰ Executing scheduled task: ${task.actuatorId} -> ${task.action ? "ON" : "OFF"}',
      );

      // Send command to Firestore
      await FirestoreService.instance.updateActuator(
        task.actuatorId,
        task.action,
      );

      // Log the scheduled action to control history
      await FirestoreService.instance.logControlAction(
        task.actuatorId,
        task.action,
        source: 'scheduled',
      );

      print('✅ Task executed successfully: ${task.actuatorId}');
    } catch (e) {
      print('❌ Error executing task: $e');
    }
  }

  // Manual execution for testing
  Future<void> executeTaskNow(ScheduledTask task) async {
    await _executeTask(task);
  }
}
