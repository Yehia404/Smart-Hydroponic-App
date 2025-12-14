import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/sensor_data.dart';
import '../models/alert.dart';
import '../models/control_log.dart';
import '../services/auth_service.dart';
import '../models/threshold_config.dart';
import 'sqlite_service.dart';
import 'notification_service.dart';
import '../../viewmodels/analytics_history_viewmodel.dart'; 

class FirestoreService {
  // Singleton Setup
  FirestoreService._privateConstructor() {
    _listenToAuthChanges();
  }
  static final FirestoreService instance =
      FirestoreService._privateConstructor();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _deviceId = 'hydroponic_system'; // Single device for now

  // Keep track of last alert time to avoid spamming notifications (per session)
  DateTime? _lastNotificationTime;
  StreamSubscription? _authSubscription;

  void _listenToAuthChanges() {
    _authSubscription = AuthService.instance.authStateChanges.listen((user) {
      // Reset notification timeout when auth state changes (login/logout)
      _lastNotificationTime = null;
      debugPrint('🔄 FIRESTORE: Reset notification timeout for new session');
    });
  }

  /// Provides a stream of sensor data from Firestore
  /// Only returns data confirmed by the server (ignores local optimistic updates)
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
          _checkAlerts(temp, water, ph, light, tds, humidity);

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

  /// Gets the current actuator states from Firestore (one-time fetch)
  Future<Map<String, bool>?> getActuatorStates() async {
    try {
      final snapshot = await _firestore.collection('devices').doc(_deviceId).get();
      
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
    } catch (e) {
      debugPrint('Error fetching actuator states: $e');
      return null;
    }
  }

