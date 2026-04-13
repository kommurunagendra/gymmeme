import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import '../../../features/archetypes/data/archetype_data.dart';
import '../providers/meme_provider.dart';
import '../../../services/ad_service.dart';
import '../../../services/share_service.dart';

class MemeCanvasScreen extends ConsumerStatefulWidget {
  final String? templatePath;
  final String? imagePath;

  const MemeCanvasScreen({
    super.key,
    this.templatePath,
    this.imagePath,
  });

  @override
  ConsumerState<MemeCanvasScreen> createState() =>
      _MemeCanvasScreenState();
}

class _MemeCanvasScreenState extends ConsumerState<MemeCanvasScreen> {
  final _repaintKey = GlobalKey();
  final _topCaptionCtrl = TextEditingController();
  final _bottomCaptionCtrl = TextEditingController();
  String _selectedArchetype = kArchetypes.first.id;
  bool _isSaving = false;
  bool _isPublic = false;

  // Draggable caption positions (as fractions 0-1 of canvas size)
  Offset _topPosition = const Offset(0.5, 0.1);
  Offset _bottomPosition = const Offset(0.5, 0.85);
  double _fontSize = 28;
  bool _isDraggingTop = false;
  bool _isDraggingBottom = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill draft state
    final draft = ref.read(draftMemeProvider);
    _topCaptionCtrl.text = draft.topCaption;
    _bottomCaptionCtrl.text = draft.bottomCaption;

