import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/sensor_data.dart';
import '../data/services/firestore_service.dart';
import '../data/services/local_cache_service.dart';

class SensorMonitoringViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final LocalCacheService _cacheService = LocalCacheService.instance;
  List<SensorData> _sensors = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _autoUpdate = false;
  bool _isFromCache = false;
  StreamSubscription<List<SensorData>>? _sensorStreamSubscription;

  List<SensorData> get sensors => _sensors;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get autoUpdate => _autoUpdate;
  bool get isFromCache => _isFromCache;

  SensorMonitoringViewModel(this._firestoreService) {
    _loadCachedDataThenFetch();
    // Enable auto-update by default
    toggleAutoUpdate();
  }

  /// Load cached sensor data first for immediate display, then fetch from Firestore
  Future<void> _loadCachedDataThenFetch() async {
    // 1. Load cached data immediately (if available)
    if (_cacheService.hasCachedData) {
      _loadCachedSensorData();
      _isFromCache = true;
      debugPrint('💾 SENSORS: Showing cached data while loading...');
    } else {
      _isLoading = true;
      notifyListeners();
    }

    // 2. Fetch fresh data from Firestore
    await _fetchFromFirestore();
  }

  /// Load sensor data from local cache
  void _loadCachedSensorData() {
    final cached = _cacheService.getCachedSensorReadings();
    
    _sensors = [
      SensorData(
        name: 'Temperature',
        value: cached['temperature'].toStringAsFixed(1),
        unit: '°C',
        icon: Icons.thermostat,
        color: Colors.orange,
      ),
      SensorData(
        name: 'Water pH',
        value: cached['ph'].toStringAsFixed(2),
        unit: '',
        icon: Icons.science_outlined,
        color: Colors.blue,
      ),
      SensorData(
        name: 'Water Level',
        value: cached['water_level'].toString(),
        unit: '%',
        icon: Icons.water_drop,
        color: Colors.lightBlue,
      ),
      SensorData(
        name: 'Light Intensity',
        value: cached['light_intensity'].toString(),
        unit: '%',
        icon: Icons.lightbulb_outline,
        color: Colors.yellow.shade700,
      ),
      SensorData(
        name: 'Nutrient TDS',
        value: cached['tds'].toString(),
        unit: 'ppm',
        icon: Icons.opacity,
        color: Colors.green,
      ),
      SensorData(
        name: 'Humidity',
        value: cached['humidity'].toString(),
        unit: '%',
        icon: Icons.water,
        color: Colors.teal,
      ),
    ];
    
    notifyListeners();
  }

  /// Fetch sensor data from Firestore
  Future<void> _fetchFromFirestore() async {
    try {
      final data = await _firestoreService.getSensorStream().first;
      _sensors = data;
      _isFromCache = false;
      _isLoading = false;
      _errorMessage = null;
      
      // Cache the new data
      _cacheSensorData(data);
      
      debugPrint('🔥 SENSORS: Loaded ${data.length} sensors from Firestore');
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load sensor data: $e';
      _isLoading = false;
      // Keep showing cached data if available
      if (_sensors.isEmpty) {
        debugPrint('⚠️ SENSORS: Failed to load and no cache available');
      } else {
        debugPrint('⚠️ SENSORS: Failed to load, using cached data');
      }
      notifyListeners();
    }
  }

  /// Cache sensor data for next app launch
  void _cacheSensorData(List<SensorData> sensorDataList) {
    try {
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
          case 'water ph':
            ph = value;
            break;
          case 'water level':
            waterLevel = value.toInt();
            break;
          case 'light intensity':
            lightIntensity = value.toInt();
            break;
          case 'nutrient tds':
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

  Future<void> loadSensorData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await _fetchFromFirestore();
  }

  void refreshSensorData() {
    loadSensorData();
  }

  void calibrateSensor(String sensorName) {
    // Calibration has been applied via the SensorCalibration singleton
    // This method can be used for additional logging or persistence
    debugPrint('✅ Sensor calibration applied for: $sensorName');
    
    // Optionally refresh sensor data to show calibrated values
    refreshSensorData();
  }

  void toggleAutoUpdate() {
    _autoUpdate = !_autoUpdate;
    
    if (_autoUpdate) {
      // Start listening to the stream
      _sensorStreamSubscription = _firestoreService.getSensorStream().listen(
        (sensorData) {
          _sensors = sensorData;
          _isFromCache = false; // We're now showing live data
          _errorMessage = null;
          
          // Cache the new data for next app launch
          _cacheSensorData(sensorData);
          
          notifyListeners();
        },
        onError: (error) {
          _errorMessage = 'Stream error: $error';
          // Keep isFromCache as is - if we had cached data, we're still showing it
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
