import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_hydroponic_app/data/models/sensor_data.dart';

void main() {
  group('SensorData Model Unit Tests', () {
    test('should create SensorData object with required fields', () {
      // Arrange & Act
      final sensorData = SensorData(
        name: 'Temperature',
        value: '25.5',
        unit: '°C',
        icon: Icons.thermostat,
        color: Colors.orange,
      );

      // Assert
      expect(sensorData.name, 'Temperature');
      expect(sensorData.value, '25.5');
      expect(sensorData.unit, '°C');
      expect(sensorData.icon, Icons.thermostat);
      expect(sensorData.color, Colors.orange);
    });

    test('should create SensorData from temperature map', () {
      // Arrange
      final map = {'value': 25.5, 'unit': '°C'};

      // Act
      final sensorData = SensorData.fromMap('temperature', map);

      // Assert
      expect(sensorData.name, 'Temperature');
      expect(sensorData.value, '25.5');
      expect(sensorData.unit, '°C');
      expect(sensorData.icon, Icons.thermostat);
      expect(sensorData.color, Colors.orange);
    });

    test('should create SensorData from pH map', () {
      // Arrange
      final map = {'value': 6.8, 'unit': ''};

      // Act
      final sensorData = SensorData.fromMap('ph', map);

      // Assert
      expect(sensorData.name, 'Ph'); // Auto-formatted from 'ph'
      expect(sensorData.value, '6.8');
      expect(sensorData.icon, Icons.science_outlined);
      expect(sensorData.color, Colors.blue);
    });

    test('should create SensorData from water_level map', () {
      // Arrange
      final map = {'value': 85, 'unit': '%'};

      // Act
      final sensorData = SensorData.fromMap('water_level', map);

      // Assert
      expect(sensorData.name, 'Water Level');
      expect(sensorData.value, '85');
      expect(sensorData.unit, '%');
      expect(sensorData.icon, Icons.water_drop);
      expect(sensorData.color, Colors.lightBlue);
    });

    test('should handle null value and convert to default', () {
      // Arrange
      final map = <String, dynamic>{'unit': '°C'};

      // Act
      final sensorData = SensorData.fromMap('temperature', map);

      // Assert
      expect(sensorData.value, '0');
    });

    test('should convert numeric value to string', () {
      // Arrange
      final map = {'value': 100, 'unit': '%'};

      // Act
      final sensorData = SensorData.fromMap('water_level', map);

      // Assert
      expect(sensorData.value, '100');
      expect(sensorData.value, isA<String>());
    });

    test('should handle light_intensity sensor type', () {
      // Arrange
      final map = {'value': 750, 'unit': 'lux'};

      // Act
      final sensorData = SensorData.fromMap('light_intensity', map);

      // Assert
      expect(sensorData.name, 'Light Intensity');
      expect(sensorData.icon, Icons.lightbulb_outline);
    });

    test('should handle tds sensor type', () {
      // Arrange
      final map = {'value': 1200, 'unit': 'ppm'};

      // Act
      final sensorData = SensorData.fromMap('tds', map);

      // Assert
      expect(sensorData.name, 'Tds'); // Auto-formatted from 'tds'
      expect(sensorData.value, '1200');
      expect(sensorData.icon, Icons.opacity);
      expect(sensorData.color, Colors.purple);
    });

    test('should handle empty unit string', () {
      // Arrange
      final map = {'value': 6.5};

      // Act
      final sensorData = SensorData.fromMap('ph', map);

      // Assert
      expect(sensorData.unit, '');
    });
  });
}