    if (widget.templatePath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(draftMemeProvider.notifier)
            .setTemplate(widget.templatePath!);
      });
    } else if (widget.imagePath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(draftMemeProvider.notifier)
            .setImage(widget.imagePath!);
      });
    }
  }

  @override
  void dispose() {
    _topCaptionCtrl.dispose();
    _bottomCaptionCtrl.dispose();
    super.dispose();
  }

  // ─── Capture canvas as PNG ────────────────────────────────────────────────

  Future<String?> _captureCanvas() async {
    try {
      final boundary = _repaintKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      final bytes = byteData.buffer.asUint8List();

      final dir = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/meme_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(path).writeAsBytes(bytes);
      return path;
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveMeme() async {
    setState(() => _isSaving = true);
    try {
      final imagePath = await _captureCanvas();
      if (imagePath == null) {
        _showSnack('Failed to capture meme');
        return;
      }

      // Save to gallery
      await ImageGallerySaver.saveFile(imagePath);

      // Save to local DB + optionally Firebase
      await ref.read(memeServiceProvider).saveMeme(
            localImagePath: imagePath,
            topCaption: _topCaptionCtrl.text,
            bottomCaption: _bottomCaptionCtrl.text,
            archetypeTag: _selectedArchetype,
            isPublic: _isPublic,
          );

      // Show interstitial every 3rd save
      adServiceInstance.onMemeSaved();

      _showSnack('Meme saved to gallery! 🎉');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _shareMeme() async {
    final imagePath = await _captureCanvas();
    if (imagePath == null) return;
    await ShareService().shareMeme(imagePath: imagePath);
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ─── Position update helpers ──────────────────────────────────────────────

  void _updatePosition(
      bool isTop, DragUpdateDetails d, BoxConstraints constraints) {
    setState(() {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      if (isTop) {
        _topPosition = Offset(
          (_topPosition.dx * w + d.delta.dx).clamp(0, w) / w,
          (_topPosition.dy * h + d.delta.dy).clamp(0, h) / h,
        );
      } else {
        _bottomPosition = Offset(
          (_bottomPosition.dx * w + d.delta.dx).clamp(0, w) / w,
          (_bottomPosition.dy * h + d.delta.dy).clamp(0, h) / h,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(draftMemeProvider);
    final theme = Theme.of(context);
    final imagePath = draft.imagePath ?? draft.templatePath;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Meme'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareMeme,
          ),
        ],
      ),
      body: Column(
        children: [
          // Canvas
          Expanded(
            child: LayoutBuilder(
              builder: (ctx, constraints) => RepaintBoundary(
                key: _repaintKey,
                child: Stack(
                  children: [
                    // Background image
                    SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: _buildBackground(imagePath),
                    ),

                    // Top caption
                    _DraggableCaption(
                      text: _topCaptionCtrl.text,
                      position: _topPosition,
                      fontSize: _fontSize,
                      constraints: constraints,
                      isActive: _isDraggingTop,
                      onDragStart: () =>
                          setState(() => _isDraggingTop = true),
                      onDragEnd: () =>
                          setState(() => _isDraggingTop = false),
                      onDragUpdate: (d) =>
                          _updatePosition(true, d, constraints),
                    ),

                    // Bottom caption
                    _DraggableCaption(
                      text: _bottomCaptionCtrl.text,
                      position: _bottomPosition,
                      fontSize: _fontSize,
                      constraints: constraints,
                      isActive: _isDraggingBottom,
                      onDragStart: () =>
                          setState(() => _isDraggingBottom = true),
                      onDragEnd: () =>
                          setState(() => _isDraggingBottom = false),
                      onDragUpdate: (d) =>
                          _updatePosition(false, d, constraints),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Controls
          Container(
            color: theme.scaffoldBackgroundColor,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top caption
                TextField(
                  controller: _topCaptionCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Top caption',
                    prefixIcon: Icon(Icons.vertical_align_top),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onChanged: (_) => setState(() {}),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 8),

                // Bottom caption
                TextField(
                  controller: _bottomCaptionCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Bottom caption',
                    prefixIcon: Icon(Icons.vertical_align_bottom),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onChanged: (_) => setState(() {}),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),

                // Font size + archetype tag row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Font: ${_fontSize.round()}pt',
                              style: const TextStyle(fontSize: 11)),
                          Slider(
                            value: _fontSize,
                            min: 14,
                            max: 52,
                            onChanged: (v) =>
                                setState(() => _fontSize = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedArchetype,
                        isDense: true,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        items: kArchetypes
                            .map((a) => DropdownMenuItem(
                                  value: a.id,
                                  child: Text('${a.emoji} ${a.name}',
                                      style:
                                          const TextStyle(fontSize: 12)),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _selectedArchetype = v);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Public toggle + Save button
                Row(
                  children: [
                    Row(
                      children: [
                        Switch(
                          value: _isPublic,
                          onChanged: (v) =>
                              setState(() => _isPublic = v),
                        ),
                        const Text('Public',
                            style: TextStyle(fontSize: 13)),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveMeme,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white))
                          : const Icon(Icons.save_alt),
                      label:
                          Text(_isSaving ? 'Saving...' : 'Save Meme'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(String? path) {
    if (path == null) {
      return Container(
        color: Colors.grey.shade900,
        child: const Center(
          child: Text(
            'No image selected',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder());
    }

    return Image.file(File(path), fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder());
  }

  Widget _placeholder() => Container(
        color: Colors.grey.shade800,
        child: const Center(
          child: Icon(Icons.image_not_supported, color: Colors.white54, size: 64),
        ),
      );
}

// ─── Draggable Caption Widget ─────────────────────────────────────────────────

class _DraggableCaption extends StatelessWidget {
  final String text;
  final Offset position; // 0-1 fractions
  final double fontSize;
  final BoxConstraints constraints;
  final bool isActive;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;
  final void Function(DragUpdateDetails) onDragUpdate;

  const _DraggableCaption({
    required this.text,
    required this.position,
    required this.fontSize,
    required this.constraints,
    required this.isActive,
    required this.onDragStart,
    required this.onDragEnd,
    required this.onDragUpdate,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    final x = position.dx * constraints.maxWidth;
    final y = position.dy * constraints.maxHeight;

    return Positioned(
      left: 0,
      top: 0,
      child: Transform.translate(
        offset: Offset(x, y),
        child: GestureDetector(
          onPanStart: (_) => onDragStart(),
          onPanEnd: (_) => onDragEnd(),
          onPanUpdate: onDragUpdate,
          child: FractionalTranslation(
            translation: const Offset(-0.5, -0.5),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                text.toUpperCase(),
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.1,
                  shadows: const [
                    Shadow(
                        color: Colors.black,
                        blurRadius: 4,
                        offset: Offset(1, 1)),
                    Shadow(
                        color: Colors.black,
                        blurRadius: 4,
                        offset: Offset(-1, -1)),
                    Shadow(
                        color: Colors.black,
                        blurRadius: 4,
                        offset: Offset(1, -1)),
                    Shadow(
                        color: Colors.black,
                        blurRadius: 4,
                        offset: Offset(-1, 1)),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
