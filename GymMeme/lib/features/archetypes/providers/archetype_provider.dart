import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/archetype_model.dart';
import '../data/archetype_data.dart';

// ─── Current archetype (persisted in Hive) ────────────────────────────────────

final currentArchetypeProvider =
    StateNotifierProvider<ArchetypeNotifier, ArchetypeModel?>(
        (ref) => ArchetypeNotifier());

class ArchetypeNotifier extends StateNotifier<ArchetypeModel?> {
  ArchetypeNotifier() : super(null) {
    _loadFromCache();
  }

  void _loadFromCache() {
    final box = Hive.box(AppConstants.archetypeCacheBox);
    final id = box.get(AppConstants.archetypeResultKey) as String?;
    if (id != null) {
      state = getArchetypeById(id);
    }
  }

  Future<void> setArchetype(String archetypeId) async {
    final box = Hive.box(AppConstants.archetypeCacheBox);
    await box.put(AppConstants.archetypeResultKey, archetypeId);
    state = getArchetypeById(archetypeId);
  }

  Future<void> clearArchetype() async {
    final box = Hive.box(AppConstants.archetypeCacheBox);
    await box.delete(AppConstants.archetypeResultKey);
    state = null;
  }
}

// ─── Quiz state ───────────────────────────────────────────────────────────────

class QuizState {
  final int currentQuestion;
  final Map<String, int> scores;
  final bool isComplete;

  const QuizState({
    this.currentQuestion = 0,
    this.scores = const {},
    this.isComplete = false,
  });

  QuizState copyWith({
    int? currentQuestion,
    Map<String, int>? scores,
    bool? isComplete,
  }) =>
      QuizState(
        currentQuestion: currentQuestion ?? this.currentQuestion,
        scores: scores ?? this.scores,
        isComplete: isComplete ?? this.isComplete,
      );
}

final quizProvider =
    StateNotifierProvider.autoDispose<QuizNotifier, QuizState>(
        (_) => QuizNotifier());

class QuizNotifier extends StateNotifier<QuizState> {
  QuizNotifier() : super(const QuizState());

  void answerQuestion(Map<String, int> optionScores) {
    final newScores = Map<String, int>.from(state.scores);
    for (final entry in optionScores.entries) {
      newScores[entry.key] = (newScores[entry.key] ?? 0) + entry.value;
    }
    final nextQ = state.currentQuestion + 1;
    state = state.copyWith(
      scores: newScores,
      currentQuestion: nextQ,
      isComplete: nextQ >= kQuizQuestions.length,
    );
  }

  void reset() => state = const QuizState();
}

// ─── All archetypes list ──────────────────────────────────────────────────────

final allArchetypesProvider = Provider<List<ArchetypeModel>>((_) => kArchetypes);
