import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../data/services/firestore_service.dart';
import '../data/models/sensor_data.dart';

class AnalyticsHistoryViewModel extends ChangeNotifier {
  BuildContext? _context;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _sensorStreamSubscription;
  
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
  
  // Current real-time values (separate from historical data)
  Map<String, double> _currentValues = {
    'temperature': 0.0,
    'ph': 0.0,
    'water_level': 0.0,
    'light_intensity': 0.0,
    'tds': 0.0,
    'humidity': 0.0,
  };

  AnalyticsHistoryViewModel() {
    _startListeningToRealTimeData();
  }

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

  /// Listen to real-time sensor data from the device document
  void _startListeningToRealTimeData() {
    _sensorStreamSubscription = FirestoreService.instance.getSensorStream().listen(
      (sensorDataList) {
        // Update current values from real-time stream
        for (var sensor in sensorDataList) {
          final value = double.tryParse(sensor.value) ?? 0.0;
          switch (sensor.name.toLowerCase()) {
            case 'temperature':
              _currentValues['temperature'] = value;
              break;
            case 'ph':
              _currentValues['ph'] = value;
              break;
            case 'water level':
              _currentValues['water_level'] = value;
              break;
            case 'light intensity':
              _currentValues['light_intensity'] = value;
              break;
            case 'tds':
              _currentValues['tds'] = value;
              break;
            case 'humidity':
              _currentValues['humidity'] = value;
              break;
          }
        }
        // Recalculate statistics with new current values
        _calculateStatistics();
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error listening to sensor data: $error');
      },
    );
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
      'temperature': _calculateStats(_temperatureData, '°C', _currentValues['temperature'] ?? 0),
      'ph': _calculateStats(_phData, '', _currentValues['ph'] ?? 0),
      'water_level': _calculateStats(_waterLevelData, '%', _currentValues['water_level'] ?? 0),
      'light_intensity': _calculateStats(_lightIntensityData, '%', _currentValues['light_intensity'] ?? 0),
      'tds': _calculateStats(_tdsData, 'ppm', _currentValues['tds'] ?? 0),
      'humidity': _calculateStats(_humidityData, '%', _currentValues['humidity'] ?? 0),
    };
  }

  SensorStats _calculateStats(List<DataPoint> data, String unit, double currentValue) {
    if (data.isEmpty) {
      // Even with no historical data, show real-time current value
      return SensorStats(
        min: currentValue,
        max: currentValue,
        avg: currentValue,
        current: currentValue,
        trend: 0,
        unit: unit,
      );
    }

    final values = data.map((d) => d.value).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;
    
    // Use real-time current value instead of last historical value
    final current = currentValue > 0 ? currentValue : values.last;
    
    // Calculate trend (difference between current and average)
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
      // Permission.storage is always denied on Android 13+.
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

  Future<String?> exportData() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Request storage permission for Android
      if (Platform.isAndroid) {
        final hasPermission = await _requestStoragePermission();
        if (!hasPermission) {
          _errorMessage = 'Storage permission denied. Cannot save file.';
          _isLoading = false;
          notifyListeners();
          return null;
        }
      }

      // Prepare CSV data
      List<List<dynamic>> csvData = [
        ['Timestamp', 'Temperature (°C)', 'pH', 'Water Level (%)', 
         'Light Intensity (%)', 'TDS (ppm)', 'Humidity (%)']
      ];

      // Combine all data points by timestamp
      final allTimestamps = <DateTime>{};
      for (var point in _temperatureData) allTimestamps.add(point.timestamp);
      for (var point in _phData) allTimestamps.add(point.timestamp);
      for (var point in _waterLevelData) allTimestamps.add(point.timestamp);
      for (var point in _lightIntensityData) allTimestamps.add(point.timestamp);
      for (var point in _tdsData) allTimestamps.add(point.timestamp);
      for (var point in _humidityData) allTimestamps.add(point.timestamp);

      final sortedTimestamps = allTimestamps.toList()..sort();

      for (var timestamp in sortedTimestamps) {
        final dateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);
        csvData.add([
          dateStr,
          _findValueAtTime(_temperatureData, timestamp),
          _findValueAtTime(_phData, timestamp),
          _findValueAtTime(_waterLevelData, timestamp),
          _findValueAtTime(_lightIntensityData, timestamp),
          _findValueAtTime(_tdsData, timestamp),
          _findValueAtTime(_humidityData, timestamp),
        ]);
      }

      String csv = const ListToCsvConverter().convert(csvData);

      // Save to Downloads folder
      Directory? directory;
      String locationMessage;
      
      if (Platform.isAndroid) {
        // Try to save to Downloads directory
        try {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = Directory('/storage/emulated/0/Downloads');
          }
          if (!await directory.exists()) {
            // Fallback to app-specific external storage (no permission needed)
            directory = await getExternalStorageDirectory();
            locationMessage = 'Downloads (App folder)';
          } else {
            locationMessage = 'Downloads';
          }
        } catch (e) {
          // If all else fails, use app-specific storage
          directory = await getExternalStorageDirectory();
          locationMessage = 'Downloads (App folder)';
        }
      } else if (Platform.isIOS) {
        // On iOS, save to Documents directory (Downloads folder is not accessible)
        directory = await getApplicationDocumentsDirectory();
        locationMessage = 'Documents';
      } else {
        // Fallback to temporary directory for other platforms
        directory = await getTemporaryDirectory();
        locationMessage = 'Temp';
      }

      final fileName = 'hydroponic_data_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File('${directory!.path}/$fileName');
      await file.writeAsString(csv);

      _isLoading = false;
      notifyListeners();
      return 'File saved to $locationMessage folder: $fileName';
    } catch (e) {
      _errorMessage = 'Error exporting data: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  String _findValueAtTime(List<DataPoint> data, DateTime timestamp) {
    final point = data.firstWhere(
      (p) => p.timestamp == timestamp,
      orElse: () => DataPoint(timestamp: timestamp, value: 0),
    );
    return point.value == 0 ? '' : point.value.toStringAsFixed(2);
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
