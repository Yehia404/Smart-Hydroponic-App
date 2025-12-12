import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/alert.dart';
import '../models/scheduled_task.dart';
import 'dart:async';

class SqliteService {
  static const String _dbName = 'hydroponics.db';

  // Table Names
  static const String _alertsTable = 'alerts';
  static const String _tasksTable = 'scheduled_tasks';
  static const String _settingsTable = 'settings';
  static const String _rulesTable = 'automation_rules';

  // Broadcast Stream for alerts
  final _alertStreamController = StreamController<void>.broadcast();

  // Expose the stream to the outside world
  Stream<void> get onAlertsChanged => _alertStreamController.stream;

  // --- Singleton Setup ---
  SqliteService._privateConstructor();
  static final SqliteService instance = SqliteService._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // --- Database Initialization ---
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // --- Table Creation ---
  Future<void> _onCreate(Database db, int version) async {
    // Create Alerts Table
    await db.execute('''
      CREATE TABLE $_alertsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sensorName TEXT NOT NULL,
        message TEXT NOT NULL,
        severity TEXT NOT NULL DEFAULT 'info',
        timestamp TEXT NOT NULL,
        isDismissed INTEGER DEFAULT 0
      )
    ''');

    // Create Scheduled Tasks Table
    await db.execute('''
      CREATE TABLE $_tasksTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        actuatorId TEXT NOT NULL,
        action INTEGER NOT NULL,
        time TEXT NOT NULL
      )
    ''');

    // Create Settings Table with userId
    await db.execute('''
      CREATE TABLE $_settingsTable (
        key TEXT NOT NULL,
        userId TEXT NOT NULL,
        value TEXT,
        PRIMARY KEY (key, userId)
      )
    ''');

    // Create Automation Rules Table with userId
    await db.execute('''
      CREATE TABLE $_rulesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        sensor TEXT NOT NULL,
        condition TEXT NOT NULL,
        threshold REAL NOT NULL,
        actuator TEXT NOT NULL,
        action TEXT NOT NULL,
        isEnabled INTEGER DEFAULT 1
      )
    ''');
  }

  // --- CRUD Operations for Alerts ---
  Future<int> logAlert(Alert alert) async {
    try {
      Database db = await instance.database;
      
      // Remove null id before inserting (let SQLite auto-generate it)
      Map<String, dynamic> data = alert.toMap();
      data.remove('id');
      
      print('📝 Inserting alert into database: ${alert.sensorName}');
      int id = await db.insert(_alertsTable, data);
      print('✅ Alert inserted successfully with ID: $id');

      // Broadcast the signal
      _alertStreamController.add(null);

      return id;
    } catch (e) {
      print('❌ Error inserting alert: $e');
      rethrow;
    }
  }

  /// Fetch ONLY active alerts (where isDismissed is 0)
  Future<List<Alert>> getActiveAlerts() async {
    try {
      Database db = await instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _alertsTable,
        where: 'isDismissed = ?',
        whereArgs: [0],
        orderBy: 'timestamp DESC',
      );
      print('📊 Fetched ${maps.length} active alerts from database');
      return List.generate(maps.length, (i) => Alert.fromMap(maps[i]));
    } catch (e) {
      print('❌ Error fetching active alerts: $e');
      return [];
    }
  }

  /// Retrieves all alerts from the database, ordered by newest first.
  Future<List<Alert>> getAlertHistory() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _alertsTable,
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return Alert.fromMap(maps[i]);
    });
  }

  Future<int> dismissAlert(int id) async {
    Database db = await instance.database;
    int result = await db.update(
      _alertsTable,
      {'isDismissed': 1},
      where: 'id = ?',
      whereArgs: [id],
    );

    // Broadcast update
    _alertStreamController.add(null);
    return result;
  }

  // --- CRUD Operations for ScheduledTasks ---

  /// Inserts a new task into the database.
  Future<int> logTask(ScheduledTask task) async {
    Database db = await instance.database;
    return await db.insert(_tasksTable, task.toMap());
  }

  /// Retrieves all scheduled tasks from the database.
  Future<List<ScheduledTask>> getTasks() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(_tasksTable);

    return List.generate(maps.length, (i) {
      return ScheduledTask.fromMap(maps[i]);
    });
  }

  /// Deletes a specific task by its ID.
  Future<int> deleteTask(int id) async {
    Database db = await instance.database;
    return await db.delete(
      _tasksTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- CRUD Operations for Settings ---
  Future<void> saveSetting(String key, String userId, String value) async {
    Database db = await instance.database;
    await db.insert(
      _settingsTable,
      {'key': key, 'userId': userId, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key, String userId) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      _settingsTable,
      where: 'key = ? AND userId = ?',
      whereArgs: [key, userId],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String;
    }
    return null;
  }

  // --- CRUD Operations for Automation Rules ---
  Future<int> addRule(Map<String, dynamic> rule) async {
    Database db = await instance.database;
    return await db.insert(_rulesTable, rule);
  }

  Future<List<Map<String, dynamic>>> getRules(String userId) async {
    Database db = await instance.database;
    return await db.query(
      _rulesTable,
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<int> deleteRule(int id, String userId) async {
    Database db = await instance.database;
    return await db.delete(
      _rulesTable,
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  Future<int> updateRule(int id, String userId, Map<String, dynamic> rule) async {
    Database db = await instance.database;
    return await db.update(
      _rulesTable,
      rule,
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }
}