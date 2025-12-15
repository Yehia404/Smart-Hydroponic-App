import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/sensor_data.dart';
import '../models/alert.dart';
import '../models/control_log.dart';
import '../services/auth_service.dart';
import '../models/threshold_config.dart';
import 'sqlite_service.dart';
import 'settings_service.dart';
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
      // First try with 'timestamp' field (new format)
      var querySnapshot = await _firestore
          .collection('devices')
          .doc(_deviceId)
          .collection('readings')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startTime),
          )
          .orderBy('timestamp', descending: false)
          .get();

      // If no results, try with 'last_updated' field (old format)
      if (querySnapshot.docs.isEmpty) {
        debugPrint('No data with timestamp field, trying last_updated...');
        querySnapshot = await _firestore
            .collection('devices')
            .doc(_deviceId)
            .collection('readings')
            .where(
              'last_updated',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startTime),
            )
            .orderBy('last_updated', descending: false)
            .get();
      }

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        // Convert Timestamp to DateTime string for compatibility
        // Handle both field names
        if (data['timestamp'] is Timestamp) {
          data['timestamp'] = (data['timestamp'] as Timestamp)
              .toDate()
              .toIso8601String();
        } else if (data['last_updated'] is Timestamp) {
          data['timestamp'] = (data['last_updated'] as Timestamp)
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
    // Rate limit: only check once every 10 seconds
    if (_lastNotificationTime != null &&
        DateTime.now().difference(_lastNotificationTime!).inSeconds < 10) {
      return;
    }

    // Check all sensors for all severity levels
    // No early return - check ALL sensors, not just the first one with an issue

    // 1. Temperature - Check all severity levels
    var tempStatus = ThresholdConfig.instance.checkTemperature(temp);
    if (tempStatus == AlertStatus.criticalHigh) {
      _triggerAlert(
        "🔥 Critical: High Temperature!",
        "Temperature is ${temp.toStringAsFixed(1)}°C. Immediate cooling needed!",
        'critical',
      );
    } else if (tempStatus == AlertStatus.criticalLow) {
      _triggerAlert(
        "❄️ Critical: Low Temperature!",
        "Temperature is ${temp.toStringAsFixed(1)}°C. Immediate heating needed!",
        'critical',
      );
    } else if (tempStatus == AlertStatus.warningHigh) {
      _triggerAlert(
        "🔥 Warning: High Temperature",
        "Temperature is ${temp.toStringAsFixed(1)}°C. Cooling recommended.",
        'warning',
      );
    } else if (tempStatus == AlertStatus.warningLow) {
      _triggerAlert(
        "❄️ Warning: Low Temperature",
        "Temperature is ${temp.toStringAsFixed(1)}°C. Heating recommended.",
        'warning',
      );
    } else if (tempStatus == AlertStatus.info) {
      _triggerAlert(
        "🌡️ Info: Temperature Near Limits",
        "Temperature is ${temp.toStringAsFixed(1)}°C. Monitor closely.",
        'info',
      );
    }

    // 2. Water Level - Check all severity levels
    var waterStatus = ThresholdConfig.instance.checkWaterLevel(water);
    if (waterStatus == AlertStatus.criticalLow) {
      _triggerAlert(
        "💧 Critical: Very Low Water Level!",
        "Water level at ${water.toStringAsFixed(0)}%. Refill immediately!",
        'critical',
      );
    } else if (waterStatus == AlertStatus.warningLow) {
      _triggerAlert(
        "💧 Warning: Low Water Level",
        "Water level at ${water.toStringAsFixed(0)}%. Refill soon.",
        'warning',
      );
    } else if (waterStatus == AlertStatus.info) {
      _triggerAlert(
        "💧 Info: Water Level Getting Low",
        "Water level at ${water.toStringAsFixed(0)}%. Consider refilling.",
        'info',
      );
    }

    // 3. pH Level - Check all severity levels
    var phStatus = ThresholdConfig.instance.checkPh(ph);
    if (phStatus == AlertStatus.criticalHigh) {
      _triggerAlert(
        "🧪 Critical: Very High pH!",
        "pH is ${ph.toStringAsFixed(1)}. Add pH Down immediately!",
        'critical',
      );
    } else if (phStatus == AlertStatus.criticalLow) {
      _triggerAlert(
        "🧪 Critical: Very Low pH!",
        "pH is ${ph.toStringAsFixed(1)}. Add pH Up immediately!",
        'critical',
      );
    } else if (phStatus == AlertStatus.warningHigh) {
      _triggerAlert(
        "🧪 Warning: High pH",
        "pH is ${ph.toStringAsFixed(1)}. Add pH Down.",
        'warning',
      );
    } else if (phStatus == AlertStatus.warningLow) {
      _triggerAlert(
        "🧪 Warning: Low pH",
        "pH is ${ph.toStringAsFixed(1)}. Add pH Up.",
        'warning',
      );
    } else if (phStatus == AlertStatus.info) {
      _triggerAlert(
        "🧪 Info: pH Near Limits",
        "pH is ${ph.toStringAsFixed(1)}. Monitor closely.",
        'info',
      );
    }

    // 4. TDS - Check all severity levels
    var tdsStatus = ThresholdConfig.instance.checkTds(tds);
    if (tdsStatus == AlertStatus.criticalHigh) {
      _triggerAlert(
        "⚠️ Critical: Very High Nutrients!",
        "TDS is ${tds.toStringAsFixed(0)}ppm. Flush system immediately!",
        'critical',
      );
    } else if (tdsStatus == AlertStatus.criticalLow) {
      _triggerAlert(
        "⚠️ Critical: Very Low Nutrients!",
        "TDS is ${tds.toStringAsFixed(0)}ppm. Add nutrients immediately!",
        'critical',
      );
    } else if (tdsStatus == AlertStatus.warningHigh) {
      _triggerAlert(
        "⚠️ Warning: High Nutrients",
        "TDS is ${tds.toStringAsFixed(0)}ppm. Consider flushing.",
        'warning',
      );
    } else if (tdsStatus == AlertStatus.warningLow) {
      _triggerAlert(
        "⚠️ Warning: Low Nutrients",
        "TDS is ${tds.toStringAsFixed(0)}ppm. Add nutrients.",
        'warning',
      );
    } else if (tdsStatus == AlertStatus.info) {
      _triggerAlert(
        "⚠️ Info: Nutrients Near Limits",
        "TDS is ${tds.toStringAsFixed(0)}ppm. Monitor closely.",
        'info',
      );
    }

    // 5. Light - Check all severity levels
    var lightStatus = ThresholdConfig.instance.checkLight(light);
    if (lightStatus == AlertStatus.criticalLow) {
      _triggerAlert(
        "💡 Critical: Very Low Light!",
        "Light intensity is ${light.toStringAsFixed(0)}%. Check bulbs immediately!",
        'critical',
      );
    } else if (lightStatus == AlertStatus.warningLow) {
      _triggerAlert(
        "💡 Warning: Low Light",
        "Light intensity is ${light.toStringAsFixed(0)}%. Check bulbs.",
        'warning',
      );
    } else if (lightStatus == AlertStatus.info) {
      _triggerAlert(
        "💡 Info: Light Getting Low",
        "Light intensity is ${light.toStringAsFixed(0)}%. Monitor bulbs.",
        'info',
      );
    }

    // 6. Humidity - Check all severity levels
    var humidityStatus = ThresholdConfig.instance.checkHumidity(humidity);
    if (humidityStatus == AlertStatus.criticalHigh) {
      _triggerAlert(
        "💨 Critical: Very High Humidity!",
        "Humidity is ${humidity.toStringAsFixed(0)}%. Increase ventilation immediately!",
        'critical',
      );
    } else if (humidityStatus == AlertStatus.criticalLow) {
      _triggerAlert(
        "💨 Critical: Very Low Humidity!",
        "Humidity is ${humidity.toStringAsFixed(0)}%. Increase moisture immediately!",
        'critical',
      );
    } else if (humidityStatus == AlertStatus.warningHigh) {
      _triggerAlert(
        "💨 Warning: High Humidity",
        "Humidity is ${humidity.toStringAsFixed(0)}%. Increase ventilation.",
        'warning',
      );
    } else if (humidityStatus == AlertStatus.warningLow) {
      _triggerAlert(
        "💨 Warning: Low Humidity",
        "Humidity is ${humidity.toStringAsFixed(0)}%. Increase moisture.",
        'warning',
      );
    } else if (humidityStatus == AlertStatus.info) {
      _triggerAlert(
        "💨 Info: Humidity Near Limits",
        "Humidity is ${humidity.toStringAsFixed(0)}%. Monitor closely.",
        'info',
      );
    }

    // Update last notification time after checking all sensors
    _lastNotificationTime = DateTime.now();
  }

  void _triggerAlert(String title, String body, String severity) async {
    // Don't send notifications if no user is logged in
    if (AuthService.instance.currentUser == null) {
      debugPrint('⏭️ ALERT: Skipping notification - no user logged in');
      return;
    }
    
    // Check user notification preferences
    final settingsService = SettingsService.instance;
    bool shouldSend = false;
    
    switch (severity.toLowerCase()) {
      case 'critical':
        shouldSend = await settingsService.getNotificationPreference('critical', defaultValue: true);
        break;
      case 'warning':
        shouldSend = await settingsService.getNotificationPreference('warning', defaultValue: true);
        break;
      case 'info':
        shouldSend = await settingsService.getNotificationPreference('info', defaultValue: true);
        break;
    }
    
    if (!shouldSend) {
      debugPrint('⏭️ ALERT: User disabled $severity notifications');
      return;
    }

    // Create and log alert to database
    final newAlert = Alert(
      sensorName: title,
      message: body,
      severity: severity.toLowerCase(),
      timestamp: DateTime.now(),
    );

    int alertId = await SqliteService.instance.logAlert(newAlert);
    
    // Send push notification
    try {
      await NotificationService.instance.showNotification(
        id: alertId,
        title: title,
        body: body,
        severity: severity,
      );
      debugPrint("✅ ALERT SENT: $title (Severity: $severity)");
    } catch (e) {
      debugPrint("❌ ALERT FAILED: $title - Error: $e");
    }
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
