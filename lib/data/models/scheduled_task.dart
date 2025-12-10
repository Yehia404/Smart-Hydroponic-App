import 'package:flutter/material.dart';
class ScheduledTask {
  final int? id;
  final String actuatorId; // e.g., 'pump' or 'lights'
  final bool action; // true for ON, false for OFF
  final TimeOfDay time;

  ScheduledTask({
    this.id,
    required this.actuatorId,
    required this.action,
    required this.time,
  });
  // Convert to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'actuatorId': actuatorId,
      'action': action ? 1 : 0, // Store bool as 0 or 1
      // Convert TimeOfDay to a simple "HH:mm" string
      'time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
    };
  }
  // Create from Map from SQLite
  factory ScheduledTask.fromMap(Map<String, dynamic> map) {
    final timeParts = map['time'].split(':');
    return ScheduledTask(
      id: map['id'],
      actuatorId: map['actuatorId'],
      action: map['action'] == 1,
      time: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
    );
  }
}