class UserModel {
  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final String primaryArchetype;
  final int streakDays;
  final DateTime? lastActiveDate;
  final int memeCount;
  final int totalLogs;
  final bool isPremium;
  final bool shareAnonymously;
  final DateTime createdAt;

  const UserModel({
    required this.userId,
    this.displayName,
    this.avatarUrl,
    required this.primaryArchetype,
    this.streakDays = 0,
    this.lastActiveDate,
    this.memeCount = 0,
    this.totalLogs = 0,
    this.isPremium = false,
    this.shareAnonymously = true,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        userId: map['userId'] as String,
        displayName: map['displayName'] as String?,
        avatarUrl: map['avatarUrl'] as String?,
        primaryArchetype: map['primaryArchetype'] as String? ?? 'unknown',
        streakDays: map['streakDays'] as int? ?? 0,
        lastActiveDate: map['lastActiveDate'] != null
            ? DateTime.parse(map['lastActiveDate'] as String)
            : null,
        memeCount: map['memeCount'] as int? ?? 0,
        totalLogs: map['totalLogs'] as int? ?? 0,
        isPremium: map['isPremium'] as bool? ?? false,
        shareAnonymously: map['shareAnonymously'] as bool? ?? true,
        createdAt: DateTime.parse(
            map['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'primaryArchetype': primaryArchetype,
        'streakDays': streakDays,
        'lastActiveDate': lastActiveDate?.toIso8601String(),
        'memeCount': memeCount,
        'totalLogs': totalLogs,
        'isPremium': isPremium,
        'shareAnonymously': shareAnonymously,
        'createdAt': createdAt.toIso8601String(),
      };

  UserModel copyWith({
    String? displayName,
    String? avatarUrl,
    String? primaryArchetype,
    int? streakDays,
    DateTime? lastActiveDate,
    int? memeCount,
    int? totalLogs,
    bool? isPremium,
    bool? shareAnonymously,
  }) =>
      UserModel(
        userId: userId,
        displayName: displayName ?? this.displayName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        primaryArchetype: primaryArchetype ?? this.primaryArchetype,
        streakDays: streakDays ?? this.streakDays,
        lastActiveDate: lastActiveDate ?? this.lastActiveDate,
        memeCount: memeCount ?? this.memeCount,
        totalLogs: totalLogs ?? this.totalLogs,
        isPremium: isPremium ?? this.isPremium,
        shareAnonymously: shareAnonymously ?? this.shareAnonymously,
        createdAt: createdAt,
      );
}
