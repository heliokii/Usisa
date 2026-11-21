import 'package:flutter/material.dart';

import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import 'check.dart';
import 'verdict_screen.dart';

/// Scan a message: paste a text, tap Check, see the verdict.
/// Scan a screenshot reuses it to review and correct the text read from the picture.
class PasteScreen extends StatefulWidget {
  const PasteScreen({
    super.key,
    required this.runCheck,
    this.source = CheckSource.message,
    this.initialText = '',
    this.title,
    this.note,
  });
  final RunCheck runCheck;
  final CheckSource source;
  final String initialText;
  final String? title;

  /// Shown above the text field.
  final String? note;

  @override
  State<PasteScreen> createState() => _PasteScreenState();
}

class _PasteScreenState extends State<PasteScreen> {
  late final _text = TextEditingController(text: widget.initialText);
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() => _busy = true);
    try {
      final result = await widget.runCheck(CheckInput(_text.text, source: widget.source));
      if (!mounted) return;
      // Pushed on top so Back returns to the pasted text.
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => VerdictScreen(result: result)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tt = Theme.of(context).textTheme;
    final link = widget.source == CheckSource.link;
    final field = OutlineInputBorder(
      borderRadius: BorderRadius.circular(UsisaRadius.card),
      borderSide: const BorderSide(color: UsisaColors.hairline, width: 1.5),
    );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: UsisaColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(widget.title ?? l.tileMessageTitle, style: tt.titleLarge),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            if (widget.note != null) ...[Text(widget.note!, style: tt.bodyLarge), const SizedBox(height: 12)],
            TextField(
              controller: _text,
              minLines: link ? 2 : 6,
              maxLines: 12,
              keyboardType: link ? TextInputType.url : null,
              style: tt.bodyLarge,
              decoration: InputDecoration(
                hintText: link ? l.linkHint : l.pasteHint,
                filled: true,
                fillColor: UsisaColors.surface,
                contentPadding: const EdgeInsets.all(20),
                border: field,
                enabledBorder: field,
                focusedBorder: field.copyWith(borderSide: const BorderSide(color: UsisaColors.primary, width: 2)),
              ),
            ),
            const SizedBox(height: 20),
            ListenableBuilder(
              listenable: _text,
              builder: (context, _) => PressScale(
                child: FilledButton(
                  onPressed: _busy || _text.text.trim().isEmpty ? null : _check,
                  style: FilledButton.styleFrom(
                    backgroundColor: UsisaColors.primary,
                    minimumSize: const Size.fromHeight(56),
                    shape: const StadiumBorder(),
                    textStyle: tt.titleMedium,
                  ),
                  child: Text(l.checkButton),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
