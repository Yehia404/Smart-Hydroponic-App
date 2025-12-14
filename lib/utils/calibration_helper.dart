import '../data/models/sensor_calibration.dart';

/// Helper class for applying calibration to individual sensor values
class CalibrationHelper {
  static final SensorCalibration _calibration = SensorCalibration.instance;

  static double calibrateTemperature(double value) =>
      _calibration.calibrateTemperature(value);

  static double calibratePh(double value) => _calibration.calibratePh(value);

  static int calibrateWaterLevel(int value) =>
      _calibration.calibrateWaterLevel(value);

  static int calibrateLightIntensity(int value) =>
      _calibration.calibrateLightIntensity(value);

  static int calibrateTds(int value) => _calibration.calibrateTds(value);

  static int calibrateHumidity(int value) =>
      _calibration.calibrateHumidity(value);

  static bool get hasActiveCalibrations {
    return _calibration.temperatureOffset != 0.0 ||
        _calibration.phOffset != 0.0 ||
        _calibration.waterLevelOffset != 0.0 ||
        _calibration.lightIntensityOffset != 0.0 ||
        _calibration.tdsOffset != 0.0 ||
        _calibration.humidityOffset != 0.0;
  }

  /// Apply calibration to a sensor value based on sensor type
  static dynamic calibrateBySensorType(String sensorType, dynamic rawValue) {
    if (rawValue == null) return rawValue;

    try {
      switch (sensorType) {
        case 'temperature':
          final double val = double.parse(rawValue.toString());
          return calibrateTemperature(val);
        case 'ph':
          final double val = double.parse(rawValue.toString());
          return calibratePh(val);
        case 'water_level':
          final int val = int.parse(rawValue.toString());
          return calibrateWaterLevel(val);
        case 'light_intensity':
          final int val = int.parse(rawValue.toString());
          return calibrateLightIntensity(val);
        case 'tds':
          final int val = int.parse(rawValue.toString());
          return calibrateTds(val);
        case 'humidity':
          final int val = int.parse(rawValue.toString());
          return calibrateHumidity(val);
        default:
          return rawValue;
      }
    } catch (e) {
      // If parsing fails, return original value
      return rawValue;
    }
  }
}

