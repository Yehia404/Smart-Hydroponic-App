import 'package:flutter/material.dart';
import '../data/models/sensor_calibration.dart';

class SensorCalibrationViewModel extends ChangeNotifier {
  final SensorCalibration _calibration = SensorCalibration.instance;

  // Getters for current offsets
  double get temperatureOffset => _calibration.temperatureOffset;
  double get phOffset => _calibration.phOffset;
  double get waterLevelOffset => _calibration.waterLevelOffset;
  double get lightIntensityOffset => _calibration.lightIntensityOffset;
  double get tdsOffset => _calibration.tdsOffset;
  double get humidityOffset => _calibration.humidityOffset;

  // Update methods
  void setTemperatureOffset(double value) {
    _calibration.temperatureOffset = value;
    notifyListeners();
  }

  void setPhOffset(double value) {
    _calibration.phOffset = value;
    notifyListeners();
  }

  void setWaterLevelOffset(double value) {
    _calibration.waterLevelOffset = value;
    notifyListeners();
  }

  void setLightIntensityOffset(double value) {
    _calibration.lightIntensityOffset = value;
    notifyListeners();
  }

  void setTdsOffset(double value) {
    _calibration.tdsOffset = value;
    notifyListeners();
  }

  void setHumidityOffset(double value) {
    _calibration.humidityOffset = value;
    notifyListeners();
  }

  // Reset all calibrations
  void resetAllCalibrations() {
    _calibration.resetAll();
    notifyListeners();
  }

  // Check if any calibrations are active
  bool get hasActiveCalibrations {
    return temperatureOffset != 0.0 ||
        phOffset != 0.0 ||
        waterLevelOffset != 0.0 ||
        lightIntensityOffset != 0.0 ||
        tdsOffset != 0.0 ||
        humidityOffset != 0.0;
  }
}
