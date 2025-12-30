import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize FFI loader for Windows
  static void setupDatabaseFactory() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  String _getDatabasePath() {
    // Finds the directory where the .exe is currently running
    // This is CRITICAL for USB portability
    try {
      final exePath = File(Platform.resolvedExecutable).parent.path;
      return p.join(exePath, 'amanda_data.db');
    } catch (e) {
      // Fallback for development (e.g., flutter run)
      return p.join(Directory.current.path, 'amanda_data.db');
    }
  }

  Future<Database> _initDatabase() async {
    final String path = _getDatabasePath();
    return await openDatabase(
      path,
      version: 4, // Bump version
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Handle migration
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        description TEXT,
        isCompleted INTEGER,
        priority INTEGER,
        dueDate TEXT
      )
    ''');
    await _createEventsTable(db);
    await _createDashboardTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createEventsTable(db);
    }
    if (oldVersion < 3) {
      await _createDashboardTables(db);
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE weekly_notes(
          id TEXT PRIMARY KEY,
          content TEXT
        )
      ''');
    }
  }

  Future<void> _createEventsTable(Database db) async {
    await db.execute('''
      CREATE TABLE events(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        description TEXT,
        date TEXT
      )
    ''');
  }

  Future<void> _createDashboardTables(Database db) async {
    await db.execute('''
      CREATE TABLE daily_notes(
        date TEXT PRIMARY KEY,
        content TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE dashboard_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT,
        content TEXT,
        isCompleted INTEGER,
        date TEXT,
        position INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE weekly_notes(
        id TEXT PRIMARY KEY,
        content TEXT
      )
    ''');
  }

  // CRUD Operations
  Future<int> insertTask(Map<String, dynamic> task) async {
    final Database db = await database;
    return await db.insert('tasks', task);
  }

  Future<List<Map<String, dynamic>>> getTasks() async {
    final Database db = await database;
    return await db.query('tasks', orderBy: 'priority DESC, dueDate ASC');
  }

  Future<int> updateTask(Map<String, dynamic> task) async {
    final Database db = await database;
    return await db.update(
      'tasks',
      task,
      where: 'id = ?',
      whereArgs: [task['id']],
    );
  }

  Future<int> deleteTask(int id) async {
    final Database db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // Event Operations
  Future<int> insertEvent(Map<String, dynamic> event) async {
    final Database db = await database;
    return await db.insert('events', event);
  }

  Future<List<Map<String, dynamic>>> getEvents() async {
    final Database db = await database;
    return await db.query('events', orderBy: 'date ASC');
  }

  Future<int> deleteEvent(int id) async {
    final Database db = await database;
    return await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  // Dashboard Operations

  // Notes
  Future<void> saveDailyNote(String date, String content) async {
    final Database db = await database;
    await db.insert('daily_notes', {
      'date': date,
      'content': content,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getDailyNote(String date) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_notes',
      where: 'date = ?',
      whereArgs: [date],
    );
    if (maps.isNotEmpty) {
      return maps.first['content'] as String;
    }
    return null;
  }

  // Weekly Notes
  Future<void> saveWeeklyNote(String id, String content) async {
    final Database db = await database;
    await db.insert('weekly_notes', {
      'id': id,
      'content': content,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getWeeklyNote(String id) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'weekly_notes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return maps.first['content'] as String;
    }
    return null;
  }

  // Dashboard Items (Checklists)
  Future<int> insertDashboardItem(Map<String, dynamic> item) async {
    final Database db = await database;
    return await db.insert('dashboard_items', item);
  }

  Future<List<Map<String, dynamic>>> getDashboardItems(
    String date,
    String type,
  ) async {
    final Database db = await database;
    return await db.query(
      'dashboard_items',
      where: 'date = ? AND type = ?',
      whereArgs: [date, type],
      orderBy: 'position ASC',
    );
  }

  Future<int> updateDashboardItem(Map<String, dynamic> item) async {
    final Database db = await database;
    return await db.update(
      'dashboard_items',
      item,
      where: 'id = ?',
      whereArgs: [item['id']],
    );
  }

  Future<int> deleteDashboardItem(int id) async {
    final Database db = await database;
    return await db.delete('dashboard_items', where: 'id = ?', whereArgs: [id]);
  }
}
