import 'package:flutter/material.dart';
import '../data/services/settings_service.dart';

class NotificationSettingsViewModel extends ChangeNotifier {
  final SettingsService _settingsService = SettingsService.instance;
  bool _isLoading = true;

  bool _criticalEnabled = true;
  bool _warningEnabled = true;
  bool _infoEnabled = true;

  bool get isLoading => _isLoading;
  bool get criticalEnabled => _criticalEnabled;
  bool get warningEnabled => _warningEnabled;
  bool get infoEnabled => _infoEnabled;

  NotificationSettingsViewModel() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _isLoading = true;
    notifyListeners();

    _criticalEnabled = await _settingsService.getNotificationPreference('critical', defaultValue: true);
    _warningEnabled = await _settingsService.getNotificationPreference('warning', defaultValue: true);
    _infoEnabled = await _settingsService.getNotificationPreference('info', defaultValue: true);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleSetting(String key, bool value) async {
    await _settingsService.saveNotificationPreference(key, value);
    switch (key) {
      case 'critical': _criticalEnabled = value; break;
      case 'warning': _warningEnabled = value; break;
      case 'info': _infoEnabled = value; break;
    }
    notifyListeners();
  }
}
