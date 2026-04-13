import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/local/database.dart';
import '../../../data/models/activity_log_model.dart';
import 'package:drift/drift.dart' show Value;

// ─── Database Provider (singleton) ───────────────────────────────────────────

final appDatabaseProvider =
    Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ─── All logs stream ──────────────────────────────────────────────────────────

final allLogsProvider = FutureProvider<List<ActivityLog>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.getAllLogs();
});

// ─── Last 7 days logs ─────────────────────────────────────────────────────────

final recentLogsProvider =
    FutureProvider<List<ActivityLog>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.getLogsForLastDays(7);
});

// ─── Weekly report ────────────────────────────────────────────────────────────

final weeklyReportProvider =
    FutureProvider<WeeklyReportData?>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final logs = await db.getLogsForDateRange(
    DateTime(weekStart.year, weekStart.month, weekStart.day),
    now,
  );

  if (logs.isEmpty) return null;

  final archetypeCounts = <String, int>{};
  final moodCounts = <String, int>{};
  var totalDuration = 0;

  for (final log in logs) {
    archetypeCounts[log.selfTagArchetype] =
        (archetypeCounts[log.selfTagArchetype] ?? 0) + 1;
    moodCounts[log.mood] = (moodCounts[log.mood] ?? 0) + 1;
    totalDuration += log.durationMinutes;
  }

  final dominantArchetype = archetypeCounts.entries
      .reduce((a, b) => a.value >= b.value ? a : b)
      .key;
  final dominantMood = moodCounts.entries
      .reduce((a, b) => a.value >= b.value ? a : b)
      .key;

  return WeeklyReportData(
    weekStart: weekStart,
    weekEnd: now,
    sessionCount: logs.length,
    avgDurationMinutes: logs.isEmpty ? 0 : totalDuration / logs.length,
    archetypeCounts: archetypeCounts,
    moodCounts: moodCounts,
    dominantArchetype: dominantArchetype,
    dominantMood: dominantMood,
  );
});

// ─── Today has log ────────────────────────────────────────────────────────────

final hasTodayLogProvider = FutureProvider<bool>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.hasLogForToday();
});

// ─── Log Notifier (CRUD) ──────────────────────────────────────────────────────

final logNotifierProvider =
    Provider<LogNotifier>((ref) => LogNotifier(ref.watch(appDatabaseProvider)));

class LogNotifier {
  final AppDatabase _db;
  final _uuid = const Uuid();

  LogNotifier(this._db);

  Future<void> addLog({
    required String mood,
    required String selfTagArchetype,
    required int durationMinutes,
    List<String> exerciseTypes = const [],
    String? notes,
    List<String> tags = const [],
  }) async {
    await _db.insertLog(ActivityLogsCompanion(
      logId: Value(_uuid.v4()),
      date: Value(DateTime.now().toIso8601String()),
      mood: Value(mood),
      selfTagArchetype: Value(selfTagArchetype),
      durationMinutes: Value(durationMinutes),
      exerciseTypes: Value(exerciseTypes.join(',')),
      notes: Value(notes),
      tags: Value(tags.join(',')),
    ));
  }
}
