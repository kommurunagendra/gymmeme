import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/router/app_router.dart';
import '../../../services/face_detection_service.dart';

// Template metadata
class MemeTemplate {
  final String id;
  final String name;
  final String assetPath;
  final String archetypeId;

  const MemeTemplate({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.archetypeId,
  });
}

// Templates bundle — add real images to assets/templates/
const kTemplates = [
  MemeTemplate(
    id: 't1',
    name: 'Mirror Check',
    assetPath: 'assets/templates/mirror_check.png',
    archetypeId: 'mirror_addict',
  ),
  MemeTemplate(
    id: 't2',
    name: 'Too Heavy',
    assetPath: 'assets/templates/too_heavy.png',
    archetypeId: 'ego_lifter',
  ),
  MemeTemplate(
    id: 't3',
    name: 'Phone Break',
    assetPath: 'assets/templates/phone_break.png',
    archetypeId: 'social_scroller',
  ),
  MemeTemplate(
    id: 't4',
    name: 'Claimed Machine',
    assetPath: 'assets/templates/claimed_machine.png',
    archetypeId: 'equipment_camper',
  ),
  MemeTemplate(
    id: 't5',
    name: 'Stretch Routine',
    assetPath: 'assets/templates/stretch_routine.png',
    archetypeId: 'over_stretcher',
  ),
  MemeTemplate(
    id: 't6',
    name: 'Pre-Workout Stack',
    assetPath: 'assets/templates/preworkout.png',
    archetypeId: 'supplement_scientist',
  ),
];

class TemplateGridScreen extends StatefulWidget {
  const TemplateGridScreen({super.key});

  @override
  State<TemplateGridScreen> createState() => _TemplateGridScreenState();
}

class _TemplateGridScreenState extends State<TemplateGridScreen> {
  final _picker = ImagePicker();
  final _faceDetection = FaceDetectionService();
  bool _isProcessing = false;

  Future<void> _pickFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    await _processPickedImage(file.path);
  }

  Future<void> _pickFromCamera() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    await _processPickedImage(file.path);
  }

  Future<void> _processPickedImage(String path) async {
    setState(() => _isProcessing = true);
    try {
      final result = await _faceDetection.detectFaces(path);
      if (!mounted) return;

      if (result.hasFaces) {
        final proceed = await _showFaceWarningDialog(result.faceCount);
        if (!mounted || !proceed) return;
      }

      Navigator.pushNamed(
        context,
        AppRoutes.memeCanvas,
        arguments: {'imagePath': path},
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<bool> _showFaceWarningDialog(int faceCount) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Face Detected ⚠️'),
            content: Text(
              'We detected ${faceCount > 1 ? '$faceCount faces' : 'a face'} in this image.\n\n'
              'GymType is a privacy-first app. Please only use images of yourself '
              'or use a template instead.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Choose Template'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('It\'s Me, Continue'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  void dispose() {
    _faceDetection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Create Meme')),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Checking image...'),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                // Upload section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload Your Own',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _UploadButton(
                                icon: Icons.photo_library,
                                label: 'Gallery',
                                onTap: _pickFromGallery,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _UploadButton(
                                icon: Icons.camera_alt,
                                label: 'Camera',
                                onTap: _pickFromCamera,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '⚠️ Only upload images of yourself. No identifying others.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Templates header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Text(
                      'Or Choose a Template',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),

                // Template grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _TemplateCard(
                        template: kTemplates[i],
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.memeCanvas,
                          arguments: {
                            'templatePath': kTemplates[i].assetPath
                          },
                        ),
                      ),
                      childCount: kTemplates.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
    );
  }
}

class _UploadButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _UploadButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final MemeTemplate template;
  final VoidCallback onTap;

  const _TemplateCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.asset(
                  template.assetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image,
                        size: 48, color: Colors.grey),
                  ),
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Text(
                template.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
