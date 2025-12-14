import 'dart:async';
import 'package:flutter/material.dart';
import '../data/services/firestore_service.dart';
import '../data/services/local_cache_service.dart';

/// Shared ViewModel for actuator controls
/// This ensures pump, lights, and fans state is synchronized across all screens
class ActuatorControlViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final LocalCacheService _cacheService = LocalCacheService.instance;

  bool _isPumpOn = false;
  bool _areLightsOn = false;
  bool _areFansOn = false;
  bool _isInitialized = false;

  StreamSubscription? _actuatorSubscription;

  bool get isPumpOn => _isPumpOn;
  bool get areLightsOn => _areLightsOn;
  bool get areFansOn => _areFansOn;
  bool get isInitialized => _isInitialized;

  ActuatorControlViewModel(this._firestoreService) {
    _initializeActuatorStates();
  }

  /// Initialize actuator states from local cache first, then listen to Firestore
  Future<void> _initializeActuatorStates() async {
    // 1. Load cached states immediately (fast, offline-available)
    final cachedStates = _cacheService.getCachedActuatorStates();
    _isPumpOn = cachedStates['pump'] ?? false;
    _areLightsOn = cachedStates['lights'] ?? false;
    _areFansOn = cachedStates['fans'] ?? false;
    debugPrint('💾 ACTUATORS: Loaded from cache - Pump=$_isPumpOn, Lights=$_areLightsOn, Fans=$_areFansOn');
    notifyListeners();

    // 2. Fetch current state from Firestore (authoritative source)
    try {
      final firestoreStates = await _firestoreService.getActuatorStates();
      if (firestoreStates != null) {
        _isPumpOn = firestoreStates['pump'] ?? false;
        _areLightsOn = firestoreStates['lights'] ?? false;
        _areFansOn = firestoreStates['fans'] ?? false;
        
        // Save to cache for next app launch
        await _cacheService.saveActuatorStates(
          isPumpOn: _isPumpOn,
          areLightsOn: _areLightsOn,
          areFansOn: _areFansOn,
        );
        
        debugPrint('🔥 ACTUATORS: Loaded from Firestore - Pump=$_isPumpOn, Lights=$_areLightsOn, Fans=$_areFansOn');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ ACTUATORS: Failed to load from Firestore, using cached values: $e');
    }

    _isInitialized = true;

    // 3. Start listening for real-time changes
    _listenToActuatorChanges();
  }

  void _listenToActuatorChanges() {
    debugPrint('🔌 Setting up actuator stream listener...');
    _actuatorSubscription = _firestoreService.getActuatorStream().listen(
      (actuators) {
        debugPrint('📡 Received actuator states from Firebase: $actuators');
        _isPumpOn = actuators['pump'] ?? false;
        _areLightsOn = actuators['lights'] ?? false;
        _areFansOn = actuators['fans'] ?? false;
        
        // Update local cache
        _cacheService.saveActuatorStates(
          isPumpOn: _isPumpOn,
          areLightsOn: _areLightsOn,
          areFansOn: _areFansOn,
        );
        
        notifyListeners();
        debugPrint(
          '🔄 Actuator states synced: Pump=$_isPumpOn, Lights=$_areLightsOn, Fans=$_areFansOn',
        );
      },
      onError: (error) {
        debugPrint('❌ Error loading actuator states: $error');
      },
    );
  }

  void togglePump([bool? value]) {
    _isPumpOn = value ?? !_isPumpOn;
    notifyListeners();
    _firestoreService.updateActuator('pump', _isPumpOn);
    _firestoreService.logControlAction('pump', _isPumpOn, source: 'manual');
  }

  void toggleLights([bool? value]) {
    _areLightsOn = value ?? !_areLightsOn;
    notifyListeners();
    _firestoreService.updateActuator('lights', _areLightsOn);
    _firestoreService.logControlAction(
      'lights',
      _areLightsOn,
      source: 'manual',
    );
  }

  void toggleFans([bool? value]) {
    _areFansOn = value ?? !_areFansOn;
    notifyListeners();
    _firestoreService.updateActuator('fans', _areFansOn);
    _firestoreService.logControlAction('fans', _areFansOn, source: 'manual');
  }

  void emergencyStop() {
    _isPumpOn = false;
    _areLightsOn = false;
    _areFansOn = false;
    notifyListeners();
    _firestoreService.updateActuator('pump', false);
    _firestoreService.updateActuator('lights', false);
    _firestoreService.updateActuator('fans', false);
    _firestoreService.logControlAction('pump', false, source: 'emergency');
    _firestoreService.logControlAction('lights', false, source: 'emergency');
    _firestoreService.logControlAction('fans', false, source: 'emergency');
  }

  @override
  void dispose() {
    _actuatorSubscription?.cancel();
    super.dispose();
  }
}
