import 'package:flutter/foundation.dart';

/// Represents the health status of an actuator
enum ActuatorHealth {
  healthy,
  failed,
  unknown,
}

/// Represents a detected actuator failure
class ActuatorFailure {
  final String actuatorName;
  final String reason;
  final DateTime detectedAt;
  final double? sensorValue;
  final String? sensorType;

  ActuatorFailure({
    required this.actuatorName,
    required this.reason,
    required this.detectedAt,
    this.sensorValue,
    this.sensorType,
  });

  @override
  String toString() {
    return 'ActuatorFailure($actuatorName: $reason at ${detectedAt.toLocal()})';
  }
}

/// Monitors actuator health and detects failures
/// Checks if actuators respond appropriately to threshold violations
class ActuatorHealthMonitor extends ChangeNotifier {
  static final ActuatorHealthMonitor instance = ActuatorHealthMonitor._internal();
  
  ActuatorHealthMonitor._internal();

  // Current health status for each actuator (start with healthy)
  final Map<String, ActuatorHealth> _actuatorHealth = {
    'pump': ActuatorHealth.healthy,
    'lights': ActuatorHealth.healthy,
    'fans': ActuatorHealth.healthy,
  };

  // History of detected failures
  final List<ActuatorFailure> _failureHistory = [];

  // Timestamps of last threshold violations (for detection cooldown)
  final Map<String, DateTime> _lastThresholdViolation = {};

  // Detection timeout (how long to wait before declaring failure)
  final Duration _detectionTimeout = const Duration(seconds: 30);

  // Getters
  Map<String, ActuatorHealth> get actuatorHealth => Map.unmodifiable(_actuatorHealth);
  List<ActuatorFailure> get failureHistory => List.unmodifiable(_failureHistory);

  /// Check if pump should be running based on water level
  void checkPumpHealth({
    required bool isPumpOn,
    required int waterLevel,
    required int waterLevelThresholdMin,
  }) {
    // Pump should be ON if water level is below minimum threshold
    bool shouldBeOn = waterLevel < waterLevelThresholdMin;

    if (shouldBeOn && !isPumpOn) {
      _recordThresholdViolation('pump');
      
      // Check if enough time has passed to declare failure
      if (_shouldDeclareFailure('pump')) {
        _declareFailure(
          actuatorName: 'Pump',
          reason: 'Failed to activate when water level ($waterLevel%) dropped below threshold ($waterLevelThresholdMin%)',
          sensorValue: waterLevel.toDouble(),
          sensorType: 'water_level',
        );
      }
    } else if (isPumpOn || !shouldBeOn) {
      // Pump is working correctly or not needed
      _markHealthy('pump');
    }
  }

  /// Check if fans should be running based on temperature
  void checkFansHealth({
    required bool areFansOn,
    required double temperature,
    required double temperatureThresholdMax,
  }) {
    // Fans should be ON if temperature exceeds maximum threshold
    bool shouldBeOn = temperature > temperatureThresholdMax;

    if (shouldBeOn && !areFansOn) {
      _recordThresholdViolation('fans');
      
      if (_shouldDeclareFailure('fans')) {
        _declareFailure(
          actuatorName: 'Fans',
          reason: 'Failed to activate when temperature (${temperature.toStringAsFixed(1)}°C) exceeded threshold (${temperatureThresholdMax.toStringAsFixed(1)}°C)',
          sensorValue: temperature,
          sensorType: 'temperature',
        );
      }
    } else if (areFansOn || !shouldBeOn) {
      _markHealthy('fans');
    }
  }

  /// Check if lights should be running based on schedule or light intensity
  void checkLightsHealth({
    required bool areLightsOn,
    required int lightIntensity,
    required int lightIntensityThresholdMin,
    bool? shouldBeOnBySchedule,
  }) {
    // Lights should be ON if:
    // 1. Schedule says they should be on, OR
    // 2. Light intensity is below minimum threshold
    bool shouldBeOn = (shouldBeOnBySchedule ?? false) || 
                     (lightIntensity < lightIntensityThresholdMin);

    if (shouldBeOn && !areLightsOn) {
      _recordThresholdViolation('lights');
      
      if (_shouldDeclareFailure('lights')) {
        String reason = shouldBeOnBySchedule == true
            ? 'Failed to activate according to schedule'
            : 'Failed to activate when light intensity ($lightIntensity%) dropped below threshold ($lightIntensityThresholdMin%)';
        
        _declareFailure(
          actuatorName: 'Lights',
          reason: reason,
          sensorValue: lightIntensity.toDouble(),
          sensorType: 'light_intensity',
        );
      }
    } else if (areLightsOn || !shouldBeOn) {
      _markHealthy('lights');
    }
  }

  void _recordThresholdViolation(String actuator) {
    _lastThresholdViolation[actuator] = DateTime.now();
  }

  bool _shouldDeclareFailure(String actuator) {
    final lastViolation = _lastThresholdViolation[actuator];
    if (lastViolation == null) return false;

    final timeSinceViolation = DateTime.now().difference(lastViolation);
    return timeSinceViolation >= _detectionTimeout;
  }

  void _declareFailure({
    required String actuatorName,
    required String reason,
    double? sensorValue,
    String? sensorType,
  }) {
    final actuatorKey = actuatorName.toLowerCase();
    
    // Only declare failure once (not repeatedly)
    if (_actuatorHealth[actuatorKey] == ActuatorHealth.failed) {
      return;
    }

    _actuatorHealth[actuatorKey] = ActuatorHealth.failed;
    
    final failure = ActuatorFailure(
      actuatorName: actuatorName,
      reason: reason,
      detectedAt: DateTime.now(),
      sensorValue: sensorValue,
      sensorType: sensorType,
    );
    
    _failureHistory.add(failure);
    
    debugPrint('⚠️ ACTUATOR FAILURE DETECTED: $failure');
    notifyListeners();
  }

  void _markHealthy(String actuator) {
    if (_actuatorHealth[actuator] != ActuatorHealth.healthy) {
      _actuatorHealth[actuator] = ActuatorHealth.healthy;
      _lastThresholdViolation.remove(actuator);
      notifyListeners();
    }
  }

  /// Manually mark an actuator as healthy (for testing or reset)
  void resetActuatorHealth(String actuator) {
    _actuatorHealth[actuator] = ActuatorHealth.healthy;
    _lastThresholdViolation.remove(actuator);
    notifyListeners();
    debugPrint('✅ ACTUATOR HEALTH RESET: $actuator');
  }

  /// Clear all failure history
  void clearFailureHistory() {
    _failureHistory.clear();
    notifyListeners();
    debugPrint('🗑️ ACTUATOR FAILURE HISTORY CLEARED');
  }

  /// Get count of current failures
  int get currentFailureCount {
    return _actuatorHealth.values.where((h) => h == ActuatorHealth.failed).length;
  }

  /// Get list of currently failed actuators
  List<String> get failedActuators {
    return _actuatorHealth.entries
        .where((e) => e.value == ActuatorHealth.failed)
        .map((e) => e.key)
        .toList();
  }
}
