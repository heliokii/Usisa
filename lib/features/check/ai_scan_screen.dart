import 'package:flutter/material.dart';

import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import 'check.dart';
import 'paste_screen.dart';
import 'screenshot_screen.dart';

/// AI scan: choose a message, a link or a screenshot, then run it as an AI scan.
class AiScanScreen extends StatelessWidget {
  const AiScanScreen({super.key, required this.runCheck, required this.readScreenshot});
  final RunCheck runCheck;
  final ScreenshotReader readScreenshot;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tt = Theme.of(context).textTheme;
    void open(Widget screen) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    final choices = [
      (
        l.aiScanMessage,
        UsisaColors.yellow,
        () => open(PasteScreen(runCheck: runCheck, aiScan: true, title: l.tileAiTitle)),
      ),
      (
        l.aiScanLink,
        UsisaColors.lilac,
        () => open(PasteScreen(runCheck: runCheck, aiScan: true, source: CheckSource.link, title: l.tileAiTitle)),
      ),
      (
        l.aiScanScreenshot,
        UsisaColors.mint,
        () => open(
          ScreenshotScreen(readScreenshot: readScreenshot, runCheck: runCheck, aiScan: true, title: l.tileAiTitle),
        ),
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: UsisaColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(l.tileAiTitle, style: tt.titleLarge),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text(l.aiScanIntro, style: tt.bodyLarge),
            const SizedBox(height: 20),
            for (final (i, (label, color, onTap)) in choices.indexed) ...[
              if (i > 0) const SizedBox(height: 14),
              EnterMotion(
                index: i,
                child: PressScale(
                  child: Material(
                    color: color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UsisaRadius.card)),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: onTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                        child: Text(label, style: tt.titleMedium),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
