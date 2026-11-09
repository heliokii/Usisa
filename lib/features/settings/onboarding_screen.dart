import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/page_body.dart';
import 'settings_store.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.settings,
    required this.onStart,
  });
  final SettingsStore settings;
  final VoidCallback onStart;
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _busy = false;
  Future<void> _start() async {
    setState(() => _busy = true);
    try {
      await widget.settings.update(onboarded: true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).saveFailed)),
        );
      }
    }
    if (mounted) widget.onStart();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Align(
                alignment: Alignment.centerLeft,
                child: Icon(
                  Icons.shield_outlined,
                  size: 52,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text('Usisa', style: theme.textTheme.titleLarge),
              const SizedBox(height: 32),
              Text(l.welcomeTitle, style: theme.textTheme.headlineLarge),
              const SizedBox(height: 20),
              Text(l.welcomeBody, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 32),
              Text(l.welcomePrivacy),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: _busy ? null : _start,
                child: Text(l.startChecking),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
