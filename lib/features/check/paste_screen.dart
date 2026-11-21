import 'package:flutter/material.dart';

import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import 'check.dart';
import 'verdict_screen.dart';

/// Scan a message: paste a text, tap Check, see the verdict.
class PasteScreen extends StatefulWidget {
  const PasteScreen({super.key, required this.runCheck});
  final RunCheck runCheck;

  @override
  State<PasteScreen> createState() => _PasteScreenState();
}

class _PasteScreenState extends State<PasteScreen> {
  final _text = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() => _busy = true);
    try {
      final result = await widget.runCheck(CheckInput(_text.text, source: CheckSource.message));
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
    final field = OutlineInputBorder(
      borderRadius: BorderRadius.circular(UsisaRadius.card),
      borderSide: const BorderSide(color: UsisaColors.hairline, width: 1.5),
    );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: UsisaColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(l.tileMessageTitle, style: tt.titleLarge),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            TextField(
              controller: _text,
              minLines: 6,
              maxLines: 12,
              style: tt.bodyLarge,
              decoration: InputDecoration(
                hintText: l.pasteHint,
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
