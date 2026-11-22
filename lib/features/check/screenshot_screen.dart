import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/check_page.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import 'check.dart';
import 'paste_screen.dart';

/// Picks a picture and reads its text (OCR). Null when the person cancels; throws when it can't read.
typedef ScreenshotReader = Future<String?> Function();

/// Scan a screenshot: pick a picture (or take a photo), review the text read from it, then check it.
class ScreenshotScreen extends StatefulWidget {
  const ScreenshotScreen({
    super.key,
    required this.readScreenshot,
    required this.runCheck,
    this.takePhoto,
    this.readShared,
    this.aiScan = false,
    this.title,
  });
  final ScreenshotReader readScreenshot;
  final RunCheck runCheck;

  /// Takes a photo with the camera and reads it; hidden when null.
  final ScreenshotReader? takePhoto;

  /// Reads a picture shared into Usisa straight away; the Check itself still waits for a tap.
  final ScreenshotReader? readShared;

  /// Runs the Check as an AI scan.
  final bool aiScan;
  final String? title;

  @override
  State<ScreenshotScreen> createState() => _ScreenshotScreenState();
}

class _ScreenshotScreenState extends State<ScreenshotScreen> {
  final _text = TextEditingController();
  bool _reading = false;
  bool _failed = false;
  bool _reviewing = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final shared = widget.readShared;
    if (shared == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _choose(shared);
    });
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _choose(ScreenshotReader read) async {
    setState(() {
      _reading = true;
      _failed = false;
    });
    String? text;
    try {
      text = await read();
    } catch (_) {
      text = '';
    }
    if (!mounted) return;
    final found = text?.trim() ?? '';
    setState(() {
      _reading = false;
      _failed = text != null && found.isEmpty;
      if (found.isNotEmpty) {
        _text.text = found.substring(0, min(found.length, maxMessageLength));
        _reviewing = true;
      }
    });
  }

  void _startOver() => setState(() {
    _text.clear();
    _reviewing = false;
    _failed = false;
  });

  Future<void> _check() async {
    setState(() => _busy = true);
    try {
      await checkAndShowVerdict(
        context,
        widget.runCheck,
        CheckInput(_text.text, source: CheckSource.screenshot, aiScan: widget.aiScan),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tt = Theme.of(context).textTheme;
    return CheckPage(
      title: widget.title ?? l.tileScreenshotTitle,
      intro: l.screenshotPageIntro,
      footnote: l.screenshotFootnote,
      button: ListenableBuilder(
        listenable: _text,
        builder: (context, _) => PrimaryPillButton(
          label: l.checkScreenshotButton,
          busy: _busy,
          onPressed: !_reviewing || _text.text.trim().isEmpty ? null : _check,
        ),
      ),
      children: [
        if (_reviewing)
          Container(
            decoration: fieldDecoration(),
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(l.screenshotReviewTitle, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
                    TextButton(
                      onPressed: _startOver,
                      style: TextButton.styleFrom(foregroundColor: UsisaColors.primary, minimumSize: const Size(48, 44)),
                      child: Text(l.screenshotStartOver, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(l.screenshotReview, style: tt.bodyMedium?.copyWith(color: UsisaColors.inkMuted)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: UsisaColors.background,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _text,
                    minLines: 5,
                    maxLines: 10,
                    maxLength: maxMessageLength,
                    style: tt.bodyLarge,
                    decoration: const InputDecoration(border: InputBorder.none, counterText: '', isCollapsed: true),
                  ),
                ),
                const SizedBox(height: 6),
                ListenableBuilder(
                  listenable: _text,
                  builder: (context, _) => Text(
                    l.charCount(_text.text.characters.length, maxMessageLength),
                    style: tt.bodySmall?.copyWith(color: UsisaColors.inkMuted),
                  ),
                ),
              ],
            ),
          )
        else
          _DropZone(
            reading: _reading,
            onGallery: _reading ? null : () => _choose(widget.readScreenshot),
            onCamera: widget.takePhoto == null || _reading ? null : () => _choose(widget.takePhoto!),
          ),
        if (_failed) ...[
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(l.screenshotNoText, style: tt.bodyLarge?.copyWith(color: UsisaColors.danger)),
          ),
        ],
      ],
    );
  }
}

/// The dashed upload area: overlapping circles, "Choose from gallery" and "Take a photo".
class _DropZone extends StatelessWidget {
  const _DropZone({required this.reading, required this.onGallery, required this.onCamera});
  final bool reading;
  final VoidCallback? onGallery;
  final VoidCallback? onCamera;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tt = Theme.of(context).textTheme;
    return CustomPaint(
      painter: _DashedBorder(),
      child: Container(
        decoration: BoxDecoration(
          color: UsisaColors.lilac.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(UsisaRadius.card),
        ),
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
        child: Column(
          children: [
            const ExcludeSemantics(
              child: SizedBox(
                width: 76,
                height: 56,
                child: Stack(
                  children: [
                    Positioned(left: 0, top: 0, child: _Circle(44, UsisaColors.yellow)),
                    Positioned(right: 0, bottom: 0, child: _Circle(44, Color(0xE6FF8A4C))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              reading ? l.screenshotReading : l.screenshotDropTitle,
              textAlign: TextAlign.center,
              style: tt.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(l.screenshotDropTypes, style: tt.bodySmall?.copyWith(color: UsisaColors.inkMuted)),
            const SizedBox(height: 14),
            if (reading)
              const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())
            else ...[
              TextButton(
                onPressed: onGallery,
                style: TextButton.styleFrom(foregroundColor: UsisaColors.primary, minimumSize: const Size(48, 48)),
                child: Text(
                  l.screenshotGallery,
                  style: tt.titleMedium?.copyWith(
                    color: UsisaColors.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: UsisaColors.primary,
                    decorationThickness: 2,
                  ),
                ),
              ),
              if (onCamera != null)
                TextButton(
                  onPressed: onCamera,
                  style: TextButton.styleFrom(foregroundColor: UsisaColors.inkMuted, minimumSize: const Size(48, 44)),
                  child: Text(l.screenshotCamera),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle(this.size, this.color);
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _DashedBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(UsisaRadius.card));
    final paint = Paint()
      ..color = UsisaColors.lilac
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder oldDelegate) => false;
}
