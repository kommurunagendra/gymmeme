import '../../../data/models/archetype_model.dart';

// ─── Static Archetype Definitions ────────────────────────────────────────────

const List<ArchetypeModel> kArchetypes = [
  ArchetypeModel(
    id: 'mirror_addict',
    name: 'Mirror Addict',
    emoji: '🪞',
    description:
        'Every set ends with a flex check. Angle? Perfect. Pump? Maximised. '
        'You didn\'t come here to lift weights, you came here to confirm you look great.',
    behaviourPatterns: [
      'Selects machine closest to mirror regardless of availability',
      'Flexes between every set',
      'Takes 3+ progress photos per session',
      'Adjusts gym clothes more than reps completed',
    ],
    colour: '#E91E63',
    badgeUnlockCount: 10,
  ),
  ArchetypeModel(
    id: 'ego_lifter',
    name: 'Ego Lifter',
    emoji: '🏋️',
    description:
        'The weight is always "too light". Form is optional when you\'re moving '
        'this much iron. Half reps count if they\'re heavy enough.',
    behaviourPatterns: [
      'Loads 40kg more than they can handle',
      'Never uses a spotter but always needs one',
      'Makes eye contact while struggling',
      'Drops weights from chest height for the noise',
    ],
    colour: '#F44336',
    badgeUnlockCount: 10,
  ),
  ArchetypeModel(
    id: 'social_scroller',
    name: 'Social Scroller',
    emoji: '📱',
    description:
        'Technically at the gym. Spiritually on TikTok. The 90-second rest '
        'timer is just a suggestion — 15 minutes is more realistic.',
    behaviourPatterns: [
      'Phone out between every set',
      'Rest periods measured in Instagram stories',
      'Occupies equipment for 45 minutes, lifts for 8',
      'Texts mid-rep',
    ],
    colour: '#2196F3',
    badgeUnlockCount: 10,
  ),
  ArchetypeModel(
    id: 'equipment_camper',
    name: 'Equipment Camper',
    emoji: '⛺',
    description:
        'Found a bench at 6pm on a Monday? That\'s your bench now. '
        'For the whole session. Working in? No concept of it.',
    behaviourPatterns: [
      'Claims bench with towel then disappears for 10 minutes',
      'Three sets of equipment "in use" simultaneously',
      'Gets territorial if someone looks at their machine',
      'Never works in with others',
    ],
    colour: '#FF9800',
    badgeUnlockCount: 10,
  ),
  ArchetypeModel(
    id: 'over_stretcher',
    name: 'Over-Stretcher',
    emoji: '🧘',
    description:
        'Arrives 15 minutes early to stretch. Stretches for 25 minutes. '
        'Completes 2 exercises. Stretches for 20 minutes. Leaves satisfied.',
    behaviourPatterns: [
      'Warm-up takes longer than the actual workout',
      'Has a 12-step stretching routine per muscle group',
      'Foam rolls for longer than most people lift',
      'Gives unsolicited stretching advice',
    ],
    colour: '#4CAF50',
    badgeUnlockCount: 10,
  ),
  ArchetypeModel(
    id: 'supplement_scientist',
    name: 'Supplement Scientist',
    emoji: '🧪',
    description:
        'Gym bag contains more powders than a pharmacy. Has an opinion on '
        'beta-alanine timing. Drinks pre-workout from a shaker labelled '
        '"Alpha Formula v3".',
    behaviourPatterns: [
      'Pre-workout ritual takes 20 minutes',
      'Has a supplement for every 30-minute window',
      'Judges others\' protein choices',
      'Carries a kitchen scale to measure creatine',
    ],
    colour: '#9C27B0',
    badgeUnlockCount: 10,
  ),
];

// ─── Quiz Questions ───────────────────────────────────────────────────────────

class QuizQuestion {
  final String id;
  final String question;
  final List<QuizOption> options;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
  });
}

class QuizOption {
  final String text;
  final Map<String, int> scores; // archetypeId -> points added

  const QuizOption({required this.text, required this.scores});
}

