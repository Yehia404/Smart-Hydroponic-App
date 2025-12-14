import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/sensor_data.dart';
import '../data/services/firestore_service.dart';

class SensorMonitoringViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService;
  List<SensorData> _sensors = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _autoUpdate = false;
  StreamSubscription<List<SensorData>>? _sensorStreamSubscription;

  List<SensorData> get sensors => _sensors;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get autoUpdate => _autoUpdate;

  SensorMonitoringViewModel(this._firestoreService) {
    loadSensorData();
    // Enable auto-update by default
    toggleAutoUpdate();
  }

  Future<void> loadSensorData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch once immediately
      _sensors = await _firestoreService.getSensorStream().first;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load sensor data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void refreshSensorData() {
    loadSensorData();
  }

  void calibrateSensor(String sensorName) {
    // TODO: Implement calibration logic
    // This would typically call a service to calibrate the sensor
  }

  void toggleAutoUpdate() {
    _autoUpdate = !_autoUpdate;
    
    if (_autoUpdate) {
      // Start listening to the stream
      _sensorStreamSubscription = _firestoreService.getSensorStream().listen(
        (sensorData) {
          _sensors = sensorData;
          notifyListeners();
        },
        onError: (error) {
          _errorMessage = 'Stream error: $error';
          notifyListeners();
        },
      );
    } else {
      // Cancel the stream subscription
      _sensorStreamSubscription?.cancel();
      _sensorStreamSubscription = null;
    }
    
    notifyListeners();
  }

  @override
  void dispose() {
    _sensorStreamSubscription?.cancel();
    super.dispose();
  }

  String getSensorStatus(SensorData sensor) {
    // TODO: Implement actual status logic based on sensor thresholds
    double value = double.tryParse(sensor.value) ?? 0;
    
    if (sensor.name == 'Temperature') {
      if (value > 28) return 'High';
      if (value < 18) return 'Low';
      return 'Normal';
    } else if (sensor.name == 'Water pH') {
      if (value > 7.5 || value < 5.5) return 'Warning';
      return 'Normal';
    } else if (sensor.name == 'Water Level') {
      if (value < 20) return 'Low';
      return 'Normal';
    }
    return 'Normal';
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Normal':
        return Colors.green;
      case 'Warning':
        return Colors.orange;
      case 'High':
      case 'Low':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
