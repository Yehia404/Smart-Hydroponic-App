import 'package:flutter/material.dart';
import '../data/services/firestore_service.dart';


class AnalyticsHistoryViewModel extends ChangeNotifier {
  
}

// Define Data Models
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