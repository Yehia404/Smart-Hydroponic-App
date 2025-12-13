import 'package:flutter/material.dart';
import '../data/services/firestore_service.dart';

class AnalyticsHistoryViewModel extends ChangeNotifier {
  BuildContext? _context;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Data storage for each sensor type
  List<DataPoint> _temperatureData = [];
  List<DataPoint> _phData = [];
  List<DataPoint> _waterLevelData = [];
  List<DataPoint> _lightIntensityData = [];
  List<DataPoint> _tdsData = [];
  List<DataPoint> _humidityData = [];
  
  // Time range selection default
  TimeRange _selectedRange = TimeRange.day;
  String _selectedSensor = 'temperature';
  
  // Computed statistics
  Map<String, SensorStats> _statistics = {};

  // Getters to expose state to the UI
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

  // Used for showing dialogs/snackbars
  void setContext(BuildContext context) {
    _context = context;
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