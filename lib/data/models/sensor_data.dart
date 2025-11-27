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


  factory SensorData.fromMap(String id, Map<String, dynamic> map) {
    // Get the value and ensure it's a string
    final dynamic rawValue = map['value'];
    final String valueString = rawValue?.toString() ?? '0';

    // Get unit
    final String unit = map['unit'] ?? '';

    // Determine icon and color based on the sensor ID/name
    IconData icon = Icons.help_outline;
    Color color = Colors.grey;

    switch (id) {
      case 'temperature':
        icon = Icons.thermostat;
        color = Colors.orange;
        break;
      case 'ph':
        icon = Icons.science_outlined;
        color = Colors.blue;
        break;
      case 'water_level':
        icon = Icons.water_drop;
        color = Colors.lightBlue;
        break;
      case 'light_intensity':
        icon = Icons.lightbulb_outline;
        color = Colors.yellow.shade700;
        break;
      case 'tds':
        icon = Icons.opacity;
        color = Colors.purple;
        break;
      case 'humidity':
        icon = Icons.grain;
        color = Colors.cyan;
        break;
    }

    // This formats 'water_level' to 'Water Level'
    final String formattedName = id
        .replaceAll('_', ' ')
        .split(' ')
        .map((l) => l.isNotEmpty ? l[0].toUpperCase() + l.substring(1) : '')
        .join(' ');

    return SensorData(
      name: formattedName,
      value: valueString,
      unit: unit,
      icon: icon,
      color: color,
    );
  }
}