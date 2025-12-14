import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../data/services/firestore_service.dart';


class AnalyticsHistoryViewModel extends ChangeNotifier {
  BuildContext? _context;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Data storage
  List<DataPoint> _temperatureData = [];
  List<DataPoint> _phData = [];
  List<DataPoint> _waterLevelData = [];
  List<DataPoint> _lightIntensityData = [];
  List<DataPoint> _tdsData = [];
  List<DataPoint> _humidityData = [];
  
  // Time range selection
  TimeRange _selectedRange = TimeRange.day;
  String _selectedSensor = 'temperature';
  
  // Statistics
  Map<String, SensorStats> _statistics = {};

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<DataPoint> get temperatureData => _temperatureData;
  List<DataPoint> get phData => _phData;
  List<DataPoint> get waterLevelData => _waterLevelData;
  List<DataPoint> get lightIntensityData => _lightIntensityData;
  List<DataPoint> get tdsData => _tdsData;
  List<DataPoint> get humidityData => _humidityData;
  TimeRange get selectedRange => _selectedRange;
  String get selectedSensor => _selectedSensor;
  Map<String, SensorStats> get statistics => _statistics;
  
  List<DataPoint> getDataForSensor(String sensor) {
    switch (sensor) {
      case 'temperature': return _temperatureData;
      case 'ph': return _phData;
      case 'water_level': return _waterLevelData;
      case 'light_intensity': return _lightIntensityData;
      case 'tds': return _tdsData;
      case 'humidity': return _humidityData;
      default: return [];
    }
  }

  void setSelectedSensor(String sensor) {
    _selectedSensor = sensor;
    notifyListeners();
  }

  void setTimeRange(TimeRange range) {
    _selectedRange = range;
    loadHistoricalData();
  }

  void setContext(BuildContext context) {
    _context = context;
  }

  Future<void> loadHistoricalData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final historyData = await FirestoreService.instance.fetchHistory(_selectedRange);

      _temperatureData = [];
      _phData = [];
      _waterLevelData = [];
      _lightIntensityData = [];
      _tdsData = [];
      _humidityData = [];

      for (var data in historyData) {
        final timestamp = DateTime.parse(data['timestamp']);
        
        if (data['temperature'] != null) {
          _temperatureData.add(DataPoint(
            timestamp: timestamp,
            value: (data['temperature'] as num).toDouble(),
          ));
        }
        if (data['ph'] != null) {
          _phData.add(DataPoint(
            timestamp: timestamp,
            value: (data['ph'] as num).toDouble(),
          ));
        }
        if (data['water_level'] != null) {
          _waterLevelData.add(DataPoint(
            timestamp: timestamp,
            value: (data['water_level'] as num).toDouble(),
          ));
        }
        if (data['light_intensity'] != null) {
          _lightIntensityData.add(DataPoint(
            timestamp: timestamp,
            value: (data['light_intensity'] as num).toDouble(),
          ));
        }
        if (data['tds'] != null) {
          _tdsData.add(DataPoint(
            timestamp: timestamp,
            value: (data['tds'] as num).toDouble(),
          ));
        }
        if (data['humidity'] != null) {
          _humidityData.add(DataPoint(
            timestamp: timestamp,
            value: (data['humidity'] as num).toDouble(),
          ));
        }
      }

      _calculateStatistics();
      
    } catch (e) {
      _errorMessage = 'Error loading data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _calculateStatistics() {
    _statistics = {
      'temperature': _calculateStats(_temperatureData, '°C'),
      'ph': _calculateStats(_phData, ''),
      'water_level': _calculateStats(_waterLevelData, '%'),
      'light_intensity': _calculateStats(_lightIntensityData, '%'),
      'tds': _calculateStats(_tdsData, 'ppm'),
      'humidity': _calculateStats(_humidityData, '%'),
    };
  }

  SensorStats _calculateStats(List<DataPoint> data, String unit) {
    if (data.isEmpty) {
      return SensorStats(
        min: 0,
        max: 0,
        avg: 0,
        current: 0,
        trend: 0,
        unit: unit,
      );
    }

    final values = data.map((d) => d.value).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;
    final current = values.last;
    
    final trend = current - avg;

    return SensorStats(
      min: min,
      max: max,
      avg: avg,
      current: current,
      trend: trend,
      unit: unit,
    );
  }

  Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    // Check Android version
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 33) {
      // On Android 13+ (API 33+), storage permissions are not needed for app-specific directories
      // or public Downloads if using the right APIs.
      return true;
    }

    // Check current permission status
    PermissionStatus status = await Permission.storage.status;
    
    if (status.isGranted) return true;

    // Show explanation dialog
    if (_context != null && _context!.mounted) {
      bool? shouldRequest = await showDialog<bool>(
        context: _context!,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Storage Permission Required'),
            content: const Text(
              'This app needs access to storage to save the CSV file to your Downloads folder. '
              'Please grant storage permission in the next dialog.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Grant Permission'),
              ),
            ],
          );
        },
      );

      if (shouldRequest != true) return false;
    }

    // Request permission
    status = await Permission.storage.request();
    
    if (status.isGranted) return true;

    // Handle denial
    if (status.isPermanentlyDenied) {
      if (_context != null && _context!.mounted) {
        final shouldOpenSettings = await showDialog<bool>(
          context: _context!,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Permission Denied'),
              content: const Text(
                'Storage permission is permanently denied. '
                'Please enable it in app settings to save files.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Open Settings'),
                ),
              ],
            );
          },
        );
        
        if (shouldOpenSettings == true) {
          await openAppSettings();
        }
      }
      return false;
    }

    return false;
  }
}



class DataPoint {
  final DateTime timestamp;
  final double value;

  DataPoint({required this.timestamp, required this.value});
}

class SensorStats {
  final double min;
  final double max;
  final double avg;
  final double current;
  final double trend;
  final String unit;

  SensorStats({
    required this.min,
    required this.max,
    required this.avg,
    required this.current,
    required this.trend,
    required this.unit,
  });
}

enum TimeRange {
  hour,
  day,
  week,
  month,
}