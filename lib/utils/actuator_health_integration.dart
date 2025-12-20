import '../data/services/actuator_health_monitor.dart';
import '../data/models/threshold_config.dart';

class ActuatorHealthIntegration {
  final ActuatorHealthMonitor _healthMonitor = ActuatorHealthMonitor.instance;
  final ThresholdConfig _thresholds = ThresholdConfig.instance;

  void checkAllActuatorHealth({
    required Map<String, dynamic> sensorData,
    required Map<String, dynamic> actuators,
  }) {
    // Extract sensor values
    final double temperature = (sensorData['temperature'] ?? 0.0).toDouble();
    final int waterLevel = (sensorData['water_level'] ?? 0).toInt();
    final int lightIntensity = (sensorData['light_intensity'] ?? 0).toInt();

    // Extract actuator states
    final bool isPumpOn = actuators['pump'] ?? false;
    final bool areFansOn = actuators['fans'] ?? false;
    final bool areLightsOn = actuators['lights'] ?? false;

    // Check Pump Health
    _healthMonitor.checkPumpHealth(
      isPumpOn: isPumpOn,
      waterLevel: waterLevel,
      waterLevelThresholdMin: _thresholds.minWaterLevel.toInt(),
    );

    // Check Fans Health
    _healthMonitor.checkFansHealth(
      areFansOn: areFansOn,
      temperature: temperature,
      temperatureThresholdMax: _thresholds.maxTemp,
    );

    // Check Lights Health
    _healthMonitor.checkLightsHealth(
      areLightsOn: areLightsOn,
      lightIntensity: lightIntensity,
      lightIntensityThresholdMin: 30, // You can adjust this threshold
      shouldBeOnBySchedule: _shouldLightsBeOnBySchedule(),
    );
  }

  /// Example schedule check (customize based on your requirements)
  bool _shouldLightsBeOnBySchedule() {
    final now = DateTime.now();
    // Example: Lights should be on between 6 AM and 10 PM
    return now.hour >= 6 && now.hour < 22;
  }
}
