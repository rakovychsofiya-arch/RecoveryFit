import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/workout_enums.dart';
import '../../domain/entities/workout_exercise.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/entities/workout_set.dart';
import '../../domain/entities/workout_template.dart';

abstract class WorkoutLocalDataSource {
  Future<List<Exercise>> getExercises({String? category});
  Future<List<WorkoutTemplate>> getTemplates();
  Future<WorkoutTemplate?> getTemplateById(String id);
  Future<void> saveTemplate(WorkoutTemplate template);
  Future<void> deleteTemplate(String id);

  Future<List<WorkoutSession>> getWorkouts();
  Future<WorkoutSession?> getWorkoutById(String id);
  Future<void> saveWorkout(WorkoutSession session);
  Future<void> deleteWorkout(String id);
}

class WorkoutLocalDataSourceImpl implements WorkoutLocalDataSource {
  final DatabaseHelper dbHelper;
  final Uuid uuid = const Uuid();

  WorkoutLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<List<Exercise>> getExercises({String? category}) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps;
    if (category != null && category.isNotEmpty) {
      maps = await db.query(
        'exercises',
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'name ASC',
      );
    } else {
      maps = await db.query('exercises', orderBy: 'name ASC');
    }

    return maps.map((m) {
      final equipmentStr = m['equipment'] as String;
      final equipment = EquipmentType.values.firstWhere(
        (e) => e.name == equipmentStr,
        orElse: () => EquipmentType.bodyweight,
      );
      return Exercise(
        id: m['id'] as String,
        name: m['name'] as String,
        category: m['category'] as String,
        equipment: equipment,
        description: m['description'] as String?,
      );
    }).toList();
  }

  @override
  Future<List<WorkoutTemplate>> getTemplates() async {
    final db = await dbHelper.database;
    final templateMaps = await db.query('workout_templates', orderBy: 'created_at DESC');

    final List<WorkoutTemplate> templates = [];
    for (var tMap in templateMaps) {
      final templateId = tMap['id'] as String;
      final exMaps = await db.query(
        'template_exercises',
        where: 'template_id = ?',
        whereArgs: [templateId],
        orderBy: 'order_index ASC',
      );

      final exercises = exMaps.map((e) {
        final eqStr = e['equipment'] as String;
        final eq = EquipmentType.values.firstWhere(
          (val) => val.name == eqStr,
          orElse: () => EquipmentType.bodyweight,
        );
        return TemplateExercise(
          id: e['id'] as String,
          exerciseName: e['exercise_name'] as String,
          equipment: eq,
          orderIndex: e['order_index'] as int,
          defaultSets: e['default_sets'] as int,
          defaultReps: e['default_reps'] as int,
          defaultWeight: (e['default_weight'] as num).toDouble(),
        );
      }).toList();

      templates.add(WorkoutTemplate(
        id: templateId,
        title: tMap['title'] as String,
        notes: tMap['notes'] as String?,
        exercises: exercises,
        createdAt: DateTime.parse(tMap['created_at'] as String),
      ));
    }
    return templates;
  }

  @override
  Future<WorkoutTemplate?> getTemplateById(String id) async {
    final templates = await getTemplates();
    try {
      return templates.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveTemplate(WorkoutTemplate template) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert(
        'workout_templates',
        {
          'id': template.id,
          'title': template.title,
          'notes': template.notes,
          'created_at': template.createdAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Видаляємо старі зв'язані вправи шаблону та додаємо актуальні
      await txn.delete(
        'template_exercises',
        where: 'template_id = ?',
        whereArgs: [template.id],
      );

      for (var ex in template.exercises) {
        await txn.insert('template_exercises', {
          'id': ex.id.isNotEmpty ? ex.id : uuid.v4(),
          'template_id': template.id,
          'exercise_name': ex.exerciseName,
          'equipment': ex.equipment.name,
          'order_index': ex.orderIndex,
          'default_sets': ex.defaultSets,
          'default_reps': ex.defaultReps,
          'default_weight': ex.defaultWeight,
        });
      }
    });
  }

  @override
  Future<void> deleteTemplate(String id) async {
    final db = await dbHelper.database;
    await db.delete('workout_templates', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<WorkoutSession>> getWorkouts() async {
    final db = await dbHelper.database;
    final sessionMaps = await db.query('workout_sessions', orderBy: 'date DESC');

    final List<WorkoutSession> sessions = [];

    for (var sMap in sessionMaps) {
      final sessionId = sMap['id'] as String;
      final typeStr = sMap['type'] as String;
      final title = sMap['title'] as String;
      final date = DateTime.parse(sMap['date'] as String);
      final duration = sMap['duration_minutes'] as int?;
      final calories = sMap['calories_burned'] as int?;
      final heartRate = sMap['avg_heart_rate'] as int?;
      final notes = sMap['notes'] as String?;
      final restSeconds = sMap['rest_timer_duration_seconds'] as int?;
      final restDuration = restSeconds != null ? Duration(seconds: restSeconds) : null;

      if (typeStr == WorkoutType.strength.name) {
        // Завантажуємо вправи силового тренування
        final exMaps = await db.query(
          'session_exercises',
          where: 'session_id = ?',
          whereArgs: [sessionId],
          orderBy: 'order_index ASC',
        );

        final List<WorkoutExercise> exercises = [];
        for (var eMap in exMaps) {
          final sessionExId = eMap['id'] as String;
          final setMaps = await db.query(
            'exercise_sets',
            where: 'session_exercise_id = ?',
            whereArgs: [sessionExId],
            orderBy: 'set_number ASC',
          );

          final sets = setMaps.map((st) {
            final catStr = st['category'] as String;
            final cat = SetCategory.values.firstWhere(
              (c) => c.name == catStr,
              orElse: () => SetCategory.working,
            );
            return WorkoutSet(
              id: st['id'] as String,
              setNumber: st['set_number'] as int,
              weight: (st['weight'] as num).toDouble(),
              reps: st['reps'] as int,
              category: cat,
              restTimeSeconds: st['rest_time_seconds'] as int?,
              isCompleted: (st['is_completed'] as int) == 1,
            );
          }).toList();

          final eqStr = eMap['equipment'] as String;
          final eq = EquipmentType.values.firstWhere(
            (val) => val.name == eqStr,
            orElse: () => EquipmentType.bodyweight,
          );

          exercises.add(WorkoutExercise(
            id: sessionExId,
            exerciseId: eMap['exercise_id'] as String? ?? '',
            name: eMap['name'] as String,
            equipment: eq,
            sets: sets,
            notes: eMap['notes'] as String?,
          ));
        }

        sessions.add(StrengthWorkoutSession(
          id: sessionId,
          title: title,
          date: date,
          caloriesBurned: calories,
          avgHeartRate: heartRate,
          notes: notes,
          restTimerDuration: restDuration,
          exercises: exercises,
        ));
      } else if (typeStr == WorkoutType.cardio.name) {
        sessions.add(CardioWorkoutSession(
          id: sessionId,
          title: title,
          date: date,
          distanceInKm: (sMap['distance_km'] as num?)?.toDouble() ?? 0.0,
          durationMinutes: duration ?? 0,
          caloriesBurned: calories,
          avgHeartRate: heartRate,
          notes: notes,
          restTimerDuration: restDuration,
        ));
      } else if (typeStr == WorkoutType.stretching.name) {
        sessions.add(StretchingWorkoutSession(
          id: sessionId,
          title: title,
          date: date,
          durationMinutes: duration ?? 0,
          targetMuscleGroup: sMap['target_muscle_group'] as String? ?? 'Загальна',
          caloriesBurned: calories,
          avgHeartRate: heartRate,
          notes: notes,
          restTimerDuration: restDuration,
        ));
      }
    }

    return sessions;
  }

  @override
  Future<WorkoutSession?> getWorkoutById(String id) async {
    final workouts = await getWorkouts();
    try {
      return workouts.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveWorkout(WorkoutSession session) async {
    final db = await dbHelper.database;

    await db.transaction((txn) async {
      final sessionMap = <String, dynamic>{
        'id': session.id,
        'title': session.title,
        'type': session.type.name,
        'date': session.date.toIso8601String(),
        'calories_burned': session.caloriesBurned,
        'avg_heart_rate': session.avgHeartRate,
        'rest_timer_duration_seconds': session.restTimerDuration?.inSeconds,
        'notes': session.notes,
      };

      if (session is StrengthWorkoutSession) {
        sessionMap['duration_minutes'] = null;
        sessionMap['distance_km'] = null;
        sessionMap['target_muscle_group'] = null;
      } else if (session is CardioWorkoutSession) {
        sessionMap['duration_minutes'] = session.durationMinutes;
        sessionMap['distance_km'] = session.distanceInKm;
        sessionMap['target_muscle_group'] = null;
      } else if (session is StretchingWorkoutSession) {
        sessionMap['duration_minutes'] = session.durationMinutes;
        sessionMap['distance_km'] = null;
        sessionMap['target_muscle_group'] = session.targetMuscleGroup;
      }

      await txn.insert(
        'workout_sessions',
        sessionMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Якщо це силове тренування, зберігаємо вправи та підходи
      if (session is StrengthWorkoutSession) {
        await txn.delete('session_exercises', where: 'session_id = ?', whereArgs: [session.id]);

        for (int i = 0; i < session.exercises.length; i++) {
          final ex = session.exercises[i];
          final exId = ex.id.isNotEmpty ? ex.id : uuid.v4();

          await txn.insert('session_exercises', {
            'id': exId,
            'session_id': session.id,
            'exercise_id': ex.exerciseId,
            'name': ex.name,
            'equipment': ex.equipment.name,
            'order_index': i,
            'notes': ex.notes,
          });

          for (var st in ex.sets) {
            final setId = st.id != null && st.id!.isNotEmpty ? st.id! : uuid.v4();
            await txn.insert('exercise_sets', {
              'id': setId,
              'session_exercise_id': exId,
              'set_number': st.setNumber,
              'weight': st.weight,
              'reps': st.reps,
              'category': st.category.name,
              'rest_time_seconds': st.restTimeSeconds,
              'is_completed': st.isCompleted ? 1 : 0,
            });
          }
        }
      }
    });
  }

  @override
  Future<void> deleteWorkout(String id) async {
    final db = await dbHelper.database;
    await db.delete('workout_sessions', where: 'id = ?', whereArgs: [id]);
  }
}
