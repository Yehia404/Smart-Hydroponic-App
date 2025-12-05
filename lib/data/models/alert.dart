class Alert {
  final int? id; // Nullable for when creating a new alert
  final String sensorName;
  final String message;
  final String severity;
  final DateTime timestamp;
  final bool isDismissed;

  Alert({
    this.id,
    required this.sensorName,
    required this.message,
    this.severity = 'info',
    required this.timestamp,
    this.isDismissed = false,
  });

  // Helper method to convert to a Map for SQLite insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sensorName': sensorName,
      'message': message,
      'severity': severity,
      // Store timestamps as an ISO 8601 string
      'timestamp': timestamp.toString(),
      'isDismissed': isDismissed ? 1 : 0,
    };
  }

  // Helper method to convert from a Map from SQLite
  factory Alert.fromMap(Map<String, dynamic> map) {
    return Alert(
      id: map['id'],
      sensorName: map['sensorName'],
      message: map['message'],
      severity: map['severity'] ?? 'info',
      timestamp: DateTime.parse(map['timestamp']),
      isDismissed: map['isDismissed'] == 1,
    );
  }
}