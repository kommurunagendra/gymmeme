import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/archetype_model.dart';
import '../data/archetype_data.dart';
import '../providers/archetype_provider.dart';
import '../../../services/share_service.dart';
import '../../../services/auth_service.dart';
import '../../../data/remote/firestore_service.dart';

class ArchetypeResultScreen extends ConsumerStatefulWidget {
  final String archetypeId;
  final Map<String, int> scores;

  const ArchetypeResultScreen({
    super.key,
    required this.archetypeId,
    required this.scores,
  });

  @override
  ConsumerState<ArchetypeResultScreen> createState() =>
      _ArchetypeResultScreenState();
}

class _ArchetypeResultScreenState
    extends ConsumerState<ArchetypeResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  final _screenshotCtrl = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
    _saveResult();
  }

  Future<void> _saveResult() async {
    // Save to Hive locally
    await ref
        .read(currentArchetypeProvider.notifier)
        .setArchetype(widget.archetypeId);

    // Sync to Firestore if authenticated
    final authSvc = ref.read(authServiceProvider);
    if (authSvc.userId != null) {
      await ref
          .read(firestoreServiceProvider)
          .updateArchetype(authSvc.userId!, widget.archetypeId);
    }
  }

  Future<void> _shareResult() async {
    final imageBytes = await _screenshotCtrl.capture();
    if (imageBytes == null) return;

    final tempDir = Directory.systemTemp;
    final file = File(
        '${tempDir.path}/gymtype_result_${widget.archetypeId}.png');
    await file.writeAsBytes(imageBytes);

    final archetype = getArchetypeById(widget.archetypeId);
    await ShareService().shareReportCard(
      imagePath: file.path,
      dominantArchetype: archetype.name,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final archetype = getArchetypeById(widget.archetypeId);
    final theme = Theme.of(context);
    final color = _hexToColor(archetype.colour);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Your GymType is...',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Shareable card
                    Screenshot(
                      controller: _screenshotCtrl,
                      child: ScaleTransition(
                        scale: _scaleAnim,
                        child: _ArchetypeCard(
                            archetype: archetype, color: color),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Behaviour patterns
                    _BehaviourPatternsList(archetype: archetype, color: color),

                    const SizedBox(height: 24),

                    // Score breakdown
                    _ScoreBreakdown(scores: widget.scores),
                  ],
                ),
              ),
            ),

            // Bottom actions
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _shareResult,
                    icon: const Icon(Icons.share),
                    label: const Text('Share My GymType'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.home,
                      (_) => false,
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text('Go to App'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchetypeCard extends StatelessWidget {
  final ArchetypeModel archetype;
  final Color color;

  const _ArchetypeCard({required this.archetype, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(archetype.emoji, style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 16),
          Text(
            archetype.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            archetype.description,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'GymType App',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BehaviourPatternsList extends StatelessWidget {
  final ArchetypeModel archetype;
  final Color color;

  const _BehaviourPatternsList(
      {required this.archetype, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Signature Moves',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        ...archetype.behaviourPatterns.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(p,
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreBreakdown extends StatelessWidget {
  final Map<String, int> scores;

  const _ScoreBreakdown({required this.scores});

  @override
  Widget build(BuildContext context) {
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxScore =
        sorted.isNotEmpty ? sorted.first.value.toDouble() : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Full Breakdown',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        ...sorted.map((entry) {
          final archetype = getArchetypeById(entry.key);
          final pct = entry.value / maxScore;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(archetype.emoji),
                    const SizedBox(width: 8),
                    Text(archetype.name,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Text('${entry.value}pts',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: Colors.grey.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation(
                        _hexToColor(archetype.colour)),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

Color _hexToColor(String hex) {
  final buffer = StringBuffer();
  if (hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}
