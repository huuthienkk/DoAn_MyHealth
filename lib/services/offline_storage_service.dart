import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/health_model.dart';
import '../models/mood_model.dart';

class OfflineStorageService {
  static final OfflineStorageService _instance = OfflineStorageService._internal();
  factory OfflineStorageService() => _instance;
  OfflineStorageService._internal();

  static OfflineStorageService get instance => _instance;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'health_data.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Bảng health data
    await db.execute('''
      CREATE TABLE health_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        steps INTEGER NOT NULL,
        weight REAL NOT NULL,
        sleep_hours REAL NOT NULL,
        height REAL,
        systolic_bp INTEGER,
        diastolic_bp INTEGER,
        heart_rate INTEGER,
        water_intake REAL,
        calories_in REAL,
        calories_out REAL,
        synced INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Bảng mood data
    await db.execute('''
      CREATE TABLE mood_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        mood TEXT NOT NULL,
        stress_level INTEGER NOT NULL,
        note TEXT,
        synced INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Indexes
    await db.execute('CREATE INDEX idx_health_date ON health_data(date)');
    await db.execute('CREATE INDEX idx_health_synced ON health_data(synced)');
    await db.execute('CREATE INDEX idx_mood_date ON mood_data(date)');
    await db.execute('CREATE INDEX idx_mood_synced ON mood_data(synced)');
  }

  // Health Data Operations
  Future<int> insertHealthData(HealthData data, {bool synced = false}) async {
    final db = await database;
    return await db.insert(
      'health_data',
      {
        'date': data.date.toIso8601String(),
        'steps': data.steps,
        'weight': data.weight,
        'sleep_hours': data.sleepHours,
        'height': data.height,
        'systolic_bp': data.systolicBP,
        'diastolic_bp': data.diastolicBP,
        'heart_rate': data.heartRate,
        'water_intake': data.waterIntake,
        'calories_in': data.caloriesIn,
        'calories_out': data.caloriesOut,
        'synced': synced ? 1 : 0,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<HealthData>> getHealthData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String query = 'SELECT * FROM health_data WHERE 1=1';
    List<dynamic> args = [];

    if (startDate != null) {
      query += ' AND date >= ?';
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      query += ' AND date <= ?';
      args.add(endDate.toIso8601String());
    }

    query += ' ORDER BY date DESC';

    final results = await db.rawQuery(query, args);
    return results.map((map) => HealthData.fromMap({
          'date': map['date'],
          'steps': map['steps'],
          'weight': map['weight'],
          'sleepHours': map['sleep_hours'],
          'height': map['height'],
          'systolicBP': map['systolic_bp'],
          'diastolicBP': map['diastolic_bp'],
          'heartRate': map['heart_rate'],
          'waterIntake': map['water_intake'],
          'caloriesIn': map['calories_in'],
          'caloriesOut': map['calories_out'],
        })).toList();
  }

  Future<List<HealthData>> getUnsyncedHealthData() async {
    final db = await database;
    final results = await db.query(
      'health_data',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'date DESC',
    );
    return results.map((map) => HealthData.fromMap({
          'date': map['date'],
          'steps': map['steps'],
          'weight': map['weight'],
          'sleepHours': map['sleep_hours'],
          'height': map['height'],
          'systolicBP': map['systolic_bp'],
          'diastolicBP': map['diastolic_bp'],
          'heartRate': map['heart_rate'],
          'waterIntake': map['water_intake'],
          'caloriesIn': map['calories_in'],
          'caloriesOut': map['calories_out'],
        })).toList();
  }

  Future<void> markHealthDataSynced(int id) async {
    final db = await database;
    await db.update(
      'health_data',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Mood Data Operations
  Future<int> insertMoodData(MoodData data, {bool synced = false}) async {
    final db = await database;
    return await db.insert(
      'mood_data',
      {
        'date': data.date.toIso8601String(),
        'mood': data.mood,
        'stress_level': data.stressLevel,
        'note': data.note,
        'synced': synced ? 1 : 0,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MoodData>> getMoodData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String query = 'SELECT * FROM mood_data WHERE 1=1';
    List<dynamic> args = [];

    if (startDate != null) {
      query += ' AND date >= ?';
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      query += ' AND date <= ?';
      args.add(endDate.toIso8601String());
    }

    query += ' ORDER BY date DESC';

    final results = await db.rawQuery(query, args);
    return results.map((map) => MoodData.fromMap({
          'date': map['date'],
          'mood': map['mood'],
          'stressLevel': map['stress_level'],
          'note': map['note'] ?? '',
        })).toList();
  }

  Future<List<MoodData>> getUnsyncedMoodData() async {
    final db = await database;
    final results = await db.query(
      'mood_data',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'date DESC',
    );
    return results.map((map) => MoodData.fromMap({
          'date': map['date'],
          'mood': map['mood'],
          'stressLevel': map['stress_level'],
          'note': map['note'] ?? '',
        })).toList();
  }

  Future<void> markMoodDataSynced(int id) async {
    final db = await database;
    await db.update(
      'mood_data',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Clear all data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('health_data');
    await db.delete('mood_data');
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