  /// Gets the current sensor readings from Firestore (one-time fetch)
  Future<Map<String, dynamic>?> getSensorReadings() async {
    try {
      final snapshot = await _firestore.collection('devices').doc(_deviceId).get();
      
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      final data = snapshot.data()!;
      return {
        'temperature': data['temperature'] ?? 0.0,
        'ph': data['ph'] ?? 0.0,
        'water_level': data['water_level'] ?? 0,
        'light_intensity': data['light_intensity'] ?? 0,
        'tds': data['tds'] ?? 0,
        'humidity': data['humidity'] ?? 0,
      };
    } catch (e) {
      debugPrint('Error fetching sensor readings: $e');
      return null;
    }
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

  /// Fetches control history logs from Firestore
  Future<List<ControlLog>> fetchControlHistory({
    int limitCount = 100,
    String? actuatorFilter,
  }) async {
    try {
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

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => ControlLog.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching control history: $e');
      return [];
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

  /// Fetches historical data from Firestore subcollection 'readings'
  Future<List<Map<String, dynamic>>> fetchHistory(TimeRange range) async {
    DateTime now = DateTime.now();
    DateTime startTime;

    switch (range) {
      case TimeRange.hour:
        startTime = now.subtract(const Duration(hours: 1));
        break;
      case TimeRange.day:
        startTime = now.subtract(const Duration(days: 1));
        break;
      case TimeRange.week:
        startTime = now.subtract(const Duration(days: 7));
        break;
      case TimeRange.month:
        startTime = now.subtract(const Duration(days: 30));
        break;
    }

    try {
      final querySnapshot = await _firestore
          .collection('devices')
          .doc(_deviceId)
          .collection('readings')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startTime),
          )
          .orderBy('timestamp', descending: false)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        // Convert Timestamp to DateTime string for compatibility
        if (data['timestamp'] is Timestamp) {
          data['timestamp'] = (data['timestamp'] as Timestamp)
              .toDate()
              .toIso8601String();
        }
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error fetching history: $e');
      return [];
    }
  }

  // --- Alert Logic ---
  void _checkAlerts(
    double temp,
    double water,
    double ph,
    double light,
    double tds,
    double humidity,
  ) {
    if (_lastNotificationTime != null &&
        DateTime.now().difference(_lastNotificationTime!).inSeconds < 10) {
      return;
    }

    bool alertTriggered = false;

    // 1. Temperature - Check for all severity levels
    var tempStatus = ThresholdConfig.instance.checkTemperature(temp);
    if (tempStatus != AlertStatus.normal) {
      String severity = _getSeverityFromStatus(tempStatus);
      String message = '';
      
      if (tempStatus == AlertStatus.criticalHigh) {
        message = "🔥 CRITICAL: Temp is ${temp.toStringAsFixed(1)}°C. Immediate cooling needed!";
      } else if (tempStatus == AlertStatus.warningHigh) {
        message = "🔥 High Temp Alert: ${temp.toStringAsFixed(1)}°C. Cooling needed.";
      } else if (tempStatus == AlertStatus.criticalLow) {
        message = "❄️ CRITICAL: Temp is ${temp.toStringAsFixed(1)}°C. Immediate heating needed!";
      } else if (tempStatus == AlertStatus.warningLow) {
        message = "❄️ Low Temp Alert: ${temp.toStringAsFixed(1)}°C. Heating needed.";
      } else if (tempStatus == AlertStatus.info) {
        message = "🌡️ Temperature approaching limits: ${temp.toStringAsFixed(1)}°C.";
      }
      
      _triggerAlert("Temperature Alert", message, severity);
      alertTriggered = true;
    }

    // 2. Water Level - Check for all severity levels
    if (!alertTriggered) {
      var waterStatus = ThresholdConfig.instance.checkWaterLevel(water);
      if (waterStatus != AlertStatus.normal) {
        String severity = _getSeverityFromStatus(waterStatus);
        String message = '';
        
        if (waterStatus == AlertStatus.criticalLow) {
          message = "💧 CRITICAL: Reservoir at ${water.toStringAsFixed(0)}%. Refill immediately!";
        } else if (waterStatus == AlertStatus.warningLow) {
          message = "💧 Low Water Level: ${water.toStringAsFixed(0)}%. Refill soon.";
        } else if (waterStatus == AlertStatus.info) {
          message = "💧 Water level getting low: ${water.toStringAsFixed(0)}%.";
        }
        
        _triggerAlert("Water Level Alert", message, severity);
        alertTriggered = true;
      }
    }

    // 3. pH Level - Check for all severity levels
    if (!alertTriggered) {
      var phStatus = ThresholdConfig.instance.checkPh(ph);
      if (phStatus != AlertStatus.normal) {
        String severity = _getSeverityFromStatus(phStatus);
        String message = '';
        
        if (phStatus == AlertStatus.criticalHigh) {
          message = "🧪 CRITICAL: pH is ${ph.toStringAsFixed(1)}. Very alkaline - add pH Down now!";
        } else if (phStatus == AlertStatus.warningHigh) {
          message = "🧪 High pH Alert: ${ph.toStringAsFixed(1)}. Add pH Down.";
        } else if (phStatus == AlertStatus.criticalLow) {
          message = "🧪 CRITICAL: pH is ${ph.toStringAsFixed(1)}. Very acidic - add pH Up now!";
        } else if (phStatus == AlertStatus.warningLow) {
          message = "🧪 Low pH Alert: ${ph.toStringAsFixed(1)}. Add pH Up.";
        } else if (phStatus == AlertStatus.info) {
          message = "🧪 pH approaching limits: ${ph.toStringAsFixed(1)}.";
        }
        
        _triggerAlert("pH Alert", message, severity);
        alertTriggered = true;
      }
    }

    // 4. TDS - Check for all severity levels
    if (!alertTriggered) {
      var tdsStatus = ThresholdConfig.instance.checkTds(tds);
      if (tdsStatus != AlertStatus.normal) {
        String severity = _getSeverityFromStatus(tdsStatus);
        String message = '';
        
        if (tdsStatus == AlertStatus.criticalHigh) {
          message = "⚠️ CRITICAL: TDS is ${tds.toStringAsFixed(0)}ppm. Flush system immediately!";
        } else if (tdsStatus == AlertStatus.warningHigh) {
          message = "⚠️ High Nutrient Alert: ${tds.toStringAsFixed(0)}ppm. Consider flushing.";
        } else if (tdsStatus == AlertStatus.criticalLow) {
          message = "⚠️ CRITICAL: TDS is ${tds.toStringAsFixed(0)}ppm. Add nutrients immediately!";
        } else if (tdsStatus == AlertStatus.warningLow) {
          message = "⚠️ Low Nutrient Alert: ${tds.toStringAsFixed(0)}ppm. Add nutrients.";
        } else if (tdsStatus == AlertStatus.info) {
          message = "⚠️ Nutrients approaching limits: ${tds.toStringAsFixed(0)}ppm.";
        }
        
        _triggerAlert("Nutrient Alert", message, severity);
        alertTriggered = true;
      }
    }

    // 5. Light - Check for all severity levels
    if (!alertTriggered) {
      var lightStatus = ThresholdConfig.instance.checkLight(light);
      if (lightStatus != AlertStatus.normal) {
        String severity = _getSeverityFromStatus(lightStatus);
        String message = '';
        
        if (lightStatus == AlertStatus.criticalLow) {
          message = "💡 CRITICAL: Light intensity is ${light.toStringAsFixed(0)}%. Check lighting system!";
        } else if (lightStatus == AlertStatus.warningLow) {
          message = "💡 Low Light Alert: ${light.toStringAsFixed(0)}%. Check bulbs.";
        } else if (lightStatus == AlertStatus.info) {
          message = "💡 Light intensity getting low: ${light.toStringAsFixed(0)}%.";
        }
        
        _triggerAlert("Light Alert", message, severity);
        alertTriggered = true;
      }
    }

    // 6. Humidity - Check for all severity levels
    if (!alertTriggered) {
      var humidityStatus = ThresholdConfig.instance.checkHumidity(humidity);
      if (humidityStatus != AlertStatus.normal) {
        String severity = _getSeverityFromStatus(humidityStatus);
        String message = '';
        
        if (humidityStatus == AlertStatus.criticalHigh) {
          message = "💨 CRITICAL: Humidity is ${humidity.toStringAsFixed(0)}%. Increase ventilation immediately!";
        } else if (humidityStatus == AlertStatus.warningHigh) {
          message = "💨 High Humidity Alert: ${humidity.toStringAsFixed(0)}%. Increase ventilation.";
        } else if (humidityStatus == AlertStatus.criticalLow) {
          message = "💨 CRITICAL: Humidity is ${humidity.toStringAsFixed(0)}%. Increase moisture immediately!";
        } else if (humidityStatus == AlertStatus.warningLow) {
          message = "💨 Low Humidity Alert: ${humidity.toStringAsFixed(0)}%. Increase moisture.";
        } else if (humidityStatus == AlertStatus.info) {
          message = "💨 Humidity approaching limits: ${humidity.toStringAsFixed(0)}%.";
        }
        
        _triggerAlert("Humidity Alert", message, severity);
        alertTriggered = true;
      }
    }
  }

  String _getSeverityFromStatus(AlertStatus status) {
    if (status == AlertStatus.criticalHigh || status == AlertStatus.criticalLow) {
      return 'critical';
    } else if (status == AlertStatus.warningHigh || status == AlertStatus.warningLow) {
      return 'warning';
    } else if (status == AlertStatus.info) {
      return 'info';
    }
    return 'info';
  }

  void _triggerAlert(String title, String body, String severity) async {
    // Don't send notifications if no user is logged in
    if (AuthService.instance.currentUser == null) {
      debugPrint('⏭️ ALERT: Skipping notification - no user logged in');
      return;
    }
    
    

    final newAlert = Alert(
      sensorName: title,
      message: body,
      severity: severity,
      timestamp: DateTime.now(),
    );

    int alertId = await SqliteService.instance.logAlert(newAlert);
    
    // Trigger actual phone notification
    bool isCritical = severity == 'critical';
    await NotificationService.instance.showNotification(
      id: alertId,
      title: title,
      body: body,
      isCritical: isCritical,
    );
    
    _lastNotificationTime = DateTime.now();
    debugPrint("ALERT SENT: $title (Severity: $severity)");
  }

  // --- User Profile Management ---
  
  /// Creates a user profile document in Firestore
  Future<void> createUserProfile({
    required String userId,
    required String name,
    required String email,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ User profile created for: $userId');
    } catch (e) {
      debugPrint('❌ Error creating user profile: $e');
      throw e;
    }
  }

  /// Gets a user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting user profile: $e');
      return null;
    }
  }

  /// Updates a user's name in Firestore
  Future<void> updateUserName(String userId, String newName) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'name': newName,
      });
      debugPrint('✅ User name updated for: $userId');
    } catch (e) {
      debugPrint('❌ Error updating user name: $e');
      throw e;
    }
  }
}
