import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/services/tts_service.dart';
import 'home_overview_viewmodel.dart';
import 'sensor_monitoring_viewmodel.dart';
import 'actuator_control_viewmodel.dart';
import 'navigation_viewmodel.dart';

class TtsViewModel extends ChangeNotifier {
  final TtsService _ttsService = TtsService();
  bool _isSpeaking = false;
  bool _isInitialized = false;

  bool get isSpeaking => _isSpeaking;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await _ttsService.initialize();
      
      // Set up callbacks to update UI when speaking starts/stops
      _ttsService.onStart = () {
        _isSpeaking = true;
        notifyListeners();
      };
      
      _ttsService.onComplete = () {
        _isSpeaking = false;
        notifyListeners();
      };
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('TTS initialization error: $e');
    }
  }

  Future<void> speakCurrentScreen(BuildContext context) async {
    try {
      if (!_isInitialized) await initialize();

      if (_isSpeaking) {
        print('🔇 Stopping TTS...');
        await stop();
        return;
      }

      // Get text based on current screen
      final String screenText = _getScreenContent(context);
      
      print('🔊 Speaking ${screenText.length} characters...');
      _isSpeaking = true;
      notifyListeners();
      
      await _ttsService.speak(screenText);
    } catch (e) {
      print('❌ TTS Error: $e');
      _isSpeaking = false;
      notifyListeners();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Text-to-Speech error: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  String _getScreenContent(BuildContext context) {
    try {
      final navViewModel = Provider.of<NavigationViewModel>(context, listen: false);
      final currentIndex = navViewModel.selectedIndex;
      
      switch (currentIndex) {
        case 0: // Home/Overview
          return _getHomeOverviewContent(context);
        case 1: // Sensor Monitoring
          return _getSensorMonitoringContent(context);
        case 2: // Control Panel
          return _getControlPanelContent(context);
        case 3: // Analytics
          return 'Analytics and History screen. View historical sensor data, trends, and export reports.';
        default:
          return 'Smart Hydroponic System Dashboard.';
      }
    } catch (e) {
      print('Error getting screen content: $e');
      return 'Smart Hydroponic System Dashboard.';
    }
  }

  String _getHomeOverviewContent(BuildContext context) {
    try {
      final homeViewModel = Provider.of<HomeOverviewViewModel>(context, listen: false);
      final sensorSummary = homeViewModel.sensorSummary;
      
      final buffer = StringBuffer('Home Overview. ');
      
      if (sensorSummary.isEmpty) {
        buffer.write('No sensor data available. ');
      } else {
        buffer.write('Current sensor readings. ');
        for (var sensor in sensorSummary) {
          final name = sensor['name'] ?? 'Unknown';
          final value = sensor['value'];
          final unit = sensor['unit'] ?? '';
          
          if (value is num) {
            buffer.write('$name: ${value.toStringAsFixed(1)} $unit. ');
          } else {
            buffer.write('$name: $value $unit. ');
          }
        }
      }
      
      return buffer.toString();
    } catch (e) {
      print('Error reading home overview: $e');
      return 'Home Overview screen.';
    }
  }

  String _getSensorMonitoringContent(BuildContext context) {
    try {
      final sensorViewModel = Provider.of<SensorMonitoringViewModel>(context, listen: false);
      final sensors = sensorViewModel.sensors;
      
      final buffer = StringBuffer('Sensor Monitoring. ');
      
      if (sensors.isEmpty) {
        buffer.write('No sensor data available. ');
      } else {
        buffer.write('Detailed sensor readings. ');
        for (var sensor in sensors) {
          if (sensor.value is num) {
            buffer.write('${sensor.name}: ${(sensor.value as num).toStringAsFixed(1)} ${sensor.unit}. ');
          } else {
            buffer.write('${sensor.name}: ${sensor.value} ${sensor.unit}. ');
          }
        }
      }
      
      return buffer.toString();
    } catch (e) {
      print('Error reading sensor monitoring: $e');
      return 'Sensor Monitoring screen.';
    }
  }

  String _getControlPanelContent(BuildContext context) {
    try {
      final controlViewModel = Provider.of<ActuatorControlViewModel>(context, listen: false);
      
      final buffer = StringBuffer('Control Panel. ');
      buffer.write('Water Pump is ${controlViewModel.isPumpOn ? "ON" : "OFF"}. ');
      buffer.write('Grow Lights are ${controlViewModel.areLightsOn ? "ON" : "OFF"}. ');
      buffer.write('Ventilation Fans are ${controlViewModel.areFansOn ? "ON" : "OFF"}. ');
      
      return buffer.toString();
    } catch (e) {
      print('Error reading control panel: $e');
      return 'Control Panel screen.';
    }
  }

  Future<void> stop() async {
    await _ttsService.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }
}
