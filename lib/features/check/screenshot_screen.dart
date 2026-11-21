import 'package:flutter/material.dart';

import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import 'check.dart';
import 'paste_screen.dart';

/// Picks a picture and reads its text (OCR). Null when the person cancels; throws when it can't read.
typedef ScreenshotReader = Future<String?> Function();

/// Scan a screenshot: pick a picture, review the text read from it, then Check.
class ScreenshotScreen extends StatefulWidget {
  const ScreenshotScreen({super.key, required this.readScreenshot, required this.runCheck});
  final ScreenshotReader readScreenshot;
  final RunCheck runCheck;

  @override
  State<ScreenshotScreen> createState() => _ScreenshotScreenState();
}

class _ScreenshotScreenState extends State<ScreenshotScreen> {
  bool _busy = false;
  bool _failed = false;

  Future<void> _choose() async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    String? text;
    try {
      text = await widget.readScreenshot();
    } catch (_) {
      text = '';
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _failed = text != null && text.trim().isEmpty;
    });
    if (text == null || _failed) return;
    final l = AppLocalizations.of(context);
    // Replaced so Back from the review goes home, not to an empty picker.
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => PasteScreen(
          runCheck: widget.runCheck,
          source: CheckSource.screenshot,
          initialText: text!.trim(),
          title: l.tileScreenshotTitle,
          note: l.screenshotReview,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: UsisaColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(l.tileScreenshotTitle, style: tt.titleLarge),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text(l.screenshotIntro, style: tt.bodyLarge),
            if (_failed) ...[
              const SizedBox(height: 16),
              Semantics(liveRegion: true, child: Text(l.screenshotNoText, style: tt.bodyLarge)),
            ],
            const SizedBox(height: 20),
            PressScale(
              child: FilledButton(
                onPressed: _busy ? null : _choose,
                style: FilledButton.styleFrom(
                  backgroundColor: UsisaColors.primary,
                  minimumSize: const Size.fromHeight(56),
                  shape: const StadiumBorder(),
                  textStyle: tt.titleMedium,
                ),
                child: Text(l.screenshotChoose),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
