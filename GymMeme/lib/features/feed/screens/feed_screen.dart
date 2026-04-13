import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/meme_model.dart';
import '../../../features/archetypes/data/archetype_data.dart';
import '../../../features/activity_log/providers/activity_log_provider.dart';
import '../../../services/ad_service.dart';
import '../providers/feed_provider.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memesAsync = ref.watch(publicMemesProvider);
    final hasTodayLog = ref.watch(hasTodayLogProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GymType 🏋️'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.weeklyReport),
            tooltip: 'Weekly Report',
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Daily log nudge
          hasTodayLog.when(
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, __) =>
                const SliverToBoxAdapter(child: SizedBox.shrink()),
            data: (hasLog) => hasLog
                ? const SliverToBoxAdapter(child: SizedBox.shrink())
                : SliverToBoxAdapter(
                    child: _DailyLogBanner(),
                  ),
          ),

          // Archetype scroll
          SliverToBoxAdapter(
            child: _ArchetypeScrollRow(),
          ),

          // Feed header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Community Memes',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),

          // Meme list
          memesAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error loading feed: $e')),
            ),
            data: (memes) => memes.isEmpty
                ? const SliverFillRemaining(
                    child: _EmptyFeed(),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        // Insert banner ad every 8 items
                        if (i > 0 && i % 8 == 0) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(child: BannerAdWidget()),
                          );
                        }
                        final memeIndex = i - (i ~/ 8);
                        if (memeIndex >= memes.length) {
                          return const SizedBox.shrink();
                        }
                        return _MemeCard(meme: memes[memeIndex]);
                      },
                      childCount: memes.length + (memes.length ~/ 8),
                    ),
                  ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

class _DailyLogBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, AppRoutes.dailyLog),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Text('💪', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Log today\'s session',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15),
                  ),
                  Text(
                    'Keep your streak alive!',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

class _ArchetypeScrollRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: kArchetypes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final a = kArchetypes[i];
          return _ArchetypeChip(
            emoji: a.emoji,
            name: a.name.split(' ').first,
            colour: a.colour,
          );
        },
      ),
    );
  }
}

class _ArchetypeChip extends StatelessWidget {
  final String emoji;
  final String name;
  final String colour;

  const _ArchetypeChip(
      {required this.emoji,
      required this.name,
      required this.colour});

  Color get _color {
    final buffer = StringBuffer();
    if (colour.length == 7) buffer.write('ff');
    buffer.write(colour.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(name,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _MemeCard extends ConsumerStatefulWidget {
  final MemeModel meme;
  const _MemeCard({required this.meme});

  @override
  ConsumerState<_MemeCard> createState() => _MemeCardState();
}

class _MemeCardState extends ConsumerState<_MemeCard> {
  bool _upvoted = false;
  late int _upvotes;

  @override
  void initState() {
    super.initState();
    _upvotes = widget.meme.upvotes;
  }

  Future<void> _upvote() async {
    if (_upvoted) return;
    setState(() {
      _upvoted = true;
      _upvotes++;
    });
    await ref.read(feedNotifierProvider).upvote(widget.meme.memeId);
  }

  void _showReportDialog() => showDialog(
        context: context,
        builder: (ctx) => _ReportDialog(
          onReport: (category, note) async {
            Navigator.pop(ctx);
            await ref.read(feedNotifierProvider).report(
                  memeId: widget.meme.memeId,
                  category: category,
                  note: note,
                );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report submitted')),
              );
            }
          },
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = widget.meme.remoteImageUrl;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image
          if (imageUrl != null)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                height: 220,
                errorBuilder: (_, __, ___) => Container(
                  height: 100,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),

          // Actions row
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Archetype tag
                if (widget.meme.archetypeTag != null)
                  _ArchetypeTag(archetypeId: widget.meme.archetypeTag!),

                const Spacer(),

                // Upvote
                GestureDetector(
                  onTap: _upvote,
                  child: Row(
                    children: [
                      Icon(
                        _upvoted
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: _upvoted ? Colors.red : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text('$_upvotes',
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Report
                GestureDetector(
                  onTap: _showReportDialog,
                  child: const Icon(Icons.flag_outlined,
                      color: Colors.grey, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchetypeTag extends StatelessWidget {
  final String archetypeId;
  const _ArchetypeTag({required this.archetypeId});

  @override
  Widget build(BuildContext context) {
    final a = getArchetypeById(archetypeId);
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${a.emoji} ${a.name}',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _ReportDialog extends StatefulWidget {
  final void Function(String category, String? note) onReport;
  const _ReportDialog({required this.onReport});

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  String _selected = 'inappropriate';
  final _noteCtrl = TextEditingController();

  static const _categories = [
    ('inappropriate', 'Inappropriate content'),
    ('real_person', 'Identifies a real person'),
    ('body_shaming', 'Body shaming'),
    ('harassment', 'Harassment'),
    ('spam', 'Spam'),
  ];

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Report Meme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._categories.map((c) => RadioListTile<String>(
                  dense: true,
                  title: Text(c.$2),
                  value: c.$1,
                  groupValue: _selected,
                  onChanged: (v) =>
                      setState(() => _selected = v!),
                )),
            const SizedBox(height: 8),
            TextField(
              controller: _noteCtrl,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: 'Additional notes (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => widget.onReport(
                _selected,
                _noteCtrl.text.trim().isEmpty
                    ? null
                    : _noteCtrl.text.trim()),
            child: const Text('Report'),
          ),
        ],
      );
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏋️', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('No memes yet!',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Be the first to create one',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey),
          ),
        ],
      );
}
