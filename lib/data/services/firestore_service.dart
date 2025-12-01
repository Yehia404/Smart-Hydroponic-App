import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/sensor_data.dart';
import '../models/control_log.dart';
class FirestoreService {
  // Singleton Setup
  FirestoreService._privateConstructor() {
    _listenToAuthChanges();
  }
  static final FirestoreService instance =
      FirestoreService._privateConstructor();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _deviceId = 'hydroponic_system'; // Single device for now

 
  void _listenToAuthChanges() {
    //placeholder for now
    return;
  }
   Stream<List<SensorData>> getSensorStream() {
    return _firestore
        .collection('devices')
        .doc(_deviceId)
        .snapshots(
          includeMetadataChanges: true,
        ) // Listen for metadata changes (cache vs server)
        .where(
          (snapshot) => !snapshot.metadata.isFromCache,
        ) // Ignore local cache
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) {
            return [];
          }

          final data = snapshot.data()!;
          List<SensorData> sensorList = [];

          // Parse sensor data
          double temp = (data['temperature'] ?? 0).toDouble();
          double ph = (data['ph'] ?? 0).toDouble();
          double water = (data['water_level'] ?? 0).toDouble();
          double light = (data['light_intensity'] ?? 0).toDouble();
          double tds = (data['tds'] ?? 0).toDouble();
          double humidity = (data['humidity'] ?? 0).toDouble();

          sensorList.add(
            SensorData.fromMap('temperature', {'value': temp, 'unit': '°C'}),
          );
          sensorList.add(SensorData.fromMap('ph', {'value': ph, 'unit': ''}));
          sensorList.add(
            SensorData.fromMap('water_level', {'value': water, 'unit': '%'}),
          );
          sensorList.add(
            SensorData.fromMap('light_intensity', {
              'value': light,
              'unit': '%',
            }),
          );
          sensorList.add(
            SensorData.fromMap('tds', {'value': tds, 'unit': 'ppm'}),
          );
          sensorList.add(
            SensorData.fromMap('humidity', {'value': humidity, 'unit': '%'}),
          );

          // Check alerts
          

          return sensorList;
        });
  }
    /// Provides a stream of actuator states from Firestore
  Stream<Map<String, bool>> getActuatorStream() {
    return _firestore.collection('devices').doc(_deviceId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists || snapshot.data() == null) {
        return {'pump': false, 'lights': false, 'fans': false};
      }

      final data = snapshot.data()!;
      final actuators = data['actuators'] as Map<String, dynamic>? ?? {};

      return {
        'pump': actuators['pump'] == true,
        'lights': actuators['lights'] == true,
        'fans': actuators['fans'] == true,
      };
    });
  }
   /// Updates an actuator state in Firestore
  Future<void> updateActuator(String actuatorId, bool isOn) async {
    try {
      await _firestore.collection('devices').doc(_deviceId).update({
        'actuators.$actuatorId': isOn,
      });
      debugPrint('Actuator $actuatorId updated to $isOn');
    } catch (e) {
      debugPrint('Error updating actuator: $e');
      throw e;
    }
  }
 /// Logs a control action to Firestore for history tracking
  Future<void> logControlAction(
    String actuatorId,
    bool action, {
    String source = 'manual',
  }) async {
    try {
      final log = ControlLog(
        actuatorId: actuatorId,
        action: action,
        timestamp: DateTime.now(),
        source: source,
      );

      await _firestore
          .collection('devices')
          .doc(_deviceId)
          .collection('control_logs')
          .add(log.toMap());

      debugPrint('Control log added: $actuatorId = $action (source: $source)');
    } catch (e) {
      debugPrint('Error logging control action: $e');
      // Don't throw - logging failures shouldn't break control functionality
    }
  }
  /// Provides a stream of control history logs
  Stream<List<ControlLog>> getControlHistoryStream({
    int limitCount = 50,
    String? actuatorFilter,
  }) {
    Query query = _firestore
        .collection('devices')
        .doc(_deviceId)
        .collection('control_logs')
        .orderBy('timestamp', descending: true)
        .limit(limitCount);

    // Apply actuator filter if provided
    if (actuatorFilter != null && actuatorFilter.isNotEmpty) {
      query = query.where('actuatorId', isEqualTo: actuatorFilter);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ControlLog.fromFirestore(doc)).toList();
    });
  }

  }