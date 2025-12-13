import 'package:flutter/material.dart';
import 'dart:async';
import '../data/services/settings_service.dart';
import '../data/services/auth_service.dart';
import 'home_overview_viewmodel.dart';

class AutomationRulesViewModel extends ChangeNotifier {
  final SettingsService _settingsService = SettingsService.instance;
  final AuthService _authService = AuthService.instance;
  final HomeOverviewViewModel _homeViewModel;
  StreamSubscription? _authSubscription;
  
  bool _isLoading = false;
  List<Map<String, dynamic>> _rules = [];

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get rules => _rules;
  bool get isAutoMode => _homeViewModel.currentMode == 'automatic';

  AutomationRulesViewModel(this._homeViewModel) {
    _homeViewModel.addListener(_onModeChanged);
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authSubscription = _authService.authStateChanges.listen((user) {
      debugPrint('🔄 RULES: Auth state changed, user: ${user?.uid}');
      if (user != null) {
        // User logged in, reload their data
        _loadRules();
      } else {
        // User logged out, clear rules
        _rules = [];
        notifyListeners();
      }
    });
  }

  /// Reload rules from database
  Future<void> reload() async {
    await _loadRules();
  }

  void _onModeChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _homeViewModel.removeListener(_onModeChanged);
    super.dispose();
  }

  Future<void> _loadRules() async {
    _isLoading = true;
    notifyListeners();

    try {
      _rules = await _settingsService.getRules();
      debugPrint('Loaded ${_rules.length} automation rules');
    } catch (e) {
      debugPrint('Error loading automation rules: $e');
      _rules = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addRule(String sensor, String condition, double threshold, String actuator, String action) async {
    try {
      await _settingsService.addRule(sensor, condition, threshold, actuator, action);
      debugPrint('Rule added successfully');
      await _loadRules();
    } catch (e) {
      debugPrint('Error adding rule: $e');
      rethrow;
    }
  }

  Future<void> deleteRule(int id) async {
    await _settingsService.deleteRule(id);
    await _loadRules();
  }

  Future<void> toggleRule(int id, bool isEnabled) async {
    await _settingsService.toggleRule(id, isEnabled);
    await _loadRules();
  }
}
