import '../data/services/actuator_health_monitor.dart';
import '../data/models/threshold_config.dart';

/// Example integration of ActuatorHealthMonitor into your app
/// 
/// This shows how to call the health checks when you receive sensor data
/// and know the actuator states. Integrate this logic wherever you process
/// sensor readings and actuator states together.
class ActuatorHealthIntegration {
  final ActuatorHealthMonitor _healthMonitor = ActuatorHealthMonitor.instance;
  final ThresholdConfig _thresholds = ThresholdConfig.instance;

  /// Call this method whenever you receive new sensor data and know actuator states
  /// 
  /// Example usage in your FirestoreService or wherever you process sensor data:
  /// ```dart
  /// void processSensorData(Map<String, dynamic> sensorData, Map<String, dynamic> actuators) {
  ///   ActuatorHealthIntegration.instance.checkAllActuatorHealth(
  ///     sensorData: sensorData,
  ///     actuators: actuators,
  ///   );
  /// }
  /// ```
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

/// INTEGRATION EXAMPLE for FirestoreService:
/// 
/// Add this to your FirestoreService.getSensorStream() method:
/// 
/// ```dart
/// Stream<List<SensorData>> getSensorStream() {
///   final healthIntegration = ActuatorHealthIntegration();
///   
///   return _firestore
///       .collection('devices')
///       .doc(_deviceId)
///       .snapshots()
///       .map((snapshot) {
///         if (snapshot.exists && snapshot.data() != null) {
///           final data = snapshot.data()!;
///           
///           // Extract actuator states
///           final actuators = data['actuators'] as Map<String, dynamic>? ?? {};
///           
///           // Check actuator health
///           healthIntegration.checkAllActuatorHealth(
///             sensorData: data,
///             actuators: actuators,
///           );
///           
///           // ... rest of your existing code
///         }
///         // ... return sensor data
///       });
/// }
/// ```
