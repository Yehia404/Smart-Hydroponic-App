import 'sqlite_service.dart';
import '../services/auth_service.dart';

class SettingsService {
  // Singleton
  static final SettingsService instance = SettingsService._internal();
  SettingsService._internal();

  final SqliteService _db = SqliteService.instance;
  final AuthService _authService = AuthService.instance;

  String? get _currentUserId => _authService.currentUser?.uid;

  // --- Thresholds ---
  Future<void> saveThreshold(String sensor, String type, double value) async {
    if (_currentUserId == null) {
      throw Exception('No user logged in');
    }
    print('💾 SETTINGS: Saving threshold ${sensor}_$type = $value for userId: $_currentUserId');
    await _db.saveSetting('${sensor}_$type', _currentUserId!, value.toString());
  }

  Future<double?> getThreshold(String sensor, String type) async {
    if (_currentUserId == null) {
      print('⚠️ SETTINGS: No user logged in, returning null for ${sensor}_$type');
      return null;
    }
    print('🔍 SETTINGS: Getting threshold ${sensor}_$type for userId: $_currentUserId');
    final val = await _db.getSetting('${sensor}_$type', _currentUserId!);
    print('🔍 SETTINGS: Retrieved value: $val');
    return val != null ? double.tryParse(val) : null;
  }

  // --- Notifications ---
  Future<void> saveNotificationPreference(String key, bool enabled) async {
    if (_currentUserId == null) {
      throw Exception('No user logged in');
    }
    await _db.saveSetting('notif_$key', _currentUserId!, enabled.toString());
  }

  Future<bool> getNotificationPreference(String key, {bool defaultValue = true}) async {
    if (_currentUserId == null) return defaultValue;
    final val = await _db.getSetting('notif_$key', _currentUserId!);
    return val != null ? val == 'true' : defaultValue;
  }

  // --- Automation Rules ---
  Future<int> addRule(String sensor, String condition, double threshold, String actuator, String action) async {
    if (_currentUserId == null) {
      throw Exception('No user logged in');
    }
    print('💾 SETTINGS: Adding rule for userId: $_currentUserId');
    return await _db.addRule({
      'userId': _currentUserId!,
      'sensor': sensor,
      'condition': condition,
      'threshold': threshold,
      'actuator': actuator,
      'action': action,
      'isEnabled': 1,
    });
  }

  Future<List<Map<String, dynamic>>> getRules() async {
    if (_currentUserId == null) {
      print('⚠️ SETTINGS: No user logged in, returning empty rules list');
      return [];
    }
    print('🔍 SETTINGS: Getting automation rules for userId: $_currentUserId');
    final rules = await _db.getRules(_currentUserId!);
    print('🔍 SETTINGS: Found ${rules.length} rules');
    return rules;
  }

  Future<void> deleteRule(int id) async {
    if (_currentUserId == null) {
      throw Exception('No user logged in');
    }
    await _db.deleteRule(id, _currentUserId!);
  }

  Future<void> toggleRule(int id, bool isEnabled) async {
    if (_currentUserId == null) {
      throw Exception('No user logged in');
    }
    await _db.updateRule(id, _currentUserId!, {'isEnabled': isEnabled ? 1 : 0});
  }
}
