import 'package:flutter/material.dart';
import '../view/controls/scheduled_tasks_screen.dart';
import '../view/controls/control_history_screen.dart';

class ControlPanelViewModel extends ChangeNotifier {
  void openScheduleTasks(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScheduledTasksScreen()),
    );
  }

  void openControlHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ControlHistoryScreen()),
    );
  }
}
