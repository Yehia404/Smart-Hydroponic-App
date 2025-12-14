import 'package:flutter/foundation.dart';

/// Singleton class to manage sensor calibration offsets
/// These offsets are applied to raw sensor readings to correct for sensor drift or inaccuracies
class SensorCalibration extends ChangeNotifier {
  static final SensorCalibration instance = SensorCalibration._internal();
  
  SensorCalibration._internal();

  // Calibration offsets for each sensor type
  double _temperatureOffset = 0.0;
  double _phOffset = 0.0;
  double _waterLevelOffset = 0.0;
  double _lightIntensityOffset = 0.0;
  double _tdsOffset = 0.0;
  double _humidityOffset = 0.0;

  // Getters for raw offsets
  double get temperatureOffset => _temperatureOffset;
  double get phOffset => _phOffset;
  double get waterLevelOffset => _waterLevelOffset;
  double get lightIntensityOffset => _lightIntensityOffset;
  double get tdsOffset => _tdsOffset;
  double get humidityOffset => _humidityOffset;

  // Setters with validation
  set temperatureOffset(double value) {
    _temperatureOffset = value.clamp(-10.0, 10.0);
    notifyListeners();
    debugPrint('🔧 CALIBRATION: Temperature offset set to $_temperatureOffset°C');
  }

  set phOffset(double value) {
    _phOffset = value.clamp(-3.0, 3.0);
    notifyListeners();
    debugPrint('🔧 CALIBRATION: pH offset set to $_phOffset');
  }

  set waterLevelOffset(double value) {
    _waterLevelOffset = value.clamp(-50.0, 50.0);
    notifyListeners();
    debugPrint('🔧 CALIBRATION: Water level offset set to $_waterLevelOffset%');
  }

  set lightIntensityOffset(double value) {
    _lightIntensityOffset = value.clamp(-50.0, 50.0);
    notifyListeners();
    debugPrint('🔧 CALIBRATION: Light intensity offset set to $_lightIntensityOffset%');
  }

  set tdsOffset(double value) {
    _tdsOffset = value.clamp(-500.0, 500.0);
    notifyListeners();
    debugPrint('🔧 CALIBRATION: TDS offset set to $_tdsOffset ppm');
  }

  set humidityOffset(double value) {
    _humidityOffset = value.clamp(-50.0, 50.0);
    notifyListeners();
    debugPrint('🔧 CALIBRATION: Humidity offset set to $_humidityOffset%');
  }

  /// Apply calibration to a temperature reading
  double calibrateTemperature(double rawValue) {
    return rawValue + _temperatureOffset;
  }

  /// Apply calibration to a pH reading
  double calibratePh(double rawValue) {
    return (rawValue + _phOffset).clamp(0.0, 14.0);
  }

  /// Apply calibration to a water level reading
  int calibrateWaterLevel(int rawValue) {
    return (rawValue + _waterLevelOffset).clamp(0, 100).round();
  }

  /// Apply calibration to a light intensity reading
  int calibrateLightIntensity(int rawValue) {
    return (rawValue + _lightIntensityOffset).clamp(0, 100).round();
  }

  /// Apply calibration to a TDS reading
  int calibrateTds(int rawValue) {
    return (rawValue + _tdsOffset).clamp(0, 10000).round();
  }

  /// Apply calibration to a humidity reading
  int calibrateHumidity(int rawValue) {
    return (rawValue + _humidityOffset).clamp(0, 100).round();
  }

  /// Reset all calibrations to zero
  void resetAll() {
    _temperatureOffset = 0.0;
    _phOffset = 0.0;
    _waterLevelOffset = 0.0;
    _lightIntensityOffset = 0.0;
    _tdsOffset = 0.0;
    _humidityOffset = 0.0;
    notifyListeners();
    debugPrint('🔧 CALIBRATION: All offsets reset to zero');
  }
}
