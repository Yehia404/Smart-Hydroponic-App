import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/control_log.dart';
import '../data/services/firestore_service.dart';

/// ViewModel for Control History screen
/// Manages fetching and filtering of actuator control logs
class ControlHistoryViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService.instance;

  List<ControlLog> _logs = [];
  bool _isLoading = false;
  String _selectedFilter = 'all'; // 'all', 'pump', 'lights', 'fans'
  StreamSubscription? _logsSubscription;

  List<ControlLog> get logs => _logs;
  bool get isLoading => _isLoading;
  String get selectedFilter => _selectedFilter;

  ControlHistoryViewModel() {
    _listenToLogs();
  }

  /// Set up real-time listener for control logs
  void _listenToLogs() {
    _isLoading = true;
    notifyListeners();

    final actuatorFilter = _selectedFilter == 'all' ? null : _selectedFilter;

    _logsSubscription = _firestoreService
        .getControlHistoryStream(
          limitCount: 100,
          actuatorFilter: actuatorFilter,
        )
        .listen(
          (logs) {
            _logs = logs;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Error loading control logs: $error');
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  /// Change the actuator filter
  void setFilter(String filter) {
    if (_selectedFilter == filter) return;

    _selectedFilter = filter;

    // Cancel existing subscription and create new one with filter
    _logsSubscription?.cancel();
    _listenToLogs();
  }

  /// Reload logs manually
  Future<void> reloadLogs() async {
    _isLoading = true;
    notifyListeners();

    final actuatorFilter = _selectedFilter == 'all' ? null : _selectedFilter;

    _logs = await _firestoreService.fetchControlHistory(
      limitCount: 100,
      actuatorFilter: actuatorFilter,
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Get icon for actuator
  IconData getActuatorIcon(String actuatorId) {
    switch (actuatorId) {
      case 'pump':
        return Icons.water_damage_outlined;
      case 'lights':
        return Icons.lightbulb_outline_rounded;
      case 'fans':
        return Icons.air_rounded;
      default:
        return Icons.settings;
    }
  }

  /// Get color for actuator
  Color getActuatorColor(String actuatorId) {
    switch (actuatorId) {
      case 'pump':
        return Colors.blue;
      case 'lights':
        return Colors.amber;
      case 'fans':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Get icon for action
  IconData getActionIcon(bool action) {
    return action ? Icons.power_settings_new : Icons.power_off;
  }

  /// Get color for action
  Color getActionColor(bool action) {
    return action ? Colors.green : Colors.red;
  }

  /// Get badge color for source
  Color getSourceColor(String source) {
    switch (source) {
      case 'manual':
        return Colors.blue;
      case 'scheduled':
        return Colors.purple;
      case 'emergency':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _logsSubscription?.cancel();
    super.dispose();
  }
}
