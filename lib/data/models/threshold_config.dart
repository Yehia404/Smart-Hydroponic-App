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
    if (value > maxTemp + 3) return AlertStatus.criticalHigh;  // Very high
    if (value > maxTemp) return AlertStatus.warningHigh;       // Moderately high
    if (value < minTemp - 3) return AlertStatus.criticalLow;   // Very low
    if (value < minTemp) return AlertStatus.warningLow;        // Moderately low
    if (value > maxTemp - 2 || value < minTemp + 2) return AlertStatus.info;  // Getting close to limits
    return AlertStatus.normal;
  }

  AlertStatus checkWaterLevel(double value) {
    if (value < minWaterLevel - 20) return AlertStatus.criticalLow;  // Very low
    if (value < minWaterLevel) return AlertStatus.warningLow;         // Low
    if (value < minWaterLevel + 10) return AlertStatus.info;          // Getting low
    return AlertStatus.normal;
  }

  AlertStatus checkPh(double value) {
    if (value < minPh - 0.5) return AlertStatus.criticalLow;    // Very acidic
    if (value > maxPh + 0.5) return AlertStatus.criticalHigh;   // Very alkaline
    if (value < minPh) return AlertStatus.warningLow;            // Acidic
    if (value > maxPh) return AlertStatus.warningHigh;           // Alkaline
    if (value < minPh + 0.3 || value > maxPh - 0.3) return AlertStatus.info;  // Near limits
    return AlertStatus.normal;
  }

  AlertStatus checkTds(double value) {
    if (value > maxTds + 200) return AlertStatus.criticalHigh;  // Very high nutrients
    if (value > maxTds) return AlertStatus.warningHigh;         // High nutrients
    if (value < minTds - 100) return AlertStatus.criticalLow;   // Very low nutrients
    if (value < minTds) return AlertStatus.warningLow;          // Low nutrients
    if (value > maxTds - 100 || value < minTds + 100) return AlertStatus.info;  // Near limits
    return AlertStatus.normal;
  }

  AlertStatus checkLight(double value) {
    if (value < minLight - 15) return AlertStatus.criticalLow;  // Very dark
    if (value < minLight) return AlertStatus.warningLow;         // Dark
    if (value < minLight + 10) return AlertStatus.info;          // Getting dark
    return AlertStatus.normal;
  }

  AlertStatus checkHumidity(double value) {
    if (value < minHumidity - 10) return AlertStatus.criticalLow;   // Very dry
    if (value > maxHumidity + 10) return AlertStatus.criticalHigh;  // Very humid
    if (value < minHumidity) return AlertStatus.warningLow;          // Dry
    if (value > maxHumidity) return AlertStatus.warningHigh;         // Humid
    if (value < minHumidity + 5 || value > maxHumidity - 5) return AlertStatus.info;  // Near limits
    return AlertStatus.normal;
  }
}

enum AlertStatus {
  normal,
  info,
  warningLow,
  warningHigh,
  criticalLow,
  criticalHigh
}