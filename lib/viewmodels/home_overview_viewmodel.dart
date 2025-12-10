import 'dart:async';
import 'package:flutter/material.dart';
import '../data/services/firestore_service.dart';
import '../data/services/settings_service.dart';
import '../data/models/sensor_data.dart';

class HomeOverviewViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final SettingsService _settingsService = SettingsService.instance;

  bool _isSystemOnline = true;
  String _currentMode = 'automatic';
  List<Map<String, dynamic>> _sensorSummary = [];
  List<Map<String, dynamic>> _automationRules = [];
  StreamSubscription<List<SensorData>>? _sensorStreamSubscription;

  // Track last execution time for each rule to avoid rapid re-triggering
  final Map<int, DateTime> _lastRuleExecution = {};

  bool get isSystemOnline => _isSystemOnline;
  String get currentMode => _currentMode;

  HomeOverviewViewModel(this._firestoreService) {
    _loadAutomationRules();
    _startListeningToSensors();
  }

  List<Map<String, dynamic>> get sensorSummary => _sensorSummary;

  Future<void> _loadAutomationRules() async {
    _automationRules = await _settingsService.getRules();
  }

  void _startListeningToSensors() {
    _sensorStreamSubscription = _firestoreService.getSensorStream().listen(
          (sensorDataList) async {
        // Reload rules periodically to catch any changes made in settings
        // This ensures toggled rules are immediately active
        await _loadAutomationRules();

        // Take only the first 4 sensors for the dashboard summary
        _sensorSummary = sensorDataList.take(4).map((sensor) => {
          'name': sensor.name,
          'value': sensor.value,
          'unit': sensor.unit,
          'icon': sensor.icon,
          'color': sensor.color,
        }).toList();

        // Execute automation rules if in automatic mode
        if (_currentMode == 'automatic') {
          _executeAutomationRules(sensorDataList);
        }

        notifyListeners();
      },
      onError: (error) {
        print('Error loading sensor data: $error');
      },
    );
  }

  void _executeAutomationRules(List<SensorData> sensorDataList) {
    final now = DateTime.now();

    debugPrint('🤖 Checking ${_automationRules.length} automation rules...');

    for (var rule in _automationRules) {
      // Skip disabled rules
      if (rule['isEnabled'] != 1) {
        debugPrint('   ⏭️ Skipping disabled rule: ${rule['sensor']} ${rule['condition']} ${rule['threshold']}');
        continue;
      }

      final ruleId = rule['id'] as int;

      // Rate limiting: Don't execute the same rule more than once per minute
      if (_lastRuleExecution.containsKey(ruleId)) {
        final timeSinceLastExecution = now.difference(_lastRuleExecution[ruleId]!);
        if (timeSinceLastExecution.inSeconds < 60) {
          debugPrint('   ⏳ Rule $ruleId executed ${timeSinceLastExecution.inSeconds}s ago, skipping (rate limit)');
          continue;
        }
      }

      // Find the sensor value
      final sensorName = rule['sensor'] as String;
      debugPrint('   🔍 Looking for sensor: "$sensorName"');
      debugPrint('   📊 Available sensors: ${sensorDataList.map((s) => s.name).join(", ")}');

      final sensorData = sensorDataList.firstWhere(
            (s) => s.name.toLowerCase() == sensorName.toLowerCase(),
        orElse: () => SensorData(name: '', value: '0', unit: '', icon: Icons.help, color: Colors.grey),
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
    _sensorStreamSubscription?.cancel();
    super.dispose();
  }
}
