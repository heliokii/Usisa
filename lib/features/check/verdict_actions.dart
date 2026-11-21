import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/motion.dart';
import '../../app/read_aloud.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import 'check.dart';

/// Opens the phone's share menu with [text]; widget tests pass a fake.
typedef ShareText = Future<void> Function(String text);

Future<void> shareWithPhone(String text) => SharePlus.instance.share(ShareParams(text: text));

/// The verdict and its advice, as spoken by Read aloud.
String verdictSpeech(AppLocalizations l, CheckResult result) =>
    '${l.verdictWord(result.verdict.name)}. ${l.verdictAction(result.verdict.name)}';

/// The message Send to family shares. The checked text itself is left out so a scam link isn't passed on.
String verdictShareText(AppLocalizations l, CheckResult result) => [
  l.shareIntro(l.verdictWord(result.verdict.name)),
  l.verdictAction(result.verdict.name),
  for (final code in result.reasons) '- ${l.reason(code)}',
].join('\n');

/// Send to family (filled) and Read aloud (outlined), both text-only per DESIGN.md.
class VerdictActions extends StatefulWidget {
  const VerdictActions({super.key, required this.result, this.readAloud, this.share});
  final CheckResult result;
  final ReadAloud? readAloud;
  final ShareText? share;

  @override
  State<VerdictActions> createState() => _VerdictActionsState();
}

class _VerdictActionsState extends State<VerdictActions> {
  late final ReadAloud _readAloud = widget.readAloud ?? ReadAloud();

  @override
  void dispose() {
    _readAloud.stop(); // Leaving the verdict ends its speech.
    super.dispose();
  }

  Future<void> _speak() => readAloudWithNote(context, _readAloud, (l) => verdictSpeech(l, widget.result));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PressScale(
          child: FilledButton(
            onPressed: () => (widget.share ?? shareWithPhone)(verdictShareText(l, widget.result)),
            style: FilledButton.styleFrom(
              backgroundColor: UsisaColors.primary,
              minimumSize: const Size.fromHeight(56),
              shape: const StadiumBorder(),
              textStyle: tt.titleMedium,
            ),
            child: Text(l.sendToFamily, textAlign: TextAlign.center),
          ),
        ),
        const SizedBox(height: 12),
        PressScale(
          child: OutlinedButton(
            onPressed: _speak,
            style: OutlinedButton.styleFrom(
              foregroundColor: UsisaColors.primary,
              side: const BorderSide(color: UsisaColors.primary, width: 1.5),
              minimumSize: const Size.fromHeight(56),
              shape: const StadiumBorder(),
              textStyle: tt.titleMedium,
            ),
            child: Text(l.readAloud, textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }
}
