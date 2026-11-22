import 'package:flutter/material.dart';

import '../../app/check_page.dart';
import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import 'check.dart';
import 'home_screen.dart';
import 'paste_screen.dart';
import 'screenshot_screen.dart';

/// AI scan: choose a message, a link or a screenshot, then run it as an AI scan.
class AiScanScreen extends StatelessWidget {
  const AiScanScreen({super.key, required this.runCheck, required this.readScreenshot, this.takePhoto});
  final RunCheck runCheck;
  final ScreenshotReader readScreenshot;
  final ScreenshotReader? takePhoto;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    void open(Widget screen) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    Widget tile(int index, CheckKind kind, String title, String subtitle, Widget screen) => EnterMotion(
      index: index,
      child: CheckTile(kind: kind, title: title, subtitle: subtitle, onTap: () => open(screen)),
    );
    return CheckPage(
      title: l.tileAiTitle,
      titleColor: UsisaColors.primary,
      intro: l.aiScanPageIntro,
      showEyebrow: false,
      children: [
        // Minimum heights match the design; very large text grows the tiles instead of clipping.
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 190),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: tile(
                    0,
                    CheckKind.message,
                    l.tileMessageTitle,
                    l.aiScanMessageSubtitle,
                    PasteScreen(runCheck: runCheck, aiScan: true, title: l.tileAiTitle),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: tile(
                    1,
                    CheckKind.link,
                    l.tileLinkTitle,
                    l.aiScanLinkSubtitle,
                    PasteScreen(runCheck: runCheck, aiScan: true, source: CheckSource.link, title: l.tileAiTitle),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 160),
          child: tile(
            2,
            CheckKind.screenshot,
            l.tileScreenshotTitle,
            l.aiScanScreenshotSubtitle,
            ScreenshotScreen(
              readScreenshot: readScreenshot,
              takePhoto: takePhoto,
              runCheck: runCheck,
              aiScan: true,
              title: l.tileAiTitle,
            ),
          ),
        ),
      ],
    );
  }
}
