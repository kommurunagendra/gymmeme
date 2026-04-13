import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';
import 'package:intl/intl.dart';
import '../../../data/models/activity_log_model.dart';
import '../../../features/archetypes/data/archetype_data.dart';
import '../providers/activity_log_provider.dart';
import '../../../services/share_service.dart';

class WeeklyReportScreen extends ConsumerWidget {
  const WeeklyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(weeklyReportProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Report')),
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (report) => report == null
            ? const _EmptyReport()
            : _ReportContent(report: report),
      ),
    );
  }
}

class _EmptyReport extends StatelessWidget {
  const _EmptyReport();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏋️', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text(
              'No sessions logged this week yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Log a session to see your weekly breakdown',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      );
}

class _ReportContent extends StatefulWidget {
  final WeeklyReportData report;
  const _ReportContent({required this.report});

  @override
  State<_ReportContent> createState() => _ReportContentState();
}

class _ReportContentState extends State<_ReportContent> {
  final _screenshotCtrl = ScreenshotController();

  Future<void> _share() async {
    final bytes = await _screenshotCtrl.capture();
    if (bytes == null) return;
    final file = File(
        '${Directory.systemTemp.path}/gymtype_weekly_report.png');
    await file.writeAsBytes(bytes);
    final archetype =
        getArchetypeById(widget.report.dominantArchetype);
    await ShareService().shareReportCard(
      imagePath: file.path,
      dominantArchetype: archetype.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final dominantArchetype =
        getArchetypeById(report.dominantArchetype);
    final theme = Theme.of(context);
    final df = DateFormat('MMM d');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Shareable card
          Screenshot(
            controller: _screenshotCtrl,
            child: _ReportCard(
              report: report,
              dominantArchetype: dominantArchetype,
              df: df,
            ),
          ),
          const SizedBox(height: 24),

          // Archetype breakdown
          _BreakdownSection(
            title: '🏷 Archetype Breakdown',
            counts: report.archetypeCounts,
            total: report.sessionCount,
            labelBuilder: (id) =>
                '${getArchetypeById(id).emoji} ${getArchetypeById(id).name}',
            colorBuilder: (id) =>
                _hexToColor(getArchetypeById(id).colour),
          ),
          const SizedBox(height: 20),

          // Mood breakdown
          _BreakdownSection(
            title: '😤 Mood Breakdown',
            counts: report.moodCounts,
            total: report.sessionCount,
            labelBuilder: (m) =>
                '${GymMood.emoji(m)} ${GymMood.label(m)}',
            colorBuilder: (_) => theme.colorScheme.primary,
          ),
          const SizedBox(height: 32),

          ElevatedButton.icon(
            onPressed: _share,
            icon: const Icon(Icons.share),
            label: const Text('Share Report Card'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final WeeklyReportData report;
  final dynamic dominantArchetype;
  final DateFormat df;

  const _ReportCard(
      {required this.report,
      required this.dominantArchetype,
      required this.df});

  @override
  Widget build(BuildContext context) {
    final color = _hexToColor(dominantArchetype.colour as String);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.9), color.withOpacity(0.5)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🏋️ Weekly Report',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${df.format(report.weekStart)} – ${df.format(report.weekEnd)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _StatBox(
                  label: 'Sessions',
                  value: '${report.sessionCount}'),
              const SizedBox(width: 12),
              _StatBox(
                  label: 'Avg Duration',
                  value:
                      '${report.avgDurationMinutes.round()}min'),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Dominant GymType',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(dominantArchetype.emoji as String,
                  style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dominantArchetype.name as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${GymMood.emoji(report.dominantMood)} ${GymMood.label(report.dominantMood)} week',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'GymType App',
            style: TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  )),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 11)),
            ],
          ),
        ),
      );
}

class _BreakdownSection extends StatelessWidget {
  final String title;
  final Map<String, int> counts;
  final int total;
  final String Function(String) labelBuilder;
  final Color Function(String) colorBuilder;

  const _BreakdownSection({
    required this.title,
    required this.counts,
    required this.total,
    required this.labelBuilder,
    required this.colorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                )),
        const SizedBox(height: 12),
        ...sorted.map((e) {
          final pct = total > 0 ? e.value / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(labelBuilder(e.key))),
                    Text('${(pct * 100).round()}%',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: Colors.grey.withOpacity(0.15),
                    valueColor:
                        AlwaysStoppedAnimation(colorBuilder(e.key)),
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
