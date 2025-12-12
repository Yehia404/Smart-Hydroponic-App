import 'package:flutter/material.dart';
import '../data/services/sqlite_service.dart';
import '../data/models/alert.dart' as db;
import 'dart:async';
// UI Model for display
class AlertUI {
  final int? id;
  final String title;
  final String subtitle;
  final String severity;
  final IconData icon;
  final Color color;
  final DateTime timestamp;
  final bool isDismissed;

  AlertUI({
    this.id,
    required this.title,
    required this.subtitle,
    required this.severity,
    required this.icon,
    required this.color,
    required this.timestamp,
    this.isDismissed = false,
  });
}

class AlertsNotificationsViewModel extends ChangeNotifier {
  int _selectedFilterIndex = 0;
  List<AlertUI> _alerts = [];
  List<AlertUI> _allAlerts = [];
  List<AlertUI> _historyAlerts = [];
  bool _isLoading = true;
  bool _showHistory = false;
  int _criticalCount = 0;
  int _warningCount = 0;
  int _infoCount = 0;

  int get selectedFilterIndex => _selectedFilterIndex;
  List<AlertUI> get alerts => _showHistory ? _historyAlerts : _alerts;
  bool get isLoading => _isLoading;
  bool get showHistory => _showHistory;
  int get criticalCount => _criticalCount;
  int get warningCount => _warningCount;
  int get infoCount => _infoCount;
  int get totalActiveCount => _alerts.length;
  StreamSubscription? _dbSubscription;
  AlertsNotificationsViewModel() {
    loadAlerts();
    _listenToDatabase();
  }
  void _listenToDatabase() {
    // Whenever the DB says "I changed", reload the alerts automatically
    _dbSubscription = SqliteService.instance.onAlertsChanged.listen((_) {
      loadAlerts();
    });
  }
  @override
  void dispose() {
    // Essential: Turn off the radio when this ViewModel dies to prevent memory leaks
    _dbSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadAlerts() async {
    _isLoading = true;
    notifyListeners();

    // FETCH ONLY ACTIVE ALERTS
    List<db.Alert> dbAlerts = await SqliteService.instance.getActiveAlerts();

    _allAlerts = dbAlerts.map((dbAlert) {
      return AlertUI(
        id: dbAlert.id,
        title: dbAlert.sensorName,
        subtitle: dbAlert.message,
        severity: dbAlert.severity,
        icon: _getIconForSeverity(dbAlert.severity),
        color: _getColorForSeverity(dbAlert.severity),
        timestamp: dbAlert.timestamp,
        isDismissed: dbAlert.isDismissed,
      );
    }).toList();

    // Apply filter
    _applyFilter();
    _updateCounts();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();

    // Fetch all alerts including dismissed ones
    List<db.Alert> dbAlerts = await SqliteService.instance.getAlertHistory();

    _historyAlerts = dbAlerts.map((dbAlert) {
      return AlertUI(
        id: dbAlert.id,
        title: dbAlert.sensorName,
        subtitle: dbAlert.message,
        severity: dbAlert.severity,
        icon: _getIconForSeverity(dbAlert.severity),
        color: _getColorForSeverity(dbAlert.severity),
        timestamp: dbAlert.timestamp,
        isDismissed: dbAlert.isDismissed,
      );
    }).toList();

    _isLoading = false;
    notifyListeners();
  }

  void _applyFilter() {
    switch (_selectedFilterIndex) {
      case 0: // All
        _alerts = List.from(_allAlerts);
        break;
      case 1: // Critical
        _alerts = _allAlerts.where((alert) => alert.severity == 'critical').toList();
        break;
      case 2: // Warning
        _alerts = _allAlerts.where((alert) => alert.severity == 'warning').toList();
        break;
      case 3: // Info
        _alerts = _allAlerts.where((alert) => alert.severity == 'info').toList();
        break;
    }
  }

  void _updateCounts() {
    _criticalCount = _allAlerts.where((alert) => alert.severity == 'critical').length;
    _warningCount = _allAlerts.where((alert) => alert.severity == 'warning').length;
    _infoCount = _allAlerts.where((alert) => alert.severity == 'info').length;
  }

  // Logic to Dismiss (Soft Delete)
  Future<void> dismissAlert(int index) async {
    if (index >= 0 && index < _alerts.length) {
      final alertToDismiss = _alerts[index];

      // 1. Remove from UI list immediately for responsiveness
      _alerts.removeAt(index);
      notifyListeners();

      // 2. Update Database (Mark as dismissed)
      if (alertToDismiss.id != null) {
        await SqliteService.instance.dismissAlert(alertToDismiss.id!);
      }
    }
  }

  void setFilter(int index) {
    _selectedFilterIndex = index;
    _applyFilter();
    notifyListeners();
  }

  void toggleHistory() {
    _showHistory = !_showHistory;
    if (_showHistory && _historyAlerts.isEmpty) {
      loadHistory();
    } else {
      notifyListeners();
    }
  }

  Future<void> acknowledgeAlert(int index) async {
    if (_showHistory) return; // Can't acknowledge history items
    
    if (index >= 0 && index < _alerts.length) {
      final alertToAck = _alerts[index];

      // 1. Remove from UI list immediately
      _alerts.removeAt(index);
      _allAlerts.removeWhere((a) => a.id == alertToAck.id);
      _updateCounts();
      notifyListeners();

      // 2. Mark as dismissed in database
      if (alertToAck.id != null) {
        await SqliteService.instance.dismissAlert(alertToAck.id!);
      }
    }
  }

  Future<void> acknowledgeAllAlerts() async {
    if (_showHistory) return;
    
    // Dismiss all visible alerts based on current filter
    for (var alert in List.from(_alerts)) {
      if (alert.id != null) {
        await SqliteService.instance.dismissAlert(alert.id!);
      }
    }
    
    // Clear the lists
    _alerts.clear();
    _allAlerts.clear();
    _updateCounts();
    notifyListeners();
  }

  String formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    
    return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }

  IconData _getIconForSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Icons.error;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'info':
        return Icons.info_outline;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}