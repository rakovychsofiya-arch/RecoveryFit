import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fitness_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Каталог вправ
    await db.execute('''
      CREATE TABLE exercises (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        equipment TEXT NOT NULL,
        description TEXT
      )
    ''');

    // 2. Шаблони тренувань (наприклад: "День ніг", "Спина/Біцепс")
    await db.execute('''
      CREATE TABLE workout_templates (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 3. Вправи в шаблоні тренування
    await db.execute('''
      CREATE TABLE template_exercises (
        id TEXT PRIMARY KEY,
        template_id TEXT NOT NULL,
        exercise_name TEXT NOT NULL,
        equipment TEXT NOT NULL,
        order_index INTEGER NOT NULL,
        default_sets INTEGER NOT NULL,
        default_reps INTEGER NOT NULL,
        default_weight REAL NOT NULL,
        FOREIGN KEY (template_id) REFERENCES workout_templates (id) ON DELETE CASCADE
      )
    ''');

    // 4. Сесії проведених тренувань (силові, кардіо, розтяжка)
    await db.execute('''
      CREATE TABLE workout_sessions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        duration_minutes INTEGER,
        calories_burned INTEGER,
        avg_heart_rate INTEGER,
        distance_km REAL,
        target_muscle_group TEXT,
        rest_timer_duration_seconds INTEGER,
        notes TEXT
      )
    ''');

    // 5. Вправи у конкретному проведеному силовому тренуванні
    await db.execute('''
      CREATE TABLE session_exercises (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        exercise_id TEXT,
        name TEXT NOT NULL,
        equipment TEXT NOT NULL,
        order_index INTEGER NOT NULL,
        notes TEXT,
        FOREIGN KEY (session_id) REFERENCES workout_sessions (id) ON DELETE CASCADE
      )
    ''');

    // 6. Підходи (сети) для конкретної вправи силового тренування
    await db.execute('''
      CREATE TABLE exercise_sets (
        id TEXT PRIMARY KEY,
        session_exercise_id TEXT NOT NULL,
        set_number INTEGER NOT NULL,
        weight REAL NOT NULL,
        reps INTEGER NOT NULL,
        category TEXT NOT NULL,
        rest_time_seconds INTEGER,
        is_completed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (session_exercise_id) REFERENCES session_exercises (id) ON DELETE CASCADE
      )
    ''');

    // 7. Метрики здоров'я (кроки, калорії за день)
    await db.execute('''
      CREATE TABLE health_metrics (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL UNIQUE,
        steps_count INTEGER NOT NULL,
        active_calories REAL NOT NULL
      )
    ''');

    // 8. Сесії сну
    await db.execute('''
      CREATE TABLE sleep_sessions (
        id TEXT PRIMARY KEY,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        total_minutes INTEGER NOT NULL,
        deep_minutes INTEGER NOT NULL,
        rem_minutes INTEGER NOT NULL,
        light_minutes INTEGER NOT NULL
      )
    ''');

    // Початкове наповнення базовими вправами
    await _seedExercises(db);
  }

  Future<void> _seedExercises(Database db) async {
    const uuid = Uuid();
    final defaultExercises = [
      {'name': 'Жим штанги лежачи', 'category': 'Груди', 'equipment': 'barbell', 'desc': 'Базова вправа для розвитку грудних м\'язів'},
      {'name': 'Жим гантелей на похилій лаві', 'category': 'Груди', 'equipment': 'dumbbells', 'desc': 'Розвиток верхньої частини грудних'},
      {'name': 'Віджимання від підлоги', 'category': 'Груди', 'equipment': 'bodyweight', 'desc': 'Класична вправа з власною вагою'},
      {'name': 'Присідання зі штангою', 'category': 'Ноги', 'equipment': 'barbell', 'desc': 'Базова багатосуглобова вправа для квадрицепсів і сідниць'},
      {'name': 'Жим ногами в тренажері', 'category': 'Ноги', 'equipment': 'machine', 'desc': 'Ізольоване навантаження на ноги'},
      {'name': 'Випади з гантелями', 'category': 'Ноги', 'equipment': 'dumbbells', 'desc': 'Вправа на координацію та сідничні м\'язи'},
      {'name': 'Підтягування на турніку', 'category': 'Спина', 'equipment': 'bodyweight', 'desc': 'Широкі м\'язи спини та біцепс'},
      {'name': 'Тяга штанги в нахилі', 'category': 'Спина', 'equipment': 'barbell', 'desc': 'Товщина спини та найширші м\'язи'},
      {'name': 'Тяга верхнього блоку до грудей', 'category': 'Спина', 'equipment': 'machine', 'desc': 'Альтернатива підтягуванням'},
      {'name': 'Армійський жим стоячи', 'category': 'Плечі', 'equipment': 'barbell', 'desc': 'Базовий жим над головою'},
      {'name': 'Махи гантелями в сторони', 'category': 'Плечі', 'equipment': 'dumbbells', 'desc': 'Ізоляція середньої дельти'},
      {'name': 'Згинання рук з гантелями на біцепс', 'category': 'Руки', 'equipment': 'dumbbells', 'desc': 'Класичний біцепс'},
      {'name': 'Французький жим зі штангою', 'category': 'Руки', 'equipment': 'barbell', 'desc': 'Робота на трицепс'},
      {'name': 'Планка на ліктях', 'category': 'Кор', 'equipment': 'bodyweight', 'desc': 'Статичне навантаження на м\'язи кору'},
    ];

    final batch = db.batch();
    for (var ex in defaultExercises) {
      batch.insert('exercises', {
        'id': uuid.v4(),
        'name': ex['name'],
        'category': ex['category'],
        'equipment': ex['equipment'],
        'description': ex['desc'],
      });
    }
    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
