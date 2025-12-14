import 'package:flutter/material.dart';
import '../../data/services/actuator_health_monitor.dart';

class ActuatorHealthViewModel extends ChangeNotifier {
  final ActuatorHealthMonitor _monitor = ActuatorHealthMonitor.instance;

  ActuatorHealthViewModel() {
    _monitor.addListener(_onHealthChanged);
  }

  void _onHealthChanged() {
    notifyListeners();
  }

  // Getters
  Map<String, ActuatorHealth> get actuatorHealth => _monitor.actuatorHealth;
  List<ActuatorFailure> get failureHistory => _monitor.failureHistory;
  int get currentFailureCount => _monitor.currentFailureCount;
  List<String> get failedActuators => _monitor.failedActuators;

  // Actions
  void resetActuatorHealth(String actuator) {
    _monitor.resetActuatorHealth(actuator);
  }

  void clearFailureHistory() {
    _monitor.clearFailureHistory();
  }

  // Get health status icon and color
  IconData getHealthIcon(String actuator) {
    final health = _monitor.actuatorHealth[actuator];
    switch (health) {
      case ActuatorHealth.healthy:
        return Icons.check_circle;
      case ActuatorHealth.failed:
        return Icons.error;
      case ActuatorHealth.unknown:
      default:
        return Icons.help;
    }
  }

  Color getHealthColor(String actuator) {
    final health = _monitor.actuatorHealth[actuator];
    switch (health) {
      case ActuatorHealth.healthy:
        return Colors.green;
      case ActuatorHealth.failed:
        return Colors.red;
      case ActuatorHealth.unknown:
      default:
        return Colors.grey;
    }
  }

  String getHealthText(String actuator) {
    final health = _monitor.actuatorHealth[actuator];
    switch (health) {
      case ActuatorHealth.healthy:
        return 'Healthy';
      case ActuatorHealth.failed:
        return 'Failed';
      case ActuatorHealth.unknown:
      default:
        return 'Unknown';
    }
  }

  @override
  void dispose() {
    _monitor.removeListener(_onHealthChanged);
    super.dispose();
  }
}
