import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Service for caching sensor readings and actuator states locally
/// This allows the app to show last known values while initializing
class LocalCacheService {
  static final LocalCacheService instance = LocalCacheService._internal();
  LocalCacheService._internal();

  SharedPreferences? _prefs;

  // Keys for storage
  static const String _keyPumpState = 'actuator_pump';
  static const String _keyLightsState = 'actuator_lights';
  static const String _keyFansState = 'actuator_fans';
  static const String _keyTemperature = 'sensor_temperature';
  static const String _keyPh = 'sensor_ph';
  static const String _keyWaterLevel = 'sensor_water_level';
  static const String _keyLightIntensity = 'sensor_light_intensity';
  static const String _keyTds = 'sensor_tds';
  static const String _keyHumidity = 'sensor_humidity';
  static const String _keyLastUpdated = 'last_updated';

  /// Initialize SharedPreferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    debugPrint('💾 LOCAL CACHE: Initialized');
  }

  // ==================== ACTUATOR STATES ====================

  /// Save actuator states to local cache
  Future<void> saveActuatorStates({
    required bool isPumpOn,
    required bool areLightsOn,
    required bool areFansOn,
  }) async {
    if (_prefs == null) await init();
    
    await _prefs!.setBool(_keyPumpState, isPumpOn);
    await _prefs!.setBool(_keyLightsState, areLightsOn);
    await _prefs!.setBool(_keyFansState, areFansOn);
    
    debugPrint('💾 LOCAL CACHE: Saved actuators - Pump=$isPumpOn, Lights=$areLightsOn, Fans=$areFansOn');
  }

  /// Get cached actuator states
  Map<String, bool> getCachedActuatorStates() {
    return {
      'pump': _prefs?.getBool(_keyPumpState) ?? false,
      'lights': _prefs?.getBool(_keyLightsState) ?? false,
      'fans': _prefs?.getBool(_keyFansState) ?? false,
    };
  }

  /// Get individual actuator state
  bool getCachedPumpState() => _prefs?.getBool(_keyPumpState) ?? false;
  bool getCachedLightsState() => _prefs?.getBool(_keyLightsState) ?? false;
  bool getCachedFansState() => _prefs?.getBool(_keyFansState) ?? false;

  // ==================== SENSOR READINGS ====================

  /// Save sensor readings to local cache
  Future<void> saveSensorReadings({
    required double temperature,
    required double ph,
    required int waterLevel,
    required int lightIntensity,
    required int tds,
    required int humidity,
  }) async {
    if (_prefs == null) await init();
    
    await _prefs!.setDouble(_keyTemperature, temperature);
    await _prefs!.setDouble(_keyPh, ph);
    await _prefs!.setInt(_keyWaterLevel, waterLevel);
    await _prefs!.setInt(_keyLightIntensity, lightIntensity);
    await _prefs!.setInt(_keyTds, tds);
    await _prefs!.setInt(_keyHumidity, humidity);
    await _prefs!.setString(_keyLastUpdated, DateTime.now().toIso8601String());
    
    debugPrint('💾 LOCAL CACHE: Saved sensor readings');
  }

  /// Get cached sensor readings
  Map<String, dynamic> getCachedSensorReadings() {
    return {
      'temperature': _prefs?.getDouble(_keyTemperature) ?? 0.0,
      'ph': _prefs?.getDouble(_keyPh) ?? 0.0,
      'water_level': _prefs?.getInt(_keyWaterLevel) ?? 0,
      'light_intensity': _prefs?.getInt(_keyLightIntensity) ?? 0,
      'tds': _prefs?.getInt(_keyTds) ?? 0,
      'humidity': _prefs?.getInt(_keyHumidity) ?? 0,
    };
  }

  /// Get individual sensor reading
  double getCachedTemperature() => _prefs?.getDouble(_keyTemperature) ?? 0.0;
  double getCachedPh() => _prefs?.getDouble(_keyPh) ?? 0.0;
  int getCachedWaterLevel() => _prefs?.getInt(_keyWaterLevel) ?? 0;
  int getCachedLightIntensity() => _prefs?.getInt(_keyLightIntensity) ?? 0;
  int getCachedTds() => _prefs?.getInt(_keyTds) ?? 0;
  int getCachedHumidity() => _prefs?.getInt(_keyHumidity) ?? 0;

  /// Get timestamp of last cache update
  DateTime? getLastUpdated() {
    final timestamp = _prefs?.getString(_keyLastUpdated);
    if (timestamp != null) {
      return DateTime.tryParse(timestamp);
    }
    return null;
  }

  /// Check if cache has data
  bool get hasCachedData => _prefs?.containsKey(_keyTemperature) ?? false;

  /// Clear all cached data
  Future<void> clearCache() async {
    if (_prefs == null) await init();
    
    await _prefs!.remove(_keyPumpState);
    await _prefs!.remove(_keyLightsState);
    await _prefs!.remove(_keyFansState);
    await _prefs!.remove(_keyTemperature);
    await _prefs!.remove(_keyPh);
    await _prefs!.remove(_keyWaterLevel);
    await _prefs!.remove(_keyLightIntensity);
    await _prefs!.remove(_keyTds);
    await _prefs!.remove(_keyHumidity);
    await _prefs!.remove(_keyLastUpdated);
    
    debugPrint('💾 LOCAL CACHE: Cleared');
  }
}
