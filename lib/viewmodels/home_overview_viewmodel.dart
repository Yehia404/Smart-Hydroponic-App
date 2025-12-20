import 'dart:async';
import 'package:flutter/material.dart';
import '../data/services/firestore_service.dart';
import '../data/services/settings_service.dart';
import '../data/services/local_cache_service.dart';
import '../data/models/sensor_data.dart';

class HomeOverviewViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final SettingsService _settingsService = SettingsService.instance;
  final LocalCacheService _cacheService = LocalCacheService.instance;

  bool _isSystemOnline = true;
  String _currentMode = 'automatic';
  List<Map<String, dynamic>> _sensorSummary = [];
  List<Map<String, dynamic>> _automationRules = [];
  StreamSubscription<List<SensorData>>? _sensorStreamSubscription;
  Timer? _connectivityTimer;

  // Track last execution time for each rule to avoid rapid re-triggering
  final Map<int, DateTime> _lastRuleExecution = {};

  bool get isSystemOnline => _isSystemOnline;
  String get currentMode => _currentMode;

  HomeOverviewViewModel(this._firestoreService) {
    _loadAutomationRules();
    _loadCachedSensorData(); // Load cached data first
    _startListeningToSensors();
  }

  List<Map<String, dynamic>> get sensorSummary => _sensorSummary;

  /// Load cached sensor data to show immediately while waiting for Firestore
  void _loadCachedSensorData() {
    if (_cacheService.hasCachedData) {
      final cached = _cacheService.getCachedSensorReadings();
      debugPrint('💾 SENSORS: Loading from cache...');

      // When showing cached data, system is considered offline until we get live data
      _isSystemOnline = false;

      // Build sensor summary from cached data
      _sensorSummary = [
        {
          'name': 'Temperature',
          'value': cached['temperature'].toString(),
          'unit': '°C',
          'icon': Icons.thermostat,
          'color': Colors.orange,
        },
        {
          'name': 'Ph',
          'value': cached['ph'].toString(),
          'unit': '',
          'icon': Icons.science_outlined,
          'color': Colors.blue,
        },
        {
          'name': 'Water Level',
          'value': cached['water_level'].toString(),
          'unit': '%',
          'icon': Icons.water_drop,
          'color': Colors.lightBlue,
        },
        {
          'name': 'Light Intensity',
          'value': cached['light_intensity'].toString(),
          'unit': '%',
          'icon': Icons.lightbulb_outline,
          'color': Colors.yellow.shade700,
        },
      ];
      notifyListeners();
    }
  }

  Future<void> _loadAutomationRules() async {
    _automationRules = await _settingsService.getRules();
  }

  /// Reset the connectivity timer - called when data is received
  void _resetConnectivityTimer() {
    _connectivityTimer?.cancel();
    _connectivityTimer = Timer(const Duration(seconds: 15), () {
      // No data received for 15 seconds - mark as offline
      if (_isSystemOnline) {
        _isSystemOnline = false;
        debugPrint('🔴 SYSTEM: Offline - no data received for 15 seconds');
        notifyListeners();
      }
    });
  }

  void _startListeningToSensors() {
    // Start the connectivity timer
    _resetConnectivityTimer();

    _sensorStreamSubscription = _firestoreService.getSensorStream().listen(
      (sensorDataList) async {
        // Reset connectivity timer - we received data
        _resetConnectivityTimer();

        // Mark system as online when we receive data from Firestore
        if (!_isSystemOnline) {
          _isSystemOnline = true;
          debugPrint('🟢 SYSTEM: Back online - receiving Firestore data');
        }

        // Reload rules periodically to catch any changes made in settings
        // This ensures toggled rules are immediately active
        await _loadAutomationRules();

        // Take only the first 4 sensors for the dashboard summary
        _sensorSummary = sensorDataList
            .take(4)
            .map(
              (sensor) => {
                'name': sensor.name,
                'value': sensor.value,
                'unit': sensor.unit,
                'icon': sensor.icon,
                'color': sensor.color,
              },
            )
            .toList();

        // Cache sensor readings for next app launch
        _cacheSensorData(sensorDataList);

        // Execute automation rules if in automatic mode
        if (_currentMode == 'automatic') {
          _executeAutomationRules(sensorDataList);
        }

        notifyListeners();
      },
      onError: (error) {
        // Mark system as offline when there's an error (e.g., no internet)
        _isSystemOnline = false;
        debugPrint('🔴 SYSTEM: Offline - Firestore error: $error');
        notifyListeners();
      },
    );
  }

  /// Cache sensor data locally for offline/quick access
  void _cacheSensorData(List<SensorData> sensorDataList) {
    try {
      // Extract values from sensor data list
      double temperature = 0.0;
      double ph = 0.0;
      int waterLevel = 0;
      int lightIntensity = 0;
      int tds = 0;
      int humidity = 0;

      for (var sensor in sensorDataList) {
        final value = double.tryParse(sensor.value) ?? 0.0;
        switch (sensor.name.toLowerCase()) {
          case 'temperature':
            temperature = value;
            break;
          case 'ph':
            ph = value;
            break;
          case 'water level':
            waterLevel = value.toInt();
            break;
          case 'light intensity':
            lightIntensity = value.toInt();
            break;
          case 'tds':
            tds = value.toInt();
            break;
          case 'humidity':
            humidity = value.toInt();
            break;
        }
      }

      _cacheService.saveSensorReadings(
        temperature: temperature,
        ph: ph,
        waterLevel: waterLevel,
        lightIntensity: lightIntensity,
        tds: tds,
        humidity: humidity,
      );
    } catch (e) {
      debugPrint('Error caching sensor data: $e');
    }
  }

  void _executeAutomationRules(List<SensorData> sensorDataList) {
    final now = DateTime.now();

    debugPrint('🤖 Checking ${_automationRules.length} automation rules...');

    for (var rule in _automationRules) {
      // Skip disabled rules
      if (rule['isEnabled'] != 1) {
        debugPrint(
          '   ⏭️ Skipping disabled rule: ${rule['sensor']} ${rule['condition']} ${rule['threshold']}',
        );
        continue;
      }

      final ruleId = rule['id'] as int;

      // Rate limiting: Don't execute the same rule more than once per minute
      if (_lastRuleExecution.containsKey(ruleId)) {
        final timeSinceLastExecution = now.difference(
          _lastRuleExecution[ruleId]!,
        );
        if (timeSinceLastExecution.inSeconds < 60) {
          debugPrint(
            '   ⏳ Rule $ruleId executed ${timeSinceLastExecution.inSeconds}s ago, skipping (rate limit)',
          );
          continue;
        }
      }

      // Find the sensor value
      final sensorName = rule['sensor'] as String;
      debugPrint('   🔍 Looking for sensor: "$sensorName"');
      debugPrint(
        '   📊 Available sensors: ${sensorDataList.map((s) => s.name).join(", ")}',
      );

      final sensorData = sensorDataList.firstWhere(
        (s) => s.name.toLowerCase() == sensorName.toLowerCase(),
        orElse: () => SensorData(
          name: '',
          value: '0',
          unit: '',
          icon: Icons.help,
          color: Colors.grey,
        ),
      );

      if (sensorData.name.isEmpty) {
        debugPrint('   ❌ Sensor "$sensorName" not found!');
        continue;
      }

      // Check if condition is met
      final condition = rule['condition'] as String;
      final threshold = (rule['threshold'] as num).toDouble();
      final sensorValue = double.tryParse(sensorData.value) ?? 0.0;

      debugPrint('   📏 Checking: $sensorValue $condition $threshold');

      bool conditionMet = false;
      if (condition == '>' && sensorValue > threshold) {
        conditionMet = true;
      } else if (condition == '<' && sensorValue < threshold) {
        conditionMet = true;
      }

      if (conditionMet) {
        // Execute the action
        final actuator = rule['actuator'] as String;
        final action = rule['action'] as String;
        final isOn = action.toLowerCase() == 'on';

        debugPrint('   ✅ CONDITION MET! Executing: $actuator → $action');

        // Update actuator in Firestore
        _firestoreService.updateActuator(actuator, isOn);

        // Log the control action as automated
        _firestoreService.logControlAction(actuator, isOn, source: 'automated');

        // Record execution time
        _lastRuleExecution[ruleId] = now;
      } else {
        debugPrint('   ⏸️ Condition not met (value: $sensorValue)');
      }
    }
  }

  void setMode(String mode) {
    debugPrint('🔄 Mode changed from $_currentMode to $mode');
    _currentMode = mode;
    notifyListeners();

    // Reload rules when switching to automatic mode
    if (mode == 'automatic') {
      debugPrint('🤖 Auto mode activated - automation rules are now active');
      _loadAutomationRules();
    } else {
      debugPrint('👤 Manual mode activated - automation rules are disabled');
    }
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    _sensorStreamSubscription?.cancel();
    super.dispose();
  }
}
