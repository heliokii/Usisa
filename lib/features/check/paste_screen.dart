import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/check_page.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import 'check.dart';
import 'verdict_screen.dart';

/// Longest message the page accepts; real scam texts are far shorter.
const maxMessageLength = 5000;

/// Runs [input] and shows its verdict on top of [context]'s page, so Back returns to the text.
/// Offers "Ask AI to look closer" on an unsure plain-tile verdict (spec story 25).
Future<void> checkAndShowVerdict(BuildContext context, RunCheck runCheck, CheckInput input) async {
  final result = await runCheck(input);
  if (!context.mounted) return;
  // A felt cue that matches the verdict's weight.
  switch (result.verdict) {
    case Verdict.dangerous:
      HapticFeedback.heavyImpact();
    case Verdict.beCareful:
      HapticFeedback.mediumImpact();
    case Verdict.looksSafe || Verdict.couldntCheck:
      HapticFeedback.lightImpact();
  }
  final unsure = result.verdict == Verdict.beCareful || result.verdict == Verdict.couldntCheck;
  var asking = false;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (screen) => VerdictScreen(
        result: result,
        onAskAi: input.aiScan || !unsure
            ? null
            : () async {
                if (asking) return;
                asking = true;
                try {
                  final ai = await runCheck(
                    CheckInput(input.text, source: input.source, aiScan: true, historyId: input.historyId),
                  );
                  if (!screen.mounted) return;
                  await Navigator.of(screen).pushReplacement(MaterialPageRoute<void>(builder: (_) => VerdictScreen(result: ai)));
                } finally {
                  asking = false;
                }
              },
      ),
    ),
  );
}

/// Scan a message or Check a link: paste, tap the button, see the verdict.
class PasteScreen extends StatefulWidget {
  const PasteScreen({
    super.key,
    required this.runCheck,
    this.source = CheckSource.message,
    this.initialText = '',
    this.title,
    this.aiScan = false,
    this.historyId,
    this.autoRun = false,
  });
  final RunCheck runCheck;
  final CheckSource source;
  final String initialText;
  final String? title;

  /// Runs the Check as an AI scan.
  final bool aiScan;

  /// See [CheckInput.historyId].
  final String? historyId;

  /// Runs the Check as soon as the screen opens (a tapped text notification).
  final bool autoRun;

  @override
  State<PasteScreen> createState() => _PasteScreenState();
}

class _PasteScreenState extends State<PasteScreen> {
  late final _text = TextEditingController(text: widget.initialText);
  final _focus = FocusNode();
  bool _busy = false;

  bool get _link => widget.source == CheckSource.link;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
    if (widget.autoRun && widget.initialText.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _check() : null);
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty || !mounted) return;
    final limit = _link ? 2048 : maxMessageLength;
    _text.text = text.length > limit ? text.substring(0, limit) : text;
    _text.selection = TextSelection.collapsed(offset: _text.text.length);
  }

  Future<void> _check() async {
    setState(() => _busy = true);
    try {
      await checkAndShowVerdict(
        context,
        widget.runCheck,
        CheckInput(_text.text, source: widget.source, aiScan: widget.aiScan, historyId: widget.historyId),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tt = Theme.of(context).textTheme;
    final pasteButton = TextButton(
      onPressed: _paste,
      style: TextButton.styleFrom(
        backgroundColor: UsisaColors.lilac.withValues(alpha: .55),
        foregroundColor: UsisaColors.primary,
        shape: const StadiumBorder(),
        minimumSize: const Size(72, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        textStyle: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      child: Text(l.pasteButton),
    );
    final field = TextField(
      controller: _text,
      focusNode: _focus,
      minLines: _link ? 1 : 7,
      maxLines: _link ? 1 : 10,
      maxLength: _link ? 2048 : maxMessageLength,
      keyboardType: _link ? TextInputType.url : TextInputType.multiline,
      style: tt.bodyLarge,
      decoration: InputDecoration(
        hintText: _link ? l.linkHint : l.pasteHint,
        hintStyle: tt.bodyLarge?.copyWith(color: UsisaColors.inkMuted.withValues(alpha: .7)),
        border: InputBorder.none,
        counterText: '',
        isCollapsed: true,
      ),
    );
    return CheckPage(
      title: widget.title ?? (_link ? l.tileLinkTitle : l.tileMessageTitle),
      intro: _link ? l.linkIntro : l.messageIntro,
      footnote: _link ? l.linkFootnote : l.messageFootnote,
      button: ListenableBuilder(
        listenable: _text,
        builder: (context, _) => PrimaryPillButton(
          label: _link ? l.checkLinkButton : l.checkMessageButton,
          busy: _busy,
          onPressed: _text.text.trim().isEmpty ? null : _check,
        ),
      ),
      children: [
        Text(_link ? l.linkLabel : l.messageLabel, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        if (_link)
          Container(
            decoration: fieldDecoration(focused: _focus.hasFocus),
            padding: const EdgeInsets.fromLTRB(20, 6, 6, 6),
            child: Row(children: [Expanded(child: field), pasteButton]),
          )
        else ...[
          Container(
            decoration: fieldDecoration(focused: _focus.hasFocus),
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [field, const SizedBox(height: 8), Align(alignment: Alignment.centerRight, child: pasteButton)],
            ),
          ),
          const SizedBox(height: 6),
          ListenableBuilder(
            listenable: _text,
            builder: (context, _) => Row(
              children: [
                Expanded(
                  child: Text(
                    l.charCount(_text.text.characters.length, maxMessageLength),
                    style: tt.bodySmall?.copyWith(color: UsisaColors.inkMuted),
                  ),
                ),
                TextButton(
                  onPressed: _text.text.isEmpty ? null : _text.clear,
                  style: TextButton.styleFrom(foregroundColor: UsisaColors.inkMuted, minimumSize: const Size(48, 40)),
                  child: Text(l.clearButton),
                ),
              ],
            ),
          ),
        ],
        if (_link) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: UsisaColors.lilac.withValues(alpha: .35),
              borderRadius: BorderRadius.circular(UsisaRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.linkTipTitle, style: tt.titleMedium),
                const SizedBox(height: 8),
                Text(l.linkTipBody, style: tt.bodyMedium?.copyWith(color: UsisaColors.inkMuted, height: 1.45)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
