import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class representing a control action log entry
/// Records manual actuator control actions for history tracking
class ControlLog {
  final String? id; // Firestore document ID
  final String actuatorId; // pump, lights, or fans
  final bool action; // true = ON, false = OFF
  final DateTime timestamp;
  final String source; // 'manual', 'scheduled', 'emergency'

  ControlLog({
    this.id,
    required this.actuatorId,
    required this.action,
    required this.timestamp,
    this.source = 'manual',
  });

  /// Create a ControlLog from Firestore document
  factory ControlLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ControlLog(
      id: doc.id,
      actuatorId: data['actuatorId'] ?? '',
      action: data['action'] ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      source: data['source'] ?? 'manual',
    );
  }

  /// Convert ControlLog to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'actuatorId': actuatorId,
      'action': action,
      'timestamp': Timestamp.fromDate(timestamp),
      'source': source,
    };
  }

  /// Get a display-friendly actuator name
  String get actuatorDisplayName {
    switch (actuatorId) {
      case 'pump':
        return 'Water Pump';
      case 'lights':
        return 'Grow Lights';
      case 'fans':
        return 'Cooling Fans';
      default:
        return actuatorId;
    }
  }

  /// Get a display-friendly action text
  String get actionText => action ? 'ON' : 'OFF';
}
