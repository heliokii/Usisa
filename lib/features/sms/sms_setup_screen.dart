import 'package:flutter/material.dart';

import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import 'sms_service.dart';

/// First-run setup: one step turns on scam text protection (SMS and notification permissions asked together),
/// then, on Xiaomi, Oppo, Vivo and Samsung, a step that opens the phone's background-running settings.
class SmsSetupScreen extends StatefulWidget {
  const SmsSetupScreen({super.key, required this.sms, required this.language, required this.onDone});
  final SmsService sms;
  final String language;
  final VoidCallback onDone;

  @override
  State<SmsSetupScreen> createState() => _SmsSetupScreenState();
}

class _SmsSetupScreenState extends State<SmsSetupScreen> {
  bool _backgroundStep = false;
  bool _busy = false;

  Future<void> _turnOn() async {
    setState(() => _busy = true);
    try {
      await widget.sms.setEnabled(true, language: widget.language);
    } catch (_) {
      await widget.sms.refresh();
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (widget.sms.enabled && widget.sms.needsBackgroundStep) {
      setState(() => _backgroundStep = true);
    } else {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tt = Theme.of(context).textTheme;
    final (title, body, primary, secondary, onPrimary, onSecondary) = _backgroundStep
        ? (
            l.smsBackgroundTitle,
            l.smsBackgroundBody,
            l.smsBackgroundOpen,
            l.smsBackgroundDone,
            () => widget.sms.openBackgroundSettings().catchError((_) {}),
            widget.onDone,
          )
        : (l.smsSetupTitle, l.smsSetupBody, l.smsSetupTurnOn, l.smsSetupNotNow, _turnOn, widget.onDone);
    return Scaffold(
      backgroundColor: UsisaColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 28),
          children: [
            Semantics(header: true, child: Text(title, style: tt.headlineMedium)),
            const SizedBox(height: 16),
            Text(body, style: tt.bodyLarge?.copyWith(height: 1.4)),
            const SizedBox(height: 32),
            PressScale(
              child: FilledButton(
                onPressed: _busy ? null : onPrimary,
                style: FilledButton.styleFrom(
                  backgroundColor: UsisaColors.primary,
                  minimumSize: const Size.fromHeight(56),
                  shape: const StadiumBorder(),
                  textStyle: tt.titleMedium,
                ),
                child: Text(primary, textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(height: 12),
            PressScale(
              child: OutlinedButton(
                onPressed: _busy ? null : onSecondary,
                style: OutlinedButton.styleFrom(
                  foregroundColor: UsisaColors.primary,
                  side: const BorderSide(color: UsisaColors.primary, width: 1.5),
                  minimumSize: const Size.fromHeight(56),
                  shape: const StadiumBorder(),
                  textStyle: tt.titleMedium,
                ),
                child: Text(secondary, textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
