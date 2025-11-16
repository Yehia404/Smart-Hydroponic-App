import 'package:flutter/material.dart';

class SensorData {
  final String name;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  SensorData({
    required this.name,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });
}
