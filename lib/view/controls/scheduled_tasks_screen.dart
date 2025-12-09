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
