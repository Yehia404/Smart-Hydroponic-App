import '../services/settings_service.dart';

class ThresholdConfig {
  static final ThresholdConfig instance = ThresholdConfig._internal();
  ThresholdConfig._internal();

  // --- THRESHOLDS (Defaults) ---
  double maxTemp = 25.0;
  double minTemp = 15.0;

  // Water Level
  double minWaterLevel = 70.0;

  // pH
  double minPh = 5.5;
  double maxPh = 7.5;

  // TDS (Nutrients)
  double minTds = 600.0;
  double maxTds = 1200.0; // Critical if above 1200 ppm

  // Light Intensity
  double minLight = 30.0; // Warning if below 30%

  // Humidity
  double minHumidity = 40.0;
  double maxHumidity = 80.0;

  // --- INITIALIZATION ---
  Future<void> init() async {
    final settings = SettingsService.instance;
    maxTemp = await settings.getThreshold('temperature', 'max') ?? 25.0;
    minTemp = await settings.getThreshold('temperature', 'min') ?? 15.0;
    minWaterLevel = await settings.getThreshold('water_level', 'min') ?? 70.0;
    minPh = await settings.getThreshold('ph', 'min') ?? 5.5;
    maxPh = await settings.getThreshold('ph', 'max') ?? 7.5;
    minTds = await settings.getThreshold('tds', 'min') ?? 600.0;
    maxTds = await settings.getThreshold('tds', 'max') ?? 1200.0;
    minLight = await settings.getThreshold('light_intensity', 'min') ?? 30.0;
    minHumidity = await settings.getThreshold('humidity', 'min') ?? 40.0;
    maxHumidity = await settings.getThreshold('humidity', 'max') ?? 80.0;
  }

  /// Reset all thresholds to hardcoded defaults
  void resetToDefaults() {
    maxTemp = 25.0;
    minTemp = 15.0;
    minWaterLevel = 70.0;
    minPh = 5.5;
    maxPh = 7.5;
    minTds = 600.0;
    maxTds = 1200.0;
    minLight = 30.0;
    minHumidity = 40.0;
    maxHumidity = 80.0;
  }

  // --- CHECKER FUNCTIONS ---

  AlertStatus checkTemperature(double value) {
    if (value > maxTemp) return AlertStatus.criticalHigh;
    if (value < minTemp) return AlertStatus.warningLow;
    return AlertStatus.normal;
  }

  AlertStatus checkWaterLevel(double value) {
    if (value < minWaterLevel) return AlertStatus.criticalLow;
    return AlertStatus.normal;
  }

  AlertStatus checkPh(double value) {
    if (value < minPh) return AlertStatus.warningLow;
    if (value > maxPh) return AlertStatus.warningHigh;
    return AlertStatus.normal;
  }

  AlertStatus checkTds(double value) {
    if (value < minTds) return AlertStatus.warningLow;
    if (value > maxTds) return AlertStatus.criticalHigh;
    return AlertStatus.normal;
  }

  AlertStatus checkLight(double value) {
    if (value < minLight) return AlertStatus.warningLow;
    return AlertStatus.normal;
  }

  AlertStatus checkHumidity(double value) {
    if (value < minHumidity) return AlertStatus.warningLow;
    if (value > maxHumidity) return AlertStatus.warningHigh;
    return AlertStatus.normal;
  }
}

enum AlertStatus {
  normal,
  warningLow,
  warningHigh,
  criticalLow,
  criticalHigh
}