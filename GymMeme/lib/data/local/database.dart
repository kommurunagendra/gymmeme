import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// ─── Table Definitions ───────────────────────────────────────────────────────

class ActivityLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get logId => text().unique()();
  TextColumn get date => text()(); // ISO8601
  IntColumn get durationMinutes => integer().withDefault(const Constant(0))();
  TextColumn get exerciseTypes => text().withDefault(const Constant(''))();
  TextColumn get mood => text()();
  TextColumn get selfTagArchetype => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get tags => text().withDefault(const Constant(''))();
  BoolColumn get memeCreated =>
      boolean().withDefault(const Constant(false))();
  TextColumn get memeId => text().nullable()();
}

class LocalMemes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get memeId => text().unique()();
  TextColumn get localImagePath => text()();
  TextColumn get captions => text().withDefault(const Constant(''))();
  TextColumn get tags => text().withDefault(const Constant(''))();
  TextColumn get archetypeTag => text().nullable()();
  BoolColumn get isUploaded =>
      boolean().withDefault(const Constant(false))();
  TextColumn get remoteUrl => text().nullable()();
  TextColumn get createdAt => text()();
}

// ─── Database ─────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [ActivityLogs, LocalMemes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ── Activity Log Queries ───────────────────────────────────────────────────

  Future<int> insertLog(ActivityLogsCompanion log) =>
      into(activityLogs).insert(log);

  Future<List<ActivityLog>> getAllLogs() =>
      (select(activityLogs)
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();

  Future<List<ActivityLog>> getLogsForDateRange(
      DateTime start, DateTime end) =>
      (select(activityLogs)
            ..where((t) =>
                t.date.isBiggerOrEqualValue(start.toIso8601String()) &
                t.date.isSmallerOrEqualValue(end.toIso8601String()))
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();

  Future<List<ActivityLog>> getLogsForLastDays(int days) {
    final start = DateTime.now().subtract(Duration(days: days));
    return getLogsForDateRange(start, DateTime.now());
  }

  Future<ActivityLog?> getLogById(String logId) =>
      (select(activityLogs)..where((t) => t.logId.equals(logId)))
          .getSingleOrNull();

  Future<bool> hasLogForToday() async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final result = await (select(activityLogs)
          ..where((t) => t.date.like('$dateStr%')))
        .get();
    return result.isNotEmpty;
  }

  // ── Meme Queries ───────────────────────────────────────────────────────────

  Future<int> insertMeme(LocalMemesCompanion meme) =>
      into(localMemes).insert(meme);

  Future<List<LocalMeme>> getLocalMemes() =>
      (select(localMemes)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<bool> updateMemeUploadStatus(
      String memeId, String remoteUrl) async {
    final count = await (update(localMemes)
          ..where((t) => t.memeId.equals(memeId)))
        .write(LocalMemesCompanion(
      isUploaded: const Value(true),
      remoteUrl: Value(remoteUrl),
    ));
    return count > 0;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'gymtype.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