const List<QuizQuestion> kQuizQuestions = [
  QuizQuestion(
    id: 'q1',
    question: 'You finish a heavy set. What do you do first?',
    options: [
      QuizOption(
        text: '👀 Check yourself out in the mirror',
        scores: {'mirror_addict': 3, 'ego_lifter': 1},
      ),
      QuizOption(
        text: '📱 Check your phone',
        scores: {'social_scroller': 3},
      ),
      QuizOption(
        text: '🧘 Start stretching immediately',
        scores: {'over_stretcher': 3},
      ),
      QuizOption(
        text: '🧪 Drink from shaker number 2 of 4',
        scores: {'supplement_scientist': 3},
      ),
    ],
  ),
  QuizQuestion(
    id: 'q2',
    question:
        'Someone wants to use the bench you\'re resting on. You say...',
    options: [
      QuizOption(
        text: '"Working in? Nah, I\'ve got 4 more sets"',
        scores: {'equipment_camper': 3, 'ego_lifter': 1},
      ),
      QuizOption(
        text: '"Sure! Let me just finish this story first"',
        scores: {'social_scroller': 3},
      ),
      QuizOption(
        text: '"I just need to finish my post-set stretch routine"',
        scores: {'over_stretcher': 2, 'equipment_camper': 1},
      ),
      QuizOption(
        text: '"Go ahead, I need to mix my intra-workout anyway"',
        scores: {'supplement_scientist': 3},
      ),
    ],
  ),
  QuizQuestion(
    id: 'q3',
    question: 'How do you choose which machine to use?',
    options: [
      QuizOption(
        text: '🪞 Closest one to the mirror, obviously',
        scores: {'mirror_addict': 3},
      ),
      QuizOption(
        text: '💪 Whichever has the most weight already loaded',
        scores: {'ego_lifter': 3},
      ),
      QuizOption(
        text: '📱 Wherever the lighting is best for content',
        scores: {'social_scroller': 2, 'mirror_addict': 1},
      ),
      QuizOption(
        text: '⛺ The one I used last week, which I\'ve basically claimed',
        scores: {'equipment_camper': 3},
      ),
    ],
  ),
  QuizQuestion(
    id: 'q4',
    question: 'Your gym bag contains:',
    options: [
      QuizOption(
        text: '🪞 A compact mirror and baby oil',
        scores: {'mirror_addict': 3},
      ),
      QuizOption(
        text: '🧪 6 different supplements and a shaker for each',
        scores: {'supplement_scientist': 3},
      ),
      QuizOption(
        text: '📱 Phone charger, headphones, and a ring light',
        scores: {'social_scroller': 3},
      ),
      QuizOption(
        text: '🧘 A foam roller, resistance bands, and a yoga mat',
        scores: {'over_stretcher': 3},
      ),
    ],
  ),
  QuizQuestion(
    id: 'q5',
    question:
        'Someone\'s using "your" machine when you arrive. You:',
    options: [
      QuizOption(
        text: '😤 Stand nearby and stare until they feel uncomfortable',
        scores: {'equipment_camper': 3, 'ego_lifter': 1},
      ),
      QuizOption(
        text: '🤳 Film yourself doing something nearby instead',
        scores: {'social_scroller': 2, 'mirror_addict': 1},
      ),
      QuizOption(
        text: '🧘 Use the wait time for more stretching',
        scores: {'over_stretcher': 3},
      ),
      QuizOption(
        text: '💪 Ask if they want to work in, then load 30kg more',
        scores: {'ego_lifter': 3},
      ),
    ],
  ),
  QuizQuestion(
    id: 'q6',
    question: 'Your rest time between sets is usually:',
    options: [
      QuizOption(
        text: '📱 However long it takes to find the perfect caption',
        scores: {'social_scroller': 3},
      ),
      QuizOption(
        text: '🧪 Exactly 4 minutes — my app times it for peak recovery',
        scores: {'supplement_scientist': 2, 'over_stretcher': 1},
      ),
      QuizOption(
        text: '🪞 Long enough to do a full flex check from every angle',
        scores: {'mirror_addict': 3},
      ),
      QuizOption(
        text: '⛺ As long as I want — this is my area until I leave',
        scores: {'equipment_camper': 3},
      ),
    ],
  ),
  QuizQuestion(
    id: 'q7',
    question: 'Someone asks you for gym advice. You say:',
    options: [
      QuizOption(
        text: '🪞 "Lighting is everything. Natural pump + golden hour = chef\'s kiss"',
        scores: {'mirror_addict': 3},
      ),
      QuizOption(
        text: '🧪 "Are you taking beta-alanine? Because without it your ATP—"',
        scores: {'supplement_scientist': 3},
      ),
      QuizOption(
        text: '🧘 "You need to stretch more. Way more. Like, start now"',
        scores: {'over_stretcher': 3},
      ),
      QuizOption(
        text: '💪 "Just add more weight. Pain is weakness leaving"',
        scores: {'ego_lifter': 3},
      ),
    ],
  ),
  QuizQuestion(
    id: 'q8',
    question: 'How do you track your progress?',
    options: [
      QuizOption(
        text: '📸 Progress photos. Daily. From 12 angles.',
        scores: {'mirror_addict': 3},
      ),
      QuizOption(
        text: '📊 A spreadsheet tracking 8 different supplement protocols',
        scores: {'supplement_scientist': 3},
      ),
      QuizOption(
        text: '📱 My follower count. If it\'s going up, I\'m doing something right',
        scores: {'social_scroller': 3},
      ),
      QuizOption(
        text: '💪 How heavy the bar is. Weight is the only metric that matters',
        scores: {'ego_lifter': 3},
      ),
    ],
  ),
];

// ─── Archetype Lookup ─────────────────────────────────────────────────────────

ArchetypeModel getArchetypeById(String id) =>
    kArchetypes.firstWhere((a) => a.id == id,
        orElse: () => kArchetypes.first);

/// Compute archetype from quiz scores
String computeArchetype(Map<String, int> scores) {
  if (scores.isEmpty) return 'social_scroller';
  return scores.entries
      .reduce((a, b) => a.value >= b.value ? a : b)
      .key;
}
