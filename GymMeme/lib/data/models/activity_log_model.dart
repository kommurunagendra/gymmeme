// Mood enum values as strings for simplicity (Drift stores as TEXT)
class GymMood {
  static const String beastMode = 'beast_mode';
  static const String focused = 'focused';
  static const String lazy = 'lazy';
  static const String distracted = 'distracted';
  static const String social = 'social';

  static const List<String> all = [
    beastMode,
    focused,
    lazy,
    distracted,
    social,
  ];

  static String emoji(String mood) {
    switch (mood) {
      case beastMode:
        return '😤';
      case focused:
        return '🎯';
      case lazy:
        return '😴';
      case distracted:
        return '📱';
      case social:
        return '🗣️';
      default:
        return '🏋️';
    }
  }

  static String label(String mood) {
    switch (mood) {
      case beastMode:
        return 'Beast Mode';
      case focused:
        return 'Focused';
      case lazy:
        return 'Lazy Day';
      case distracted:
        return 'Distracted';
      case social:
        return 'Social';
      default:
        return mood;
    }
  }
}

class ActivityLogModel {
  final int? id; // Drift auto-increment
  final String logId; // UUID
  final DateTime date;
  final int durationMinutes;
  final List<String> exerciseTypes; // stored as comma-separated in DB
  final String mood;
  final String selfTagArchetype;
  final String? notes;
  final List<String> tags;
  final bool memeCreated;
  final String? memeId;

  const ActivityLogModel({
    this.id,
    required this.logId,
    required this.date,
    this.durationMinutes = 0,
    this.exerciseTypes = const [],
    required this.mood,
    required this.selfTagArchetype,
    this.notes,
    this.tags = const [],
    this.memeCreated = false,
    this.memeId,
  });

  factory ActivityLogModel.fromMap(Map<String, dynamic> map) =>
      ActivityLogModel(
        id: map['id'] as int?,
        logId: map['logId'] as String,
        date: DateTime.parse(map['date'] as String),
        durationMinutes: map['durationMinutes'] as int? ?? 0,
        exerciseTypes: (map['exerciseTypes'] as String? ?? '')
            .split(',')
            .where((s) => s.isNotEmpty)
            .toList(),
        mood: map['mood'] as String,
        selfTagArchetype: map['selfTagArchetype'] as String,
        notes: map['notes'] as String?,
        tags: (map['tags'] as String? ?? '')
            .split(',')
            .where((s) => s.isNotEmpty)
            .toList(),
        memeCreated: (map['memeCreated'] as int? ?? 0) == 1,
        memeId: map['memeId'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'logId': logId,
        'date': date.toIso8601String(),
        'durationMinutes': durationMinutes,
        'exerciseTypes': exerciseTypes.join(','),
        'mood': mood,
        'selfTagArchetype': selfTagArchetype,
        'notes': notes,
        'tags': tags.join(','),
        'memeCreated': memeCreated ? 1 : 0,
        'memeId': memeId,
      };
}

// Summary used by weekly report
class WeeklyReportData {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int sessionCount;
  final double avgDurationMinutes;
  final Map<String, int> archetypeCounts; // archetype -> count
  final Map<String, int> moodCounts;
  final String dominantArchetype;
  final String dominantMood;

  const WeeklyReportData({
    required this.weekStart,
    required this.weekEnd,
    required this.sessionCount,
    required this.avgDurationMinutes,
    required this.archetypeCounts,
    required this.moodCounts,
    required this.dominantArchetype,
    required this.dominantMood,
  });
}
