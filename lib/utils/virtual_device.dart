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
  bool _fansAreActive = false;

  // Configurable sensor ranges
  double tempMin = 22.0;
  double tempMax = 27.0;
  double phMin = 6.5;
  double phMax = 7.5;
  double waterLevelMin = 80.0;
  double waterLevelMax = 100.0;
  double lightMin = 60.0;
  double lightMax = 100.0;
  double tdsMin = 800.0;
  double tdsMax = 1200.0;
  double humidityMin = 50.0;
  double humidityMax = 70.0;

  /// Starts the background simulation loop
  void start() {
    debugPrint("🔌 VIRTUAL DEVICE: Started. Simulating hardware...");

    // Listen for control commands from Firestore
    _listenForControls();

    // Run the simulation loop every 5 seconds (Real-time!)
    _simulationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _simulateSensorReadings();
    });
  }

  /// Stops the simulation
  void stop() {
    _simulationTimer?.cancel();
    debugPrint("🔌 VIRTUAL DEVICE: Stopped.");
  }

  /// Updates the sensor simulation ranges
  void updateRanges({
    required double tempMin,
    required double tempMax,
    required double phMin,
    required double phMax,
    required double waterLevelMin,
    required double waterLevelMax,
    required double lightMin,
    required double lightMax,
    required double tdsMin,
    required double tdsMax,
    required double humidityMin,
    required double humidityMax,
  }) {
    this.tempMin = tempMin;
    this.tempMax = tempMax;
    this.phMin = phMin;
    this.phMax = phMax;
    this.waterLevelMin = waterLevelMin;
    this.waterLevelMax = waterLevelMax;
    this.lightMin = lightMin;
    this.lightMax = lightMax;
    this.tdsMin = tdsMin;
    this.tdsMax = tdsMax;
    this.humidityMin = humidityMin;
    this.humidityMax = humidityMax;
    debugPrint("🔌 VIRTUAL DEVICE: Ranges updated - Temp: $tempMin-$tempMax°C, pH: $phMin-$phMax");
  }

  /// Generates random data and PUSHES it to Firestore
  Future<void> _simulateSensorReadings() async {
    // --- DYNAMIC RANGE ADJUSTMENTS BASED ON ACTUATOR STATES ---

    // Temperature adjustments
    double effectiveTempMin = tempMin;
    double effectiveTempMax = tempMax;

    // FANS ON → Cooling effect (reduce temperature range by 3°C)
    if (_fansAreActive) {
      effectiveTempMin -= 3.0;
      effectiveTempMax -= 3.0;
    }

    // LIGHTS ON → Heating effect (increase temperature range by 2°C)
    if (_lightsAreActive) {
      effectiveTempMin += 2.0;
      effectiveTempMax += 2.0;
    }

    // Water Level adjustments
    double effectiveWaterMin = waterLevelMin;
    double effectiveWaterMax = waterLevelMax;

    // PUMP ON → Increases water level range (shift up by 10%)
    if (_pumpIsActive) {
      effectiveWaterMin = (waterLevelMin + 10.0).clamp(0.0, 100.0);
      effectiveWaterMax = 100.0; // Pump keeps reservoir fuller
    }

    // Generate realistic fluctuating data using adjusted ranges
    double temp = effectiveTempMin + _random.nextDouble() * (effectiveTempMax - effectiveTempMin);
    double ph = phMin + _random.nextDouble() * (phMax - phMin);
    int waterLevel = effectiveWaterMin.toInt() + _random.nextInt((effectiveWaterMax - effectiveWaterMin).toInt());
    int light = lightMin.toInt() + _random.nextInt((lightMax - lightMin).toInt());
    int tds = tdsMin.toInt() + _random.nextInt((tdsMax - tdsMin).toInt());
    int humidity = humidityMin.toInt() + _random.nextInt((humidityMax - humidityMin).toInt());

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
      // FIX: This section was broken in your original file
      await _firestore
          .collection('devices')
          .doc(_deviceId)
          .collection('readings')
          .add(data);

    } catch (e) {
      debugPrint("🔌 VIRTUAL DEVICE: Error sending data: $e");
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
                bool newFansState = actuators['fans'] ?? false; // FIX: Added missing fan logic

                if (newPumpState != _pumpIsActive) {
                  _pumpIsActive = newPumpState;
                  debugPrint("🔌 VIRTUAL DEVICE: 🚿 PUMP is now ${_pumpIsActive ? 'ON' : 'OFF'}");
                }

                if (newLightState != _lightsAreActive) {
                  _lightsAreActive = newLightState;
                  debugPrint("🔌 VIRTUAL DEVICE: 💡 LIGHTS are now ${_lightsAreActive ? 'ON' : 'OFF'}");
                }

                if (newFansState != _fansAreActive) {
                  _fansAreActive = newFansState;
                  debugPrint("🔌 VIRTUAL DEVICE: 🌀 FANS are now ${_fansAreActive ? 'ON' : 'OFF'}");
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