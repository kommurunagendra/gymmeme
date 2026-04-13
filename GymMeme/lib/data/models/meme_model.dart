class MemeCaption {
  final String text;
  final String position; // 'top', 'bottom', 'custom'
  final double? x;
  final double? y;
  final double fontSize;
  final String color; // hex

  const MemeCaption({
    required this.text,
    required this.position,
    this.x,
    this.y,
    this.fontSize = 28,
    this.color = '#FFFFFF',
  });

  factory MemeCaption.fromMap(Map<String, dynamic> map) => MemeCaption(
        text: map['text'] as String,
        position: map['position'] as String,
        x: (map['x'] as num?)?.toDouble(),
        y: (map['y'] as num?)?.toDouble(),
        fontSize: (map['fontSize'] as num?)?.toDouble() ?? 28,
        color: map['color'] as String? ?? '#FFFFFF',
      );

  Map<String, dynamic> toMap() => {
        'text': text,
        'position': position,
        'x': x,
        'y': y,
        'fontSize': fontSize,
        'color': color,
      };
}

class MemeModel {
  final String memeId;
  final String creatorId;
  final bool isAnonymous;
  final String? templateId;
  final String? localImagePath; // local path before upload
  final String? remoteImageUrl; // Firebase Storage URL after upload
  final List<MemeCaption> captions;
  final List<String> tags;
  final String? archetypeTag;
  final String? aiCategory; // funny | cringe | impressive | wholesome
  final bool isPublic;
  final int upvotes;
  final int reportCount;
  final String status; // active | under_review | removed
  final DateTime createdAt;

  const MemeModel({
    required this.memeId,
    required this.creatorId,
    this.isAnonymous = true,
    this.templateId,
    this.localImagePath,
    this.remoteImageUrl,
    this.captions = const [],
    this.tags = const [],
    this.archetypeTag,
    this.aiCategory,
    this.isPublic = false,
    this.upvotes = 0,
    this.reportCount = 0,
    this.status = 'active',
    required this.createdAt,
  });

  factory MemeModel.fromMap(Map<String, dynamic> map) => MemeModel(
        memeId: map['memeId'] as String,
        creatorId: map['creatorId'] as String,
        isAnonymous: map['isAnonymous'] as bool? ?? true,
        templateId: map['templateId'] as String?,
        localImagePath: map['localImagePath'] as String?,
        remoteImageUrl: map['remoteImageUrl'] as String?,
        captions: (map['captions'] as List? ?? [])
            .map((c) => MemeCaption.fromMap(c as Map<String, dynamic>))
            .toList(),
        tags: List<String>.from(map['tags'] as List? ?? []),
        archetypeTag: map['archetypeTag'] as String?,
        aiCategory: map['aiCategory'] as String?,
        isPublic: map['isPublic'] as bool? ?? false,
        upvotes: map['upvotes'] as int? ?? 0,
        reportCount: map['reportCount'] as int? ?? 0,
        status: map['status'] as String? ?? 'active',
        createdAt: DateTime.parse(
            map['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      );

  Map<String, dynamic> toMap() => {
        'memeId': memeId,
        'creatorId': creatorId,
        'isAnonymous': isAnonymous,
        'templateId': templateId,
        'remoteImageUrl': remoteImageUrl,
        'captions': captions.map((c) => c.toMap()).toList(),
        'tags': tags,
        'archetypeTag': archetypeTag,
        'aiCategory': aiCategory,
        'isPublic': isPublic,
        'upvotes': upvotes,
        'reportCount': reportCount,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };

  MemeModel copyWith({
    String? remoteImageUrl,
    List<MemeCaption>? captions,
    List<String>? tags,
    String? archetypeTag,
    bool? isPublic,
    String? status,
  }) =>
      MemeModel(
        memeId: memeId,
        creatorId: creatorId,
        isAnonymous: isAnonymous,
        templateId: templateId,
        localImagePath: localImagePath,
        remoteImageUrl: remoteImageUrl ?? this.remoteImageUrl,
        captions: captions ?? this.captions,
        tags: tags ?? this.tags,
        archetypeTag: archetypeTag ?? this.archetypeTag,
        aiCategory: aiCategory,
        isPublic: isPublic ?? this.isPublic,
        upvotes: upvotes,
        reportCount: reportCount,
        status: status ?? this.status,
        createdAt: createdAt,
      );
}
