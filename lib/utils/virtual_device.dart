import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Simulates the physical hardware (ESP32/Arduino).
/// It pushes random sensor data to cloud and listens for control commands.
class VirtualDevice {
  // ---------------- CONFIGURATION ----------------
  final String _deviceId = 'hydroponic_system';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // -----------------------------------------------

  Timer? _simulationTimer;
  final Random _random = Random();

  // Internal state of our "Hardware"
  bool _pumpIsActive = false;
  bool _lightsAreActive = false;

  /// Starts the background simulation loop
  void start() {
    debugPrint("🔌 VIRTUAL DEVICE: Started. Simulating hardware...");

    // Listen for control commands from Firestore
    _listenForControls();

    // Run the simulation loop every 5 seconds (Real-time!)
    _simulationTimer = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) async {
      await _simulateSensorReadings();
    });
  }

  /// Stops the simulation
  void stop() {
    _simulationTimer?.cancel();
    debugPrint("🔌 VIRTUAL DEVICE: Stopped.");
  }

  /// Generates random data and PUSHES it to Firestore
  Future<void> _simulateSensorReadings() async {
    // Generate realistic fluctuating data
    double temp = 22.0 + _random.nextDouble() * 5; // 22-27°C
    double ph = 6.5 + _random.nextDouble() * 1.0; // 6.5-7.5
    int waterLevel = 80 + _random.nextInt(20); // 80-100%
    int light = 60 + _random.nextInt(40); // 60-100%
    int tds = 800 + _random.nextInt(400); // 800-1200 ppm
    int humidity = 50 + _random.nextInt(20); // 50-70%

    try {
      final data = {
        'temperature': double.parse(temp.toStringAsFixed(1)),
        'ph': double.parse(ph.toStringAsFixed(1)),
        'water_level': waterLevel,
        'light_intensity': light,
        'tds': tds,
        'humidity': humidity,
        'last_updated': FieldValue.serverTimestamp(),
      };

      // 1. Update Real-time Status
      await _firestore
          .collection('devices')
          .doc(_deviceId)
          .set(data, SetOptions(merge: true));

      // 2. Add to History (Readings Collection)
      await _firestore
          .collection('devices')
          .doc(_deviceId)
          .collection('readings')
          .add({...data, 'timestamp': FieldValue.serverTimestamp()});

      debugPrint(
        "🔌 VIRTUAL DEVICE: 📤 Data Sent (Temp: ${temp.toStringAsFixed(1)}°C)",
      );
    } catch (e) {
      debugPrint("🔌 VIRTUAL DEVICE: ❌ Error sending data: $e");
    }
  }

  /// Listens to Firestore for control commands
  void _listenForControls() {
    _firestore
        .collection('devices')
        .doc(_deviceId)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists && snapshot.data() != null) {
              final data = snapshot.data()!;
              final actuators = data['actuators'] as Map<String, dynamic>?;

              if (actuators != null) {
                bool newPumpState = actuators['pump'] ?? false;
                bool newLightState = actuators['lights'] ?? false;

                if (newPumpState != _pumpIsActive) {
                  _pumpIsActive = newPumpState;
                  debugPrint(
                    "🔌 VIRTUAL DEVICE: 🚿 PUMP is now ${_pumpIsActive ? 'ON' : 'OFF'}",
                  );
                }

                if (newLightState != _lightsAreActive) {
                  _lightsAreActive = newLightState;
                  debugPrint(
                    "🔌 VIRTUAL DEVICE: 💡 LIGHTS are now ${_lightsAreActive ? 'ON' : 'OFF'}",
                  );
                }
              }
            }
          },
          onError: (e) {
            debugPrint("🔌 VIRTUAL DEVICE: Error listening controls: $e");
          },
        );
  }
}
