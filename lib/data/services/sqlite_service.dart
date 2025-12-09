import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/alert.dart';
import '../models/scheduled_task.dart';
import 'dart:async';

class SqliteService {
  static const String _dbName = 'hydroponics.db';
  static const int _dbVersion = 7;

  // Table Names
  static const String _alertsTable = 'alerts';
  static const String _tasksTable = 'scheduled_tasks';
  static const String _settingsTable = 'settings';
  static const String _rulesTable = 'automation_rules';
// 2. Create a Broadcast Stream
  final _alertStreamController = StreamController<void>.broadcast();

  // 3. Expose the stream to the outside world
  Stream<void> get onAlertsChanged => _alertStreamController.stream;
  // --- Singleton Setup ---
  // This ensures we only have one instance of this database service
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
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  
  // --- Database Migration ---
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add isDismissed column to alerts table if upgrading from version 1
      await db.execute('ALTER TABLE $_alertsTable ADD COLUMN isDismissed INTEGER DEFAULT 0');
    }
    if (oldVersion < 3) {
      // Ensure isDismissed column exists (in case of any inconsistency)
      try {
        await db.execute('ALTER TABLE $_alertsTable ADD COLUMN isDismissed INTEGER DEFAULT 0');
      } catch (e) {
        // Column already exists, ignore error
        print('isDismissed column already exists: $e');
      }
    }
    if (oldVersion < 4) {
      // Add severity column for alert categorization
      try {
        await db.execute('ALTER TABLE $_alertsTable ADD COLUMN severity TEXT NOT NULL DEFAULT "info"');
      } catch (e) {
        // Column already exists, ignore error
        print('severity column already exists: $e');
      }
    }
    if (oldVersion < 5) {
      // Add settings and automation_rules tables
      await db.execute('''
        CREATE TABLE $_settingsTable (
          key TEXT PRIMARY KEY,
          value TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE $_rulesTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sensor TEXT NOT NULL,
          condition TEXT NOT NULL,
          threshold REAL NOT NULL,
          actuator TEXT NOT NULL,
          action TEXT NOT NULL,
          isEnabled INTEGER DEFAULT 1
        )
      ''');
    }
    if (oldVersion < 6) {
      // Add userId to settings and automation_rules for user isolation
      await db.execute('DROP TABLE IF EXISTS $_settingsTable');
      await db.execute('DROP TABLE IF EXISTS $_rulesTable');
      
      await db.execute('''
        CREATE TABLE $_settingsTable (
          key TEXT NOT NULL,
          userId TEXT NOT NULL,
          value TEXT,
          PRIMARY KEY (key, userId)
        )
      ''');
      
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
    if (oldVersion < 7) {
      // Force recreation to ensure userId columns exist and are indexed
      await db.execute('DROP TABLE IF EXISTS $_settingsTable');
      await db.execute('DROP TABLE IF EXISTS $_rulesTable');
      
      await db.execute('''
        CREATE TABLE $_settingsTable (
          key TEXT NOT NULL,
          userId TEXT NOT NULL,
          value TEXT,
          PRIMARY KEY (key, userId)
        )
      ''');
      
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
      
      print('✅ DATABASE: Tables recreated with userId support (version 7)');
    }
  }

  // --- Table Creation ---
  // This is called only once when the database is first created
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

      // 4. BROADCAST THE SIGNAL!
      // This tells anyone listening: "New data is here!"
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
        whereArgs: [0], // Only fetch active ones
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

  /// Deletes all alerts from the table.
  /*Future<int> clearAlertHistory() async {
    Database db = await instance.database;
    return await db.delete(_alertsTable);
  }*/

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