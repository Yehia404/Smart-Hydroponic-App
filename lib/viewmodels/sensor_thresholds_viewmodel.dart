import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../data/services/settings_service.dart';
import '../data/services/auth_service.dart';
import '../data/models/threshold_config.dart';

class SensorThresholdsViewModel extends ChangeNotifier {
  final SettingsService _settingsService = SettingsService.instance;
  final AuthService _authService = AuthService.instance;
  StreamSubscription? _authSubscription;
  bool _isLoading = false;

  // Thresholds - Will be loaded from DB based on current user
  double _maxTemp = 30.0;
  double _minTemp = 15.0;
  double _minWaterLevel = 20.0;
  double _minPh = 5.5;
  double _maxPh = 6.5;
  double _minTds = 800.0;
  double _maxTds = 1500.0;
  double _minLight = 30.0;
  double _minHumidity = 50.0;
  double _maxHumidity = 70.0;

  bool get isLoading => _isLoading;
  double get maxTemp => _maxTemp;
  double get minTemp => _minTemp;
  double get minWaterLevel => _minWaterLevel;
  double get minPh => _minPh;
  double get maxPh => _maxPh;
  double get minTds => _minTds;
  double get maxTds => _maxTds;
  double get minLight => _minLight;
  double get minHumidity => _minHumidity;
  double get maxHumidity => _maxHumidity;

  SensorThresholdsViewModel() {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authSubscription = _authService.authStateChanges.listen((user) {
      debugPrint('🔄 THRESHOLDS: Auth state changed, user: ${user?.uid}');
      if (user != null) {
        // User logged in, reload their data
        _loadThresholds();
      } else {
        // User logged out, reset to defaults
        _resetToDefaults();
      }
    });
  }

  void _resetToDefaults() {
    // Reset to hardcoded defaults
    _maxTemp = 25.0;
    _minTemp = 15.0;
    _minWaterLevel = 70.0;
    _minPh = 5.5;
    _maxPh = 7.5;
    _minTds = 600.0;
    _maxTds = 1200.0;
    _minLight = 30.0;
    _minHumidity = 40.0;
    _maxHumidity = 80.0;
    
    // Also reset the singleton
    ThresholdConfig.instance.resetToDefaults();
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  /// Reload thresholds from database
  Future<void> reload() async {
    await _loadThresholds();
  }

  Future<void> _loadThresholds() async {
    _isLoading = true;
    notifyListeners();

    try {
      final config = ThresholdConfig.instance;
      
      // CRITICAL: Reset singleton to hardcoded defaults first
      // This prevents previous user's values from persisting
      config.resetToDefaults();
      
      debugPrint('📊 THRESHOLDS: Loading for user ${_authService.currentUser?.uid}');
      
      // Load from database - if null, use hardcoded defaults
      final maxTemp = await _settingsService.getThreshold('temperature', 'max');
      final minTemp = await _settingsService.getThreshold('temperature', 'min');
      final minWaterLevel = await _settingsService.getThreshold('water_level', 'min');
      final minPh = await _settingsService.getThreshold('ph', 'min');
      final maxPh = await _settingsService.getThreshold('ph', 'max');
      final minTds = await _settingsService.getThreshold('tds', 'min');
      final maxTds = await _settingsService.getThreshold('tds', 'max');
      final minLight = await _settingsService.getThreshold('light_intensity', 'min');
      final minHumidity = await _settingsService.getThreshold('humidity', 'min');
      final maxHumidity = await _settingsService.getThreshold('humidity', 'max');
      
      // Update local state - use DB value if exists, otherwise use hardcoded defaults
      _maxTemp = maxTemp ?? 25.0;
      _minTemp = minTemp ?? 15.0;
      _minWaterLevel = minWaterLevel ?? 70.0;
      _minPh = minPh ?? 5.5;
      _maxPh = maxPh ?? 7.5;
      _minTds = minTds ?? 600.0;
      _maxTds = maxTds ?? 1200.0;
      _minLight = minLight ?? 30.0;
      _minHumidity = minHumidity ?? 40.0;
      _maxHumidity = maxHumidity ?? 80.0;
      
      // CRITICAL: Always update the singleton with the final values
      // This ensures notifications and other services use the correct thresholds
      config.maxTemp = _maxTemp;
      config.minTemp = _minTemp;
      config.minWaterLevel = _minWaterLevel;
      config.minPh = _minPh;
      config.maxPh = _maxPh;
      config.minTds = _minTds;
      config.maxTds = _maxTds;
      config.minLight = _minLight;
      config.minHumidity = _minHumidity;
      config.maxHumidity = _maxHumidity;
      
      debugPrint('✅ THRESHOLDS: Loaded - maxTemp: $_maxTemp, minTemp: $_minTemp');
    } catch (e) {
      debugPrint('❌ Error loading thresholds: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveThreshold(String sensor, String type, double value) async {
    await _settingsService.saveThreshold(sensor, type, value);
    
    // Update local state and ThresholdConfig singleton
    final config = ThresholdConfig.instance;
    switch ('${sensor}_$type') {
      case 'temperature_max': _maxTemp = value; config.maxTemp = value; break;
      case 'temperature_min': _minTemp = value; config.minTemp = value; break;
      case 'water_level_min': _minWaterLevel = value; config.minWaterLevel = value; break;
      case 'ph_min': _minPh = value; config.minPh = value; break;
      case 'ph_max': _maxPh = value; config.maxPh = value; break;
      case 'tds_min': _minTds = value; config.minTds = value; break;
      case 'tds_max': _maxTds = value; config.maxTds = value; break;
      case 'light_intensity_min': _minLight = value; config.minLight = value; break;
      case 'humidity_min': _minHumidity = value; config.minHumidity = value; break;
      case 'humidity_max': _maxHumidity = value; config.maxHumidity = value; break;
    }
    notifyListeners();
  }
}
