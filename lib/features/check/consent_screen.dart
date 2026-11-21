import 'package:flutter/material.dart';

import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';

/// First-use consent before anything is sent online. Pops true (allow), false (phone only), or null on Back.
class ConsentScreen extends StatelessWidget {
  const ConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tt = Theme.of(context).textTheme;
    final pop = Navigator.of(context).pop<bool>;
    return Scaffold(
      appBar: AppBar(backgroundColor: UsisaColors.background, surfaceTintColor: Colors.transparent),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          children: [
            Semantics(header: true, child: Text(l.consentTitle, style: tt.headlineMedium)),
            const SizedBox(height: 16),
            Text(l.consentBody, style: tt.bodyLarge?.copyWith(height: 1.4)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: UsisaColors.surface, borderRadius: BorderRadius.circular(20)),
              child: Text(l.consentDecline, style: tt.bodyLarge?.copyWith(height: 1.4)),
            ),
            const SizedBox(height: 12),
            Text(l.consentLater, style: tt.bodyMedium?.copyWith(color: UsisaColors.inkMuted)),
            const SizedBox(height: 28),
            PressScale(
              child: FilledButton(
                onPressed: () => pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: UsisaColors.primary,
                  minimumSize: const Size.fromHeight(56),
                  shape: const StadiumBorder(),
                  textStyle: tt.titleMedium,
                ),
                child: Text(l.consentAllow, textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(height: 12),
            PressScale(
              child: OutlinedButton(
                onPressed: () => pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: UsisaColors.primary,
                  side: const BorderSide(color: UsisaColors.primary, width: 1.5),
                  minimumSize: const Size.fromHeight(56),
                  shape: const StadiumBorder(),
                  textStyle: tt.titleMedium,
                ),
                child: Text(l.consentDeny, textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
