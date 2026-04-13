import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/archetype_model.dart';
import '../../../features/archetypes/data/archetype_data.dart';
import '../../../features/archetypes/providers/archetype_provider.dart';
import '../../../features/activity_log/providers/activity_log_provider.dart';
import '../../../services/auth_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archetype = ref.watch(currentArchetypeProvider);
    final recentAsync = ref.watch(recentLogsProvider);
    final hasTodayLog = ref.watch(hasTodayLogProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My GymType'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettings(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Archetype card or CTA
            archetype == null
                ? _TakeQuizCta()
                : _ArchetypeHeroCard(archetype: archetype),

            const SizedBox(height: 24),

            // Streak + quick stats
            _StatsRow(
              recentLogsAsync: recentAsync,
              hasTodayLog: hasTodayLog,
            ),

            const SizedBox(height: 24),

            // Quick actions
            Text(
              'Quick Actions',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _QuickActionsGrid(),

            const SizedBox(height: 24),

            // Recent logs
            Text(
              'Recent Sessions',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            recentAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (logs) => logs.isEmpty
                  ? const _EmptyLogs()
                  : Column(
                      children: logs
                          .take(5)
                          .map((log) => _LogTile(log: log))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings(BuildContext context, WidgetRef ref) =>
      showModalBottomSheet(
        context: context,
        builder: (_) => _SettingsSheet(ref: ref),
      );
}

class _TakeQuizCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.quiz),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text('🤔', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  'What\'s your GymType?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Take the 8-question quiz to find out',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.quiz),
                  child: const Text('Find My GymType'),
                ),
              ],
            ),
          ),
        ),
      );
}

class _ArchetypeHeroCard extends StatelessWidget {
  final ArchetypeModel archetype;
  const _ArchetypeHeroCard({required this.archetype});

  Color get _color {
    final buffer = StringBuffer();
    if (archetype.colour.length == 7) buffer.write('ff');
    buffer.write(archetype.colour.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_color, _color.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(archetype.emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your GymType',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  archetype.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.quiz),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Retake quiz →',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final AsyncValue<List<dynamic>> recentLogsAsync;
  final AsyncValue<bool> hasTodayLog;

  const _StatsRow(
      {required this.recentLogsAsync, required this.hasTodayLog});

  @override
  Widget build(BuildContext context) {
    final sessions = recentLogsAsync.valueOrNull?.length ?? 0;
    final todayDone = hasTodayLog.valueOrNull ?? false;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            emoji: '🔥',
            value: '${sessions}',
            label: 'This Week',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            emoji: todayDone ? '✅' : '⏳',
            value: todayDone ? 'Done' : 'Pending',
            label: 'Today',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            emoji: '🏅',
            value: '${sessions}',
            label: 'Total Logs',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const _StatCard(
      {required this.emoji, required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 18)),
              Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ),
      );
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _ActionTile(
          icon: Icons.add_circle_outline,
          label: 'Log Session',
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.dailyLog),
        ),
        _ActionTile(
          icon: Icons.add_photo_alternate_outlined,
          label: 'Create Meme',
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.templateGrid),
        ),
        _ActionTile(
          icon: Icons.bar_chart,
          label: 'Weekly Report',
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.weeklyReport),
        ),
        _ActionTile(
          icon: Icons.quiz_outlined,
          label: 'Retake Quiz',
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.quiz),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Icon(icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _LogTile extends StatelessWidget {
  final dynamic log;
  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final archetype = getArchetypeById(log.selfTagArchetype as String);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(archetype.emoji,
            style: const TextStyle(fontSize: 28)),
        title: Text(archetype.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${log.durationMinutes}min · ${log.mood}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          _formatDate(log.date as String),
          style:
              const TextStyle(color: Colors.grey, fontSize: 11),
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    final d = DateTime.parse(isoDate);
    final now = DateTime.now();
    final diff = now.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${d.day}/${d.month}';
  }
}

class _EmptyLogs extends StatelessWidget {
  const _EmptyLogs();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text('📋', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            const Text('No sessions yet',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text(
              'Log your first gym session above',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
}

class _SettingsSheet extends StatefulWidget {
  final WidgetRef ref;
  const _SettingsSheet({required this.ref});

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late bool _anonymous;

  @override
  void initState() {
    super.initState();
    final box = Hive.box(AppConstants.userPrefsBox);
    _anonymous = box.get('share_anonymous', defaultValue: true) as bool;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Share Anonymously'),
              subtitle: const Text(
                  'Your username is hidden from public memes'),
              value: _anonymous,
              onChanged: (v) async {
                setState(() => _anonymous = v);
                final box = Hive.box(AppConstants.userPrefsBox);
                await box.put('share_anonymous', v);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete All Data',
                  style: TextStyle(color: Colors.red)),
              onTap: () => _confirmDeleteData(context),
            ),
            ListTile(
              leading:
                  const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy Policy'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteData(BuildContext context) =>
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete All Data?'),
          content: const Text(
              'This will delete all your local logs, meme history, and archetype result. This cannot be undone.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(ctx);
                Navigator.pop(context);
                await Hive.box(AppConstants.userPrefsBox).clear();
                await Hive.box(AppConstants.archetypeCacheBox).clear();
                widget.ref.invalidate(currentArchetypeProvider);
                final db = widget.ref.read(appDatabaseProvider);
                await db.delete(db.activityLogs).go();
                await db.delete(db.localMemes).go();
              },
              child: const Text('Delete Everything'),
            ),
          ],
        ),
      );
}
