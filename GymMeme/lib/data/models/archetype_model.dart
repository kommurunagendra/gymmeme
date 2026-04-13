class ArchetypeModel {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final List<String> behaviourPatterns;
  final String colour; // hex string e.g. '#FF5722'
  final int badgeUnlockCount;

  const ArchetypeModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.behaviourPatterns,
    required this.colour,
    required this.badgeUnlockCount,
  });

  factory ArchetypeModel.fromMap(Map<String, dynamic> map) => ArchetypeModel(
        id: map['id'] as String,
        name: map['name'] as String,
        emoji: map['emoji'] as String,
        description: map['description'] as String,
        behaviourPatterns:
            List<String>.from(map['behaviourPatterns'] as List? ?? []),
        colour: map['colour'] as String? ?? '#FF5722',
        badgeUnlockCount: map['badgeUnlockCount'] as int? ?? 10,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'description': description,
        'behaviourPatterns': behaviourPatterns,
        'colour': colour,
        'badgeUnlockCount': badgeUnlockCount,
      };
}
