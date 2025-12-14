import 'package:flutter/material.dart';
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